/**
 * P1-02 — blocks Partner autoritatifs.
 *
 * Ancien Residence.blockedDates : LEGACY. Le champ n'existe même pas au schéma
 * Residence (strict Mongoose) → les PUT /availability/block n'écrivaient rien
 * de fiable, et createReservation ne le lisait pas. Availability.status=blocked
 * existait mais n'était pas posé par blockDates.
 *
 * Source de vérité : AvailabilityBlock + inventory.service.guardSlot
 * (+ Availability journalier pour day/week/month, comme les Reservations).
 * external_booking = P1-03 (entité séparée).
 */
const mongoose = require('mongoose');
const Residence = require('../models/residence.model');
const Availability = require('../models/availability.model');
const AvailabilityBlock = require('../models/availability-block.model');
const ApiError = require('../utils/apiError');
const errorCodes = require('../utils/errorCodes');
const logger = require('../utils/logger');
const { guardSlot, acquire, withRetry } = require('./inventory.service');

const BLOCK_TYPES = AvailabilityBlock.BLOCK_TYPES || [
  'personal_use', 'maintenance', 'cleaning', 'renovation', 'administrative', 'other',
];

function assertCanManageResidence(user, residence) {
  if (!user) {
    throw new ApiError('Authentification requise', 401, errorCodes.GENERAL.UNAUTHORIZED);
  }
  if (['admin', 'superadmin'].includes(user.role)) return;
  const partnerId = residence.partner?._id || residence.partner;
  if (String(partnerId) !== String(user._id)) {
    throw new ApiError(
      'Accès non autorisé à cette résidence',
      403,
      errorCodes.RESIDENCE.UNAUTHORIZED_ACCESS
    );
  }
}

function parseRange(payload) {
  const start = new Date(payload.startDate || payload.start || payload.checkIn);
  const end = new Date(payload.endDate || payload.end || payload.checkOut);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime()) || !(start < end)) {
    throw new ApiError(
      'Période de blocage invalide',
      400,
      errorCodes.INVENTORY.INVALID_BLOCK_PERIOD
    );
  }
  if (end <= new Date()) {
    throw new ApiError(
      'Impossible de créer un bloc entièrement passé',
      400,
      errorCodes.INVENTORY.INVALID_BLOCK_PERIOD
    );
  }
  return { start, end };
}

async function writeBlockedAvailability({ residenceId, start, end, blockId, session }) {
  const dates = [];
  const currentDate = new Date(start);
  while (currentDate < end) {
    dates.push({
      residenceId,
      date: new Date(currentDate),
      status: 'blocked',
      reservationId: null,
      sourceType: 'manual_block',
      sourceId: blockId,
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

async function clearBlockedAvailability({ residenceId, blockId, session }) {
  const q = Availability.updateMany(
    {
      residenceId,
      sourceType: 'manual_block',
      sourceId: blockId,
      status: 'blocked',
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

async function createBlock(user, payload) {
  const residenceId = payload.residenceId || payload.residence;
  const residence = await Residence.findById(residenceId);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);

  const { start, end } = parseRange(payload);
  const bookingType = payload.bookingType || 'day';
  const type = BLOCK_TYPES.includes(payload.type) ? payload.type : 'other';
  const reason = payload.reason || '';

  return withRetry(async () => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
      await guardSlot({
        residenceId: residence._id,
        checkIn: start,
        checkOut: end,
        purpose: 'block',
        session,
      });

      const [block] = await AvailabilityBlock.create([{
        residence: residence._id,
        start,
        end,
        bookingType,
        type,
        reason,
        status: 'active',
        sourceType: 'manual_block',
        createdBy: user._id,
      }], { session });

      if (bookingType !== 'hour') {
        await writeBlockedAvailability({
          residenceId: residence._id,
          start,
          end,
          blockId: block._id,
          session,
        });
      }

      await session.commitTransaction();
      session.endSession();
      logger.info('PARTNER_BLOCK_CREATED', {
        event: 'PARTNER_BLOCK_CREATED',
        blockId: String(block._id),
        residenceId: String(residence._id),
        bookingType,
        type,
      });
      return block;
    } catch (err) {
      if (session.inTransaction()) await session.abortTransaction();
      session.endSession();
      throw err;
    }
  });
}

async function releaseBlock(user, blockId) {
  const block = await AvailabilityBlock.findById(blockId);
  if (!block) {
    throw new ApiError('Bloc introuvable', 404, errorCodes.INVENTORY.BLOCK_NOT_FOUND);
  }
  if (block.sourceType !== 'manual_block') {
    throw new ApiError(
      'Cette occupation n\'est pas un bloc manuel',
      403,
      errorCodes.INVENTORY.BLOCK_NOT_OWNED
    );
  }

  const residence = await Residence.findById(block.residence);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);

  if (block.status === 'released') {
    return block;
  }

  return withRetry(async () => {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
      await acquire(residence._id, [{ checkIn: block.start, checkOut: block.end }], session);

      const released = await AvailabilityBlock.findOneAndUpdate(
        { _id: block._id, status: 'active', sourceType: 'manual_block' },
        {
          $set: {
            status: 'released',
            releasedAt: new Date(),
            releasedBy: user._id,
          },
        },
        { new: true, session }
      );

      if (!released) {
        await session.abortTransaction();
        session.endSession();
        const current = await AvailabilityBlock.findById(blockId);
        if (current?.status === 'released') return current;
        throw new ApiError('Bloc introuvable', 404, errorCodes.INVENTORY.BLOCK_NOT_FOUND);
      }

      await clearBlockedAvailability({
        residenceId: residence._id,
        blockId: released._id,
        session,
      });

      await session.commitTransaction();
      session.endSession();
      logger.info('PARTNER_BLOCK_RELEASED', {
        event: 'PARTNER_BLOCK_RELEASED',
        blockId: String(released._id),
        residenceId: String(residence._id),
      });
      return released;
    } catch (err) {
      if (session.inTransaction()) await session.abortTransaction();
      session.endSession();
      throw err;
    }
  });
}

async function listBlocks(user, { residenceId, status = 'active' } = {}) {
  const residence = await Residence.findById(residenceId);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);
  const filter = { residence: residenceId };
  if (status) filter.status = status;
  return AvailabilityBlock.find(filter).sort({ start: 1 }).lean();
}

async function unblockRange(user, { residenceId, startDate, endDate }) {
  const residence = await Residence.findById(residenceId);
  if (!residence) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }
  assertCanManageResidence(user, residence);
  const start = new Date(startDate);
  const end = new Date(endDate);
  const blocks = await AvailabilityBlock.find({
    residence: residenceId,
    status: 'active',
    sourceType: 'manual_block',
    start: { $lt: end },
    end: { $gt: start },
  });
  const released = [];
  for (const block of blocks) {
    released.push(await releaseBlock(user, block._id));
  }
  return released;
}

module.exports = {
  BLOCK_TYPES,
  createBlock,
  releaseBlock,
  listBlocks,
  unblockRange,
  assertCanManageResidence,
};
