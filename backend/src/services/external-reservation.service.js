/**
 * P1-03 — ExternalReservation autoritative via inventory.service.
 * Aucun Payment / Payout / commission / paymentDeadline.
 */
const mongoose = require('mongoose');
const Residence = require('../models/residence.model');
const Availability = require('../models/availability.model');
const ExternalReservation = require('../models/external-reservation.model');
const ApiError = require('../utils/apiError');
const errorCodes = require('../utils/errorCodes');
const logger = require('../utils/logger');
const { guardSlot, acquire, withRetry } = require('./inventory.service');
const { assertCanManageResidence } = require('./partner-block.service');

const CHANNELS = ExternalReservation.CHANNELS;

function parseRange(payload) {
  const checkIn = new Date(payload.checkIn || payload.startDate || payload.start);
  const checkOut = new Date(payload.checkOut || payload.endDate || payload.end);
  if (Number.isNaN(checkIn.getTime()) || Number.isNaN(checkOut.getTime()) || !(checkIn < checkOut)) {
    throw new ApiError(
      'Période externe invalide',
      400,
      errorCodes.INVENTORY.INVALID_EXTERNAL_PERIOD
    );
  }
  if (checkOut <= new Date()) {
    throw new ApiError(
      'Impossible de créer une réservation externe entièrement passée',
      400,
      errorCodes.INVENTORY.INVALID_EXTERNAL_PERIOD
    );
  }
  return { checkIn, checkOut };
}

function sanitizeGuest(payload) {
  return {
    channel: CHANNELS.includes(payload.channel) ? payload.channel : 'other',
    guestName: payload.guestName ? String(payload.guestName).slice(0, 120) : '',
    guestPhone: payload.guestPhone ? String(payload.guestPhone).slice(0, 40) : '',
    externalReference: payload.externalReference ? String(payload.externalReference).slice(0, 120) : '',
    notes: payload.notes ? String(payload.notes).slice(0, 500) : '',
  };
}

async function writeOccupiedAvailability({ residenceId, start, end, externalId, session }) {
  const dates = [];
  const currentDate = new Date(start);
  while (currentDate < end) {
    dates.push({
      residenceId,
      date: new Date(currentDate),
      status: 'reserved',
      reservationId: null,
      sourceType: 'external_reservation',
      sourceId: externalId,
      lastModified: new Date(),
    });
    currentDate.setDate(currentDate.getDate() + 1);
  }
  if (dates.length === 0) return;
  try {
    await Availability.upsertBulk(dates, { session, failIfOccupied: true });
  } catch (err) {
    if (err?.code === 11000 || err?.code === 11001 || /E11000|duplicate/i.test(err?.message || '')) {
      throw new ApiError(
        'Ces dates sont déjà occupées',
        409,
        errorCodes.INVENTORY.ALREADY_RESERVED
      );
    }
    throw err;
  }
}

async function clearOccupiedAvailability({ residenceId, externalId, session }) {
  const q = Availability.updateMany(
    {
      residenceId,
      sourceType: 'external_reservation',
      sourceId: externalId,
      status: 'reserved',
    },
    {
      $set: {
        status: 'available',
        sourceType: null,
        sourceId: null,
        reservationId: null,
      },
    }
  );
  if (session) q.session(session);
  return q;
}

async function createExternalReservation(user, payload) {
  const residenceId = payload.residenceId || payload.residence;
  const residence = await Residence.findById(residenceId);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);

  const { checkIn, checkOut } = parseRange(payload);
  const bookingType = payload.bookingType || 'day';
  const guest = sanitizeGuest(payload);

  return withRetry(async () => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
      await guardSlot({
        residenceId: residence._id,
        checkIn,
        checkOut,
        purpose: 'external',
        session,
      });

      const [external] = await ExternalReservation.create([{
        residence: residence._id,
        partner: residence.partner,
        checkIn,
        checkOut,
        bookingType,
        ...guest,
        status: 'active',
        sourceType: 'external_reservation',
        createdBy: user._id,
      }], { session });

      if (bookingType !== 'hour') {
        await writeOccupiedAvailability({
          residenceId: residence._id,
          start: checkIn,
          end: checkOut,
          externalId: external._id,
          session,
        });
      }

      await session.commitTransaction();
      session.endSession();
      logger.info('EXTERNAL_RESERVATION_CREATED', {
        event: 'EXTERNAL_RESERVATION_CREATED',
        externalId: String(external._id),
        residenceId: String(residence._id),
        bookingType,
        channel: guest.channel,
      });
      return external;
    } catch (err) {
      if (session.inTransaction()) await session.abortTransaction();
      session.endSession();
      throw err;
    }
  });
}

async function modifyExternalReservation(user, externalId, payload) {
  const current = await ExternalReservation.findById(externalId);
  if (!current) {
    throw new ApiError('Réservation externe introuvable', 404, errorCodes.INVENTORY.EXTERNAL_NOT_FOUND);
  }
  if (current.sourceType !== 'external_reservation') {
    throw new ApiError(
      'Cette occupation n\'est pas une réservation externe',
      403,
      errorCodes.INVENTORY.EXTERNAL_NOT_OWNED
    );
  }
  if (current.status !== 'active') {
    throw new ApiError(
      'Cette réservation externe ne peut plus être modifiée',
      409,
      errorCodes.INVENTORY.EXTERNAL_NOT_MODIFIABLE
    );
  }

  const residence = await Residence.findById(current.residence);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);

  const nextCheckIn = (payload.checkIn || payload.startDate)
    ? new Date(payload.checkIn || payload.startDate)
    : current.checkIn;
  const nextCheckOut = (payload.checkOut || payload.endDate)
    ? new Date(payload.checkOut || payload.endDate)
    : current.checkOut;
  if (Number.isNaN(nextCheckIn.getTime()) || Number.isNaN(nextCheckOut.getTime()) || !(nextCheckIn < nextCheckOut)) {
    throw new ApiError(
      'Période externe invalide',
      400,
      errorCodes.INVENTORY.INVALID_EXTERNAL_PERIOD
    );
  }

  const datesChanged = nextCheckIn.getTime() !== current.checkIn.getTime()
    || nextCheckOut.getTime() !== current.checkOut.getTime()
    || (payload.bookingType && payload.bookingType !== current.bookingType);
  const nextBookingType = payload.bookingType || current.bookingType;
  const guest = sanitizeGuest({ ...current.toObject(), ...payload });

  return withRetry(async () => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
      if (datesChanged) {
        await guardSlot({
          residenceId: residence._id,
          checkIn: nextCheckIn,
          checkOut: nextCheckOut,
          excludeExternalId: current._id,
          extraRanges: [{ checkIn: current.checkIn, checkOut: current.checkOut }],
          purpose: 'external',
          session,
        });
      } else {
        await acquire(residence._id, [{ checkIn: current.checkIn, checkOut: current.checkOut }], session);
      }

      const updated = await ExternalReservation.findOneAndUpdate(
        { _id: current._id, status: 'active', sourceType: 'external_reservation' },
        {
          $set: {
            checkIn: nextCheckIn,
            checkOut: nextCheckOut,
            bookingType: nextBookingType,
            channel: guest.channel,
            guestName: guest.guestName,
            guestPhone: guest.guestPhone,
            externalReference: guest.externalReference,
            notes: guest.notes,
          },
        },
        { new: true, session }
      );

      if (!updated) {
        await session.abortTransaction();
        session.endSession();
        throw new ApiError(
          'Cette réservation externe ne peut plus être modifiée',
          409,
          errorCodes.INVENTORY.EXTERNAL_NOT_MODIFIABLE
        );
      }

      if (datesChanged) {
        await clearOccupiedAvailability({
          residenceId: residence._id,
          externalId: updated._id,
          session,
        });
        if (nextBookingType !== 'hour') {
          await writeOccupiedAvailability({
            residenceId: residence._id,
            start: nextCheckIn,
            end: nextCheckOut,
            externalId: updated._id,
            session,
          });
        }
      }

      await session.commitTransaction();
      session.endSession();
      logger.info('EXTERNAL_RESERVATION_MODIFIED', {
        event: 'EXTERNAL_RESERVATION_MODIFIED',
        externalId: String(updated._id),
        residenceId: String(residence._id),
        datesChanged,
      });
      return updated;
    } catch (err) {
      if (session.inTransaction()) await session.abortTransaction();
      session.endSession();
      throw err;
    }
  });
}

async function closeExternalReservation(user, externalId, nextStatus) {
  const current = await ExternalReservation.findById(externalId);
  if (!current) {
    throw new ApiError('Réservation externe introuvable', 404, errorCodes.INVENTORY.EXTERNAL_NOT_FOUND);
  }
  if (current.sourceType !== 'external_reservation') {
    throw new ApiError(
      'Cette occupation n\'est pas une réservation externe',
      403,
      errorCodes.INVENTORY.EXTERNAL_NOT_OWNED
    );
  }

  const residence = await Residence.findById(current.residence);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);

  if (current.status === nextStatus) {
    return current;
  }
  if (current.status !== 'active') {
    throw new ApiError(
      'Cette réservation externe ne peut plus changer de statut',
      409,
      errorCodes.INVENTORY.EXTERNAL_NOT_MODIFIABLE
    );
  }

  return withRetry(async () => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
      await acquire(residence._id, [{ checkIn: current.checkIn, checkOut: current.checkOut }], session);

      const closeSet = nextStatus === 'cancelled'
        ? { status: 'cancelled', cancelledAt: new Date(), cancelledBy: user._id }
        : { status: 'completed', completedAt: new Date(), actualCheckOut: new Date() };

      const closed = await ExternalReservation.findOneAndUpdate(
        { _id: current._id, status: 'active', sourceType: 'external_reservation' },
        { $set: closeSet },
        { new: true, session }
      );

      if (!closed) {
        await session.abortTransaction();
        session.endSession();
        const latest = await ExternalReservation.findById(externalId);
        if (latest?.status === nextStatus) return latest;
        throw new ApiError(
          'Cette réservation externe ne peut plus changer de statut',
          409,
          errorCodes.INVENTORY.EXTERNAL_NOT_MODIFIABLE
        );
      }

      await clearOccupiedAvailability({
        residenceId: residence._id,
        externalId: closed._id,
        session,
      });

      await session.commitTransaction();
      session.endSession();
      logger.info('EXTERNAL_RESERVATION_CLOSED', {
        event: 'EXTERNAL_RESERVATION_CLOSED',
        externalId: String(closed._id),
        residenceId: String(residence._id),
        status: nextStatus,
      });
      return closed;
    } catch (err) {
      if (session.inTransaction()) await session.abortTransaction();
      session.endSession();
      throw err;
    }
  });
}

async function cancelExternalReservation(user, externalId) {
  return closeExternalReservation(user, externalId, 'cancelled');
}

async function completeExternalReservation(user, externalId) {
  return closeExternalReservation(user, externalId, 'completed');
}

async function getExternalReservation(user, externalId) {
  const external = await ExternalReservation.findById(externalId);
  if (!external) {
    throw new ApiError('Réservation externe introuvable', 404, errorCodes.INVENTORY.EXTERNAL_NOT_FOUND);
  }
  const residence = await Residence.findById(external.residence);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);
  return external;
}

async function listExternalReservations(user, { residenceId, status = 'active' } = {}) {
  const residence = await Residence.findById(residenceId);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);
  const filter = { residence: residenceId };
  if (status) filter.status = status;
  return ExternalReservation.find(filter).sort({ checkIn: 1 });
}

module.exports = {
  CHANNELS,
  createExternalReservation,
  modifyExternalReservation,
  cancelExternalReservation,
  completeExternalReservation,
  getExternalReservation,
  listExternalReservations,
  toPublicOccupation: ExternalReservation.toPublicOccupation,
  toPartnerView: ExternalReservation.toPartnerView,
};
