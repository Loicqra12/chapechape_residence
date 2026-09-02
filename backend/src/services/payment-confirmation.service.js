const Payment = require('../models/payment.model');
const Reservation = require('../models/reservation.model');
const { Conversation, Message } = require('../models/message.model');
const WebhookEvent = require('../models/webhook-event.model');
const mongoose = require('mongoose');
const logger = require('../utils/logger');
const {
  guardSlot,
  withRetry,
} = require('./inventory.service');

/**
 * Réclame un événement webhook pour traitement.
 * - Nouveau → status processing, claimed=true
 * - Déjà completed → claimed=false
 * - failed → reprise possible (claimed=true)
 * - processing récent → claimed=false (évite double traitement concurrent)
 *
 * @returns {{ claimed: boolean, alreadyCompleted: boolean }}
 */
async function claimWebhookEvent(provider, eventId, payloadHash = null) {
  try {
    await WebhookEvent.create({
      provider,
      eventId,
      payloadHash,
      status: 'processing',
    });
    return { claimed: true, alreadyCompleted: false };
  } catch (err) {
    if (err.code !== 11000) throw err;

    const existing = await WebhookEvent.findOne({ provider, eventId });
    if (!existing) {
      return { claimed: false, alreadyCompleted: false };
    }

    if (existing.status === 'completed') {
      logger.info(`Webhook déjà traité: ${provider}/${eventId}`);
      return { claimed: false, alreadyCompleted: true };
    }

    if (existing.status === 'failed') {
      const updated = await WebhookEvent.findOneAndUpdate(
        { provider, eventId, status: 'failed' },
        {
          $set: {
            status: 'processing',
            lastError: null,
            payloadHash: payloadHash || existing.payloadHash,
          },
        },
        { new: true }
      );
      if (updated) {
        logger.info(`Webhook retry après échec: ${provider}/${eventId}`);
        return { claimed: true, alreadyCompleted: false };
      }
    }

    // processing en cours (ou course concurrente)
    logger.info(`Webhook déjà en cours: ${provider}/${eventId}`);
    return { claimed: false, alreadyCompleted: false };
  }
}

/**
 * Marque l'événement comme traité avec succès (après applyPaymentPaid etc.)
 */
async function completeWebhookEvent(provider, eventId) {
  await WebhookEvent.updateOne(
    { provider, eventId },
    { $set: { status: 'completed', processedAt: new Date(), lastError: null } }
  );
}

/**
 * Marque l'événement en échec pour permettre un retry PSP
 */
async function failWebhookEvent(provider, eventId, errorMessage) {
  await WebhookEvent.updateOne(
    { provider, eventId },
    {
      $set: {
        status: 'failed',
        lastError: (errorMessage || 'unknown').toString().slice(0, 500),
        processedAt: new Date(),
      },
    }
  );
}

/**
 * @deprecated Préférer claimWebhookEvent + completeWebhookEvent
 * Conservé pour compat : crée l'événement ; true si nouveau.
 */
async function registerWebhookEvent(provider, eventId, payloadHash = null) {
  const result = await claimWebhookEvent(provider, eventId, payloadHash);
  return result.claimed;
}

/**
 * Confirme un paiement et la réservation de façon idempotente.
 * @returns {{ applied: boolean, alreadyPaid: boolean, payment: object|null }}
 */
async function applyPaymentPaid(payment, options = {}) {
  // allowExpired: webhooks PSP uniquement — un paiement localement « expired »
  // peut encore être validé si le client a payé côté PSP avant/après le cutoff.
  const { providerResponse, triggerPayout = true, allowExpired = false } = options;

  if (!payment) {
    return { applied: false, alreadyPaid: false, payment: null };
  }

  if (payment.status === 'paid') {
    return { applied: false, alreadyPaid: true, payment };
  }

  const updateFields = {
    status: 'paid',
    providerStatus: 'validated',
  };
  if (providerResponse !== undefined) {
    updateFields['paymentDetails.providerResponse'] = providerResponse;
  }

  const allowedStatuses = allowExpired
    ? ['pending', 'failed', 'expired']
    : ['pending', 'failed'];

  const updatedPayment = await Payment.findOneAndUpdate(
    {
      _id: payment._id,
      status: { $in: allowedStatuses },
    },
    { $set: updateFields },
    { new: true }
  );

  if (!updatedPayment) {
    const current = await Payment.findById(payment._id);
    const alreadyPaid = current?.status === 'paid';
    return { applied: false, alreadyPaid, payment: current };
  }

  const reservationId = updatedPayment.reservation;
  const reservation = await Reservation.findById(reservationId);

  if (!reservation) {
    await markPaymentRefundRequired(updatedPayment, 'reservation_missing');
    logger.error('PAYMENT_REFUND_REQUIRED', {
      event: 'PAYMENT_REFUND_REQUIRED',
      paymentId: String(updatedPayment._id),
      reservationId: String(reservationId),
      reason: 'reservation_missing',
    });
    return {
      applied: true,
      alreadyPaid: false,
      payment: updatedPayment,
      reservationConfirmed: false,
      refundRequired: true,
    };
  }

  const confirmable = ['pending', 'payment_pending', 'confirmed'];
  const requiresHostApproval =
    reservation.reservationModeSnapshot === 'approval_required'
    && reservation.status !== 'payment_pending'
    && reservation.status !== 'confirmed';

  if (requiresHostApproval) {
    await markPaymentRefundRequired(updatedPayment, `status_${reservation.status}`);
    logger.info('PAYMENT_REFUND_REQUIRED', {
      event: 'PAYMENT_REFUND_REQUIRED',
      reservationId: String(reservationId),
      paymentId: String(updatedPayment._id),
      status: reservation.status,
      reason: 'approval_required_without_host_approval',
    });
    return {
      applied: true,
      alreadyPaid: false,
      payment: updatedPayment,
      reservationConfirmed: false,
      refundRequired: true,
    };
  }

  let socketPreviousStatus = null;
  let socketTransitioned = false;

  if (confirmable.includes(reservation.status)) {
    socketPreviousStatus = reservation.status;
    const updateResult = await Reservation.updateOne(
      {
        _id: reservationId,
        paymentStatus: { $ne: 'paid' },
        status: { $in: confirmable },
      },
      {
        $set: {
          paymentStatus: 'paid',
          status: 'confirmed',
          messagingEnabled: true,
          paymentDeadline: null,
        },
        $push: {
          statusHistory: {
            status: 'confirmed',
            paymentStatus: 'paid',
            changedAt: new Date(),
            reason: 'Paiement confirmé (webhook/PSP)',
          },
        },
      }
    );
    socketTransitioned = updateResult.modifiedCount > 0;
  } else if (reservation.status === 'expired' && allowExpired) {
    socketPreviousStatus = reservation.status;
    const reacquired = await reacquireExpiredReservation(reservation, updatedPayment);
    if (!reacquired) {
      return {
        applied: true,
        alreadyPaid: false,
        payment: updatedPayment,
        reservationConfirmed: false,
        refundRequired: true,
      };
    }
    logger.info('PAYMENT_LATE', {
      event: 'PAYMENT_LATE',
      reservationId: String(reservationId),
      paymentId: String(updatedPayment._id),
      outcome: 'reacquired',
    });
    socketTransitioned = true;
  } else if (reservation.status === 'expired') {
    await markPaymentRefundRequired(updatedPayment, 'reservation_expired');
    logger.info('PAYMENT_LATE', {
      event: 'PAYMENT_LATE',
      reservationId: String(reservationId),
      paymentId: String(updatedPayment._id),
      outcome: 'refund_required_no_allowExpired',
    });
    return {
      applied: true,
      alreadyPaid: false,
      payment: updatedPayment,
      reservationConfirmed: false,
      refundRequired: true,
    };
  } else {
    // awaiting_approval, cancelled, etc. — ne pas confirmer (règle d'approbation)
    await markPaymentRefundRequired(updatedPayment, `status_${reservation.status}`);
    logger.info('PAYMENT_REFUND_REQUIRED', {
      event: 'PAYMENT_REFUND_REQUIRED',
      reservationId: String(reservationId),
      paymentId: String(updatedPayment._id),
      status: reservation.status,
    });
    return {
      applied: true,
      alreadyPaid: false,
      payment: updatedPayment,
      reservationConfirmed: false,
      refundRequired: true,
    };
  }

  const confirmedNow = await Reservation.findById(reservationId);
  if (!confirmedNow || confirmedNow.status !== 'confirmed') {
    return {
      applied: true,
      alreadyPaid: false,
      payment: updatedPayment,
      reservationConfirmed: false,
      refundRequired: updatedPayment.metadata?.get?.('refund_required') === 'true',
    };
  }

  await ensureReservationConversation(reservationId);

  if (process.env.NODE_ENV === 'test') {
    return {
      applied: true,
      alreadyPaid: false,
      payment: updatedPayment,
      reservationConfirmed: true,
      refundRequired: false,
    };
  }

  // Annuler expiration + rappels paiement (webhooks / PSP)
  try {
    const { cancelReservationExpiration } = require('./agenda.service');
    await cancelReservationExpiration(reservationId);
  } catch (cancelErr) {
    logger.error('Annulation jobs paiement échouée:', cancelErr);
  }

  // Notifications Client + Partner (idempotentes) — chemin canonique webhook/PSP
  try {
    const reservationForNotif = await Reservation.findById(reservationId)
      .populate('user residence partner');
    if (reservationForNotif) {
      const notificationService = require('./notification.service');
      await notificationService.sendPaymentConfirmationNotification(reservationForNotif);

      if (socketTransitioned) {
        try {
          const SocketService = require('./socket.service');
          SocketService.emitReservationStatusChange(
            reservationForNotif,
            socketPreviousStatus || 'payment_pending',
            'confirmed'
          );
        } catch (socketErr) {
          logger.warn('Socket confirmation paiement non émis:', socketErr?.message);
        }
      }
    }
  } catch (notifError) {
    logger.error('Notification confirmation paiement non envoyée:', notifError);
  }

  if (triggerPayout) {
    try {
      const reservation = await Reservation.findById(reservationId).populate('partner');
      const AutomaticPayoutService = require('./automatic-payout.service');
      await AutomaticPayoutService.triggerAutomaticPayout(updatedPayment, reservation);
    } catch (payoutError) {
      logger.error('Payout automatique non déclenché:', payoutError);
    }
  }

  return { applied: true, alreadyPaid: false, payment: updatedPayment };
}

async function ensureReservationConversation(reservationId) {
  const existing = await Conversation.findOne({ reservationId });
  if (existing) return;

  const populated = await Reservation.findById(reservationId).populate('user partner residence');
  if (!populated?.user || !populated?.partner) return;

  const conversation = await Conversation.create({
    participants: [populated.user._id, populated.partner._id],
    reservationId: populated._id,
    residenceId: populated.residence._id,
    createdAt: Date.now(),
    updatedAt: Date.now(),
  });

  const residenceName =
    populated.residence?.title || populated.residence?.name || 'votre résidence';

  const message = await Message.create({
    conversation: conversation._id,
    sender: populated.partner._id,
    content: `Merci pour votre réservation de "${residenceName}" ! N'hésitez pas à me contacter pour toute question concernant votre séjour.`,
  });

  conversation.lastMessage = message._id;
  await conversation.save();
}

async function markPaymentRefundRequired(payment, reason) {
  const refundService = require('./refund.service');
  await refundService.markRefundRequired(payment, reason);
}

/**
 * Webhook tardif après expire : réacquiert l'inventaire ou marque refund_required.
 * @returns {Promise<boolean>} true si Reservation → confirmed
 */
async function reacquireExpiredReservation(reservation, payment) {
  const availabilityService = require('./availability.service');

  try {
    return await withRetry(async () => {
      const session = await mongoose.startSession();
      session.startTransaction();
      try {
        await guardSlot({
          residenceId: reservation.residence,
          checkIn: reservation.checkIn,
          checkOut: reservation.checkOut,
          excludeId: reservation._id,
          session,
        });

        await availabilityService.updateAvailabilityForReservation(
          reservation.residence,
          reservation.checkIn,
          reservation.checkOut,
          reservation._id,
          'reserved',
          reservation.bookingType || 'day',
          session
        );

        const updated = await Reservation.findOneAndUpdate(
          { _id: reservation._id, status: 'expired' },
          {
            $set: {
              status: 'confirmed',
              paymentStatus: 'paid',
              messagingEnabled: true,
              paymentDeadline: null,
            },
            $push: {
              statusHistory: {
                status: 'confirmed',
                paymentStatus: 'paid',
                changedAt: new Date(),
                reason: 'Paiement tardif — inventaire réacquis',
              },
            },
          },
          { session, new: true }
        );

        if (!updated) {
          await session.abortTransaction();
          session.endSession();
          await markPaymentRefundRequired(payment, 'reservation_no_longer_expired');
          return false;
        }

        await session.commitTransaction();
        session.endSession();
        return true;
      } catch (err) {
        if (session.inTransaction()) {
          await session.abortTransaction();
        }
        session.endSession();
        throw err;
      }
    });
  } catch (err) {
    if (err.statusCode === 409) {
      await markPaymentRefundRequired(payment, 'inventory_taken');
      logger.info('PAYMENT_LATE', {
        event: 'PAYMENT_LATE',
        reservationId: String(reservation._id),
        paymentId: String(payment._id),
        outcome: 'refund_required_overlap',
      });
      return false;
    }
    logger.error('PAYMENT_LATE reacquire failed', { err: err?.message, statusCode: err?.statusCode });
    await markPaymentRefundRequired(payment, 'reacquire_error');
    return false;
  }
}

module.exports = {
  registerWebhookEvent,
  claimWebhookEvent,
  completeWebhookEvent,
  failWebhookEvent,
  applyPaymentPaid,
};
