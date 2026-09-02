const mongoose = require('mongoose');
const Reservation = require('../models/reservation.model');
const ApiError = require('../utils/apiError');
const errorCodes = require('../utils/errorCodes');
const logger = require('../utils/logger');
const { acquire, release, withRetry } = require('./inventory.service');

const JOB_NAME = 'expire host approval';
const DEFAULT_HOST_ACCEPT_TTL_MINUTES = 480;

function computeHostApprovalDeadline(fromDate, ttlMinutes) {
  const minutes = Number(ttlMinutes) > 0 ? Number(ttlMinutes) : DEFAULT_HOST_ACCEPT_TTL_MINUTES;
  return new Date(new Date(fromDate).getTime() + minutes * 60 * 1000);
}

function resolveDeadline(reservation) {
  if (reservation.hostApprovalDeadline) {
    return new Date(reservation.hostApprovalDeadline);
  }
  const ttl = reservation.ttlSnapshot?.hostAcceptTTLMinutes || DEFAULT_HOST_ACCEPT_TTL_MINUTES;
  return computeHostApprovalDeadline(reservation.createdAt || new Date(), ttl);
}

function structuredLog(event, extra = {}) {
  logger.info(event, {
    event,
    timestamp: new Date().toISOString(),
    ...extra,
  });
}

async function scheduleHostApprovalExpiration(reservationId, deadline) {
  if (process.env.NODE_ENV === 'test' || !deadline) return;
  const { agenda, saveUniqueScheduledJob } = require('./agenda.service');
  await agenda.cancel({ name: JOB_NAME, 'data.reservationId': String(reservationId) });
  await saveUniqueScheduledJob(
    agenda,
    JOB_NAME,
    deadline,
    { reservationId: String(reservationId) },
    'reservationId'
  );
  structuredLog('HOST_APPROVAL_SCHEDULED', {
    reservationId: String(reservationId),
    deadline: new Date(deadline).toISOString(),
  });
}

async function cancelHostApprovalExpiration(reservationId) {
  if (process.env.NODE_ENV === 'test') return;
  const { agenda } = require('./agenda.service');
  await agenda.cancel({ name: JOB_NAME, 'data.reservationId': String(reservationId) });
}

async function notifyHostApprovalExpired(reservation) {
  if (process.env.NODE_ENV === 'test') return;
  try {
    const notificationService = require('./notification.service');
    await notificationService.sendHostApprovalExpiredNotification(reservation);
  } catch (err) {
    logger.error('Notification host approval expired échouée', { err: err.message });
  }
  try {
    const SocketService = require('./socket.service');
    await SocketService.emitReservationStatusChange(
      reservation,
      'awaiting_approval',
      'expired'
    );
  } catch (err) {
    logger.warn(`Socket expire host approval: ${err.message}`);
  }
}

async function expireHostApprovalOnce(reservationId) {
  const session = await mongoose.startSession();
  session.startTransaction();
  try {
    const now = new Date();
    const expired = await Reservation.findOneAndUpdate(
      {
        _id: reservationId,
        status: 'awaiting_approval',
        hostApprovalDeadline: { $lte: now },
      },
      {
        $set: {
          status: 'expired',
          expirationReason: 'host_approval_timeout',
        },
        $push: {
          statusHistory: {
            status: 'expired',
            paymentStatus: 'pending',
            changedAt: now,
            reason: 'host_approval_timeout',
          },
        },
      },
      { new: true, session }
    ).populate('user residence partner');

    if (!expired) {
      await session.abortTransaction();
      structuredLog('HOST_APPROVAL_RACE_LOST', {
        reservationId: String(reservationId),
      });
      return { expired: false, reason: 'already_transitioned' };
    }

    const residenceId = expired.residence._id || expired.residence;
    await acquire(residenceId, [{
      checkIn: expired.checkIn,
      checkOut: expired.checkOut,
    }], session);
    await release({
      residenceId,
      checkIn: expired.checkIn,
      checkOut: expired.checkOut,
      reservationId: expired._id,
      bookingType: expired.bookingType || 'day',
      session,
    });

    await session.commitTransaction();

    structuredLog('HOST_APPROVAL_EXPIRED', {
      reservationId: String(expired._id),
      residenceId: String(residenceId),
      partnerId: String(expired.partner?._id || expired.partner || ''),
      deadline: expired.hostApprovalDeadline ? expired.hostApprovalDeadline.toISOString() : undefined,
    });

    return { expired: true, reservation: expired };
  } catch (error) {
    if (session.inTransaction()) {
      await session.abortTransaction();
    }
    throw error;
  } finally {
    session.endSession();
  }
}

async function expireHostApproval(reservationId) {
  const result = await withRetry(() => expireHostApprovalOnce(reservationId));
  if (result.expired && result.reservation) {
    await notifyHostApprovalExpired(result.reservation);
  }
  return result;
}

async function approveHostRequest(reservationId, partnerId) {
  const current = await Reservation.findById(reservationId);
  if (!current) {
    throw new ApiError('Réservation non trouvée', 404, errorCodes.RESERVATION.NOT_FOUND);
  }

  if (current.status === 'expired') {
    throw new ApiError(
      'Cette demande a expiré. Les dates ont été libérées.',
      409,
      errorCodes.RESERVATION.APPROVAL_EXPIRED
    );
  }

  if (current.status !== 'awaiting_approval') {
    throw new ApiError(
      'Cette réservation ne peut pas être approuvée dans son état actuel',
      400,
      errorCodes.RESERVATION.INVALID_STATE_TRANSITION
    );
  }

  const now = new Date();
  const deadline = resolveDeadline(current);
  if (!current.hostApprovalDeadline) {
    await Reservation.updateOne(
      { _id: reservationId, status: 'awaiting_approval', hostApprovalDeadline: { $exists: false } },
      { $set: { hostApprovalDeadline: deadline } }
    );
  }

  if (deadline <= now) {
    await expireHostApproval(reservationId);
    throw new ApiError(
      'Cette demande a expiré. Les dates ont été libérées.',
      409,
      errorCodes.RESERVATION.APPROVAL_EXPIRED
    );
  }

  const paymentTTL = current.ttlSnapshot?.paymentTTLMinutes || current.paymentTimerDuration || 30;
  const paymentDeadline = new Date(now.getTime() + paymentTTL * 60 * 1000);

  const updated = await Reservation.findOneAndUpdate(
    {
      _id: reservationId,
      status: 'awaiting_approval',
      hostApprovalDeadline: { $gt: now },
    },
    {
      $set: {
        status: 'payment_pending',
        paymentDeadline,
        paymentTimerDuration: paymentTTL,
      },
      $push: {
        statusHistory: {
          status: 'payment_pending',
          paymentStatus: 'pending',
          changedAt: now,
          changedBy: partnerId,
          reason: 'host_approved',
        },
      },
    },
    { new: true }
  ).populate('user residence partner');

  if (!updated) {
    await expireHostApproval(reservationId);
    throw new ApiError(
      'Cette demande a expiré. Les dates ont été libérées.',
      409,
      errorCodes.RESERVATION.APPROVAL_EXPIRED
    );
  }

  await cancelHostApprovalExpiration(reservationId);

  const paymentTimerService = require('./payment-timer.service');
  await paymentTimerService.startPaymentTimer(updated._id, paymentTTL);

  structuredLog('HOST_APPROVAL_APPROVED', {
    reservationId: String(updated._id),
    residenceId: String(updated.residence?._id || updated.residence || ''),
    partnerId: String(partnerId || ''),
    deadline: deadline.toISOString(),
  });

  return updated;
}

async function sweepExpiredHostApprovals() {
  const due = await Reservation.find({
    status: 'awaiting_approval',
    hostApprovalDeadline: { $lte: new Date() },
  }).select('_id');

  const results = [];
  for (const row of due) {
    try {
      results.push(await expireHostApproval(row._id));
    } catch (err) {
      logger.error('Sweep host approval failed', {
        reservationId: String(row._id),
        err: err.message,
      });
      results.push({ expired: false, reservationId: row._id, error: err.message });
    }
  }
  return results;
}

module.exports = {
  JOB_NAME,
  DEFAULT_HOST_ACCEPT_TTL_MINUTES,
  computeHostApprovalDeadline,
  resolveDeadline,
  scheduleHostApprovalExpiration,
  cancelHostApprovalExpiration,
  expireHostApproval,
  approveHostRequest,
  sweepExpiredHostApprovals,
};
