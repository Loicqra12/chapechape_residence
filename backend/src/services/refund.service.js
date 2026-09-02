const Payment = require('../models/payment.model');
const logger = require('../utils/logger');

const AUTO_REFUND_PROVIDERS = ['stripe'];
const MAX_REFUND_ATTEMPTS = 8;
const JOB_NAME = 'process payment refund';

let testRefundAdapter = null;

function setRefundAdapter(adapter) {
  testRefundAdapter = adapter;
}

function getRefundAdapter() {
  return testRefundAdapter;
}

async function defaultStripeRefund(payment) {
  if (!process.env.STRIPE_SECRET_KEY) {
    const err = new Error('STRIPE_NOT_CONFIGURED');
    err.retryable = false;
    throw err;
  }
  if (!payment.transactionId) {
    const err = new Error('STRIPE_TRANSACTION_ID_MISSING');
    err.retryable = false;
    throw err;
  }
  const Stripe = require('stripe');
  const stripe = Stripe(process.env.STRIPE_SECRET_KEY);
  return stripe.refunds.create(
    {
      payment_intent: payment.transactionId,
      amount: Math.round(payment.amount),
      reason: 'requested_by_customer',
      metadata: { paymentId: String(payment._id) },
    },
    { idempotencyKey: `chapechape_refund_${payment._id}` }
  );
}

/**
 * Persiste refund_required et programme le job Agenda (hors webhook synchrone).
 * Idempotent : un paiement déjà required/pending/succeeded n'est pas re-clamé.
 */
async function markRefundRequired(payment, reason) {
  const reasonStr = String(reason || 'unknown').slice(0, 200);
  const updated = await Payment.findOneAndUpdate(
    {
      _id: payment._id,
      status: 'paid',
      $or: [
        { refundStatus: 'not_required' },
        { refundStatus: { $exists: false } },
      ],
    },
    {
      $set: {
        refundStatus: 'required',
        refundReason: reasonStr,
        refundOpsRequired: false,
        'metadata.refund_required': 'true',
        'metadata.refund_required_reason': reasonStr,
      },
    },
    { new: true }
  );

  if (payment.metadata && typeof payment.metadata.set === 'function') {
    payment.metadata.set('refund_required', 'true');
    payment.metadata.set('refund_required_reason', reasonStr);
  } else if (updated) {
    payment.refundStatus = updated.refundStatus;
  }

  if (!updated) {
    const current = await Payment.findById(payment._id);
    logger.info('REFUND_REQUIRED_ALREADY', {
      event: 'REFUND_REQUIRED_ALREADY',
      paymentId: String(payment._id),
      refundStatus: current?.refundStatus,
    });
    return current;
  }

  logger.info('REFUND_REQUIRED', {
    event: 'REFUND_REQUIRED',
    paymentId: String(payment._id),
    reservation: String(updated.reservation),
    reason: reasonStr,
    provider: updated.paymentProvider,
  });

  await scheduleRefundProcessing(updated._id);
  return updated;
}

async function scheduleRefundProcessing(paymentId) {
  if (process.env.NODE_ENV === 'test') {
    return;
  }
  try {
    const { agenda, saveUniqueScheduledJob } = require('./agenda.service');
    await agenda.cancel({ name: JOB_NAME, 'data.paymentId': String(paymentId) });
    await saveUniqueScheduledJob(
      agenda,
      JOB_NAME,
      'now',
      { paymentId: String(paymentId) },
      'paymentId'
    );
  } catch (err) {
    logger.error('REFUND_SCHEDULE_FAILED', {
      event: 'REFUND_SCHEDULE_FAILED',
      paymentId: String(paymentId),
      err: err.message,
    });
  }
}

function providerSupportsAutoRefund(payment) {
  return AUTO_REFUND_PROVIDERS.includes(payment.paymentProvider);
}

/**
 * Claim atomique + exécution provider. Un seul remboursement financier par paiement.
 */
async function processPaymentRefund(paymentId) {
  const claimed = await Payment.findOneAndUpdate(
    {
      _id: paymentId,
      status: 'paid',
      refundStatus: { $in: ['required', 'failed'] },
    },
    {
      $set: {
        refundStatus: 'pending',
        refundLastAttemptAt: new Date(),
      },
      $inc: { refundAttempts: 1 },
    },
    { new: true }
  );

  if (!claimed) {
    const current = await Payment.findById(paymentId);
    if (current?.status === 'refunded' || current?.refundStatus === 'succeeded') {
      return { applied: false, alreadyRefunded: true };
    }
    if (current?.refundStatus === 'pending') {
      return { applied: false, inProgress: true };
    }
    return { applied: false, skipped: true, refundStatus: current?.refundStatus };
  }

  if (!providerSupportsAutoRefund(claimed) || !claimed.transactionId) {
    await Payment.updateOne(
      { _id: claimed._id, refundStatus: 'pending' },
      {
        $set: {
          refundStatus: 'required',
          refundOpsRequired: true,
          refundLastError: 'provider_has_no_auto_refund_api',
        },
      }
    );
    logger.error('REFUND_OPS_REQUIRED', {
      event: 'REFUND_OPS_REQUIRED',
      paymentId: String(claimed._id),
      provider: claimed.paymentProvider,
      reservation: String(claimed.reservation),
    });
    await notifyRefundOps(claimed);
    return { applied: false, opsRequired: true };
  }

  try {
    const adapter = testRefundAdapter || { refund: defaultStripeRefund };
    const result = await adapter.refund(claimed);
    const providerRef = result?.id || result?.refundId || `ok_${claimed._id}`;

    const finalized = await Payment.findOneAndUpdate(
      { _id: claimed._id, refundStatus: 'pending', status: 'paid' },
      {
        $set: {
          status: 'refunded',
          refundStatus: 'succeeded',
          refundAmount: claimed.amount,
          refundProviderRef: String(providerRef).slice(0, 200),
          refundLastError: null,
          refundOpsRequired: false,
        },
      },
      { new: true }
    );

    if (!finalized) {
      logger.info('REFUND_FINALIZE_RACE', {
        event: 'REFUND_FINALIZE_RACE',
        paymentId: String(claimed._id),
      });
      return { applied: false, alreadyRefunded: true };
    }

    logger.info('REFUND_SUCCEEDED', {
      event: 'REFUND_SUCCEEDED',
      paymentId: String(claimed._id),
      providerRef,
    });

    await notifyClientRefund(finalized);
    return { applied: true, refunded: true, payment: finalized };
  } catch (err) {
    const attempts = claimed.refundAttempts;
    const retryable = err.retryable !== false;
    await Payment.updateOne(
      { _id: claimed._id },
      {
        $set: {
          refundStatus: 'failed',
          refundLastError: String(err.message || 'refund_failed').slice(0, 400),
        },
      }
    );
    logger.error('REFUND_FAILED', {
      event: 'REFUND_FAILED',
      paymentId: String(claimed._id),
      attempts,
      err: err.message,
      retryable,
    });

    if (retryable && attempts < MAX_REFUND_ATTEMPTS && process.env.NODE_ENV !== 'test') {
      try {
        const { agenda, saveUniqueScheduledJob } = require('./agenda.service');
        const delay = new Date(Date.now() + Math.min(15, attempts) * 60 * 1000);
        await saveUniqueScheduledJob(
          agenda,
          JOB_NAME,
          delay,
          { paymentId: String(claimed._id) },
          'paymentId'
        );
      } catch (schedErr) {
        logger.error('REFUND_RETRY_SCHEDULE_FAILED', { err: schedErr.message });
      }
    }

    if (!retryable || attempts >= MAX_REFUND_ATTEMPTS) {
      logger.error('REFUND_ALERT', {
        event: 'REFUND_ALERT',
        paymentId: String(claimed._id),
        attempts,
      });
    }

    throw err;
  }
}

async function notifyClientRefund(payment) {
  if (process.env.NODE_ENV === 'test') return;
  try {
    const Reservation = require('../models/reservation.model');
    const reservation = await Reservation.findById(payment.reservation).populate('user');
    if (!reservation?.user) return;
    const notificationService = require('./notification.service');
    const notificationTypes = require('../utils/notification-types');
    await notificationService.notifyClient(
      reservation.user._id,
      notificationTypes.CLIENT.PAYMENT_REFUND,
      {
        reservationId: String(reservation._id),
        amount: payment.amount,
        deepLink: `/booking-details/${reservation._id}`,
      }
    );
  } catch (err) {
    logger.error('REFUND_CLIENT_NOTIFY_FAILED', { err: err.message });
  }
}

async function notifyRefundOps(payment) {
  logger.error('REFUND_OPS_QUEUE', {
    event: 'REFUND_OPS_QUEUE',
    paymentId: String(payment._id),
    provider: payment.paymentProvider,
    amount: payment.amount,
    reservation: String(payment.reservation),
  });
}

async function sweepDueRefunds() {
  const due = await Payment.find({
    status: 'paid',
    refundStatus: { $in: ['required', 'failed'] },
    refundOpsRequired: { $ne: true },
  })
    .select('_id')
    .limit(50)
    .lean();

  for (const row of due) {
    await scheduleRefundProcessing(row._id);
  }

  const opsQueue = await Payment.countDocuments({
    status: 'paid',
    refundOpsRequired: true,
    refundStatus: 'required',
  });
  if (opsQueue > 0) {
    logger.error('REFUND_OPS_BACKLOG', {
      event: 'REFUND_OPS_BACKLOG',
      count: opsQueue,
    });
  }

  return { scheduled: due.length, opsBacklog: opsQueue };
}

/**
 * Confirmation manuelle auditable d'un remboursement hors API
 * (Wave / CinetPay : refundOpsRequired).
 * Ce n'est PAS un accusé de réception (acknowledged).
 * L'opérateur atteste qu'un remboursement réel a été effectué chez le provider
 * (note + référence externe) : le Payment passe à refunded.
 */
async function confirmManualRefund(paymentId, { actorId, note, externalReference }) {
  const noteStr = String(note || '').trim();
  const refStr = String(externalReference || '').trim();
  if (noteStr.length < 8) {
    const err = new Error('NOTE_REQUIRED');
    err.statusCode = 400;
    throw err;
  }
  if (refStr.length < 3) {
    const err = new Error('EXTERNAL_REF_REQUIRED');
    err.statusCode = 400;
    throw err;
  }

  const current = await Payment.findById(paymentId);
  if (!current) {
    const err = new Error('PAYMENT_NOT_FOUND');
    err.statusCode = 404;
    throw err;
  }

  const finalized = await Payment.findOneAndUpdate(
    {
      _id: paymentId,
      status: 'paid',
      refundOpsRequired: true,
      refundStatus: { $in: ['required', 'failed', 'pending'] },
    },
    {
      $set: {
        status: 'refunded',
        refundStatus: 'succeeded',
        refundOpsRequired: false,
        refundAmount: current.amount,
        refundProviderRef: refStr.slice(0, 200),
        refundOpsExternalRef: refStr.slice(0, 200),
        refundOpsNote: noteStr.slice(0, 500),
        refundOpsConfirmedAt: new Date(),
        refundOpsConfirmedBy: actorId,
        refundLastAttemptAt: new Date(),
        refundLastError: null,
      },
    },
    { new: true }
  );

  if (!finalized) {
    const err = new Error('REFUND_CONFIRM_NOT_ELIGIBLE');
    err.statusCode = 409;
    err.refundStatus = current.refundStatus;
    err.refundOpsRequired = current.refundOpsRequired;
    err.paymentStatus = current.status;
    throw err;
  }

  logger.info('REFUND_MANUAL_CONFIRMED', {
    event: 'REFUND_MANUAL_CONFIRMED',
    paymentId: String(finalized._id),
    actorId: String(actorId),
    reservation: String(finalized.reservation),
    externalReference: refStr,
  });

  return finalized;
}

module.exports = {
  AUTO_REFUND_PROVIDERS,
  MAX_REFUND_ATTEMPTS,
  JOB_NAME,
  setRefundAdapter,
  getRefundAdapter,
  markRefundRequired,
  scheduleRefundProcessing,
  processPaymentRefund,
  sweepDueRefunds,
  confirmManualRefund,
};
