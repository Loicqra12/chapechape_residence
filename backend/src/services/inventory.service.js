const InventoryLock = require('../models/inventory-lock.model');
const Reservation = require('../models/reservation.model');
const ApiError = require('../utils/apiError');
const errorCodes = require('../utils/errorCodes');
const logger = require('../utils/logger');
const { ACTIVE_BLOCKING_STATUSES } = require('../constants/reservation-status');

const MAX_INVENTORY_TXN_ATTEMPTS = 8;

/**
 * Jours calendaires UTC touchés : [startOfUtcDay(checkIn), checkOut).
 * Une plage 22 23:00 → 23 02:00 verrouille le 22 et le 23.
 * Ordre lexicographique ISO = ordre croissant (anti-deadlock).
 */
function inventoryDayKeys(residenceId, checkIn, checkOut) {
  const keys = [];
  const start = new Date(checkIn);
  const end = new Date(checkOut);
  const current = new Date(Date.UTC(
    start.getUTCFullYear(),
    start.getUTCMonth(),
    start.getUTCDate()
  ));

  while (current < end) {
    keys.push(`${residenceId}:${current.toISOString().slice(0, 10)}`);
    current.setUTCDate(current.getUTCDate() + 1);
  }

  return [...new Set(keys)].sort();
}

function isRetryableTransactionError(err) {
  if (!err) return false;
  if (Array.isArray(err.errorLabels) && (
    err.errorLabels.includes('TransientTransactionError')
    || err.errorLabels.includes('UnknownTransactionCommitResult')
  )) {
    return true;
  }
  if (err.code === 112 || err.codeName === 'WriteConflict') return true;
  if (err.code === 251 || err.codeName === 'NoSuchTransaction') return true;
  if (err.code === 11000) {
    const dup = `${err.message || ''} ${err.errmsg || ''} ${JSON.stringify(err.keyPattern || {})}`;
    if (/InventoryLock|inventorylocks|"key"/i.test(dup)) return true;
  }
  const msg = `${err.message || ''} ${err.errmsg || ''}`;
  return /WriteConflict|TransientTransactionError|UnknownTransactionCommitResult|Unable to read from a snapshot|has been aborted/i.test(msg);
}

function throwDateConflict(residenceId, overlappingId) {
  logger.info('RESERVATION_CONFLICT', {
    event: 'RESERVATION_CONFLICT',
    residenceId: String(residenceId),
    overlappingId: overlappingId ? String(overlappingId) : undefined,
  });
  throw new ApiError(
    'Ces dates viennent d\'être réservées par un autre client',
    409,
    errorCodes.RESERVATION.DATE_CONFLICT
  );
}

function throwAlreadyReserved(residenceId, overlappingId) {
  logger.info('INVENTORY_ALREADY_RESERVED', {
    event: 'INVENTORY_ALREADY_RESERVED',
    residenceId: String(residenceId),
    overlappingId: overlappingId ? String(overlappingId) : undefined,
  });
  throw new ApiError(
    'Ces dates sont déjà réservées',
    409,
    errorCodes.INVENTORY.ALREADY_RESERVED
  );
}

function throwBlockConflict(residenceId, overlappingId) {
  logger.info('INVENTORY_BLOCK_CONFLICT', {
    event: 'INVENTORY_BLOCK_CONFLICT',
    residenceId: String(residenceId),
    overlappingId: overlappingId ? String(overlappingId) : undefined,
  });
  throw new ApiError(
    'Ces dates sont bloquées',
    409,
    errorCodes.INVENTORY.BLOCK_CONFLICT
  );
}

function throwExternalConflict(residenceId, overlappingId) {
  logger.info('EXTERNAL_RESERVATION_CONFLICT', {
    event: 'EXTERNAL_RESERVATION_CONFLICT',
    residenceId: String(residenceId),
    overlappingId: overlappingId ? String(overlappingId) : undefined,
  });
  throw new ApiError(
    'Ces dates sont déjà occupées par une réservation externe',
    409,
    errorCodes.INVENTORY.EXTERNAL_CONFLICT
  );
}

function mapInventoryError(error) {
  if (error instanceof ApiError) return error;
  if (error && error.statusCode && error.errorCode) return error;
  if (isRetryableTransactionError(error)) {
    logger.error('INVENTORY_TXN_RETRIES_EXHAUSTED', {
      event: 'INVENTORY_TXN_RETRIES_EXHAUSTED',
      message: error.message,
      code: error.code,
    });
    return new ApiError(
      'Service temporairement indisponible, veuillez réessayer',
      503,
      errorCodes.GENERAL.SERVICE_UNAVAILABLE
    );
  }
  return error;
}

/**
 * Mutex Mongo par jour, dans la transaction appelante.
 * Plusieurs plages → union des clés, triées.
 */
async function acquire(residenceId, ranges, session) {
  const keySet = new Set();
  for (const range of ranges) {
    if (!range || !range.checkIn || !range.checkOut) continue;
    for (const key of inventoryDayKeys(residenceId, range.checkIn, range.checkOut)) {
      keySet.add(key);
    }
  }
  const keys = [...keySet].sort();
  if (keys.length === 0) return keys;

  for (const key of keys) {
    await InventoryLock.findOneAndUpdate(
      { key },
      { $set: { key, acquiredAt: new Date() } },
      { upsert: true, session, new: true }
    );
  }

  logger.info('RESERVATION_INVENTORY_LOCK', {
    event: 'RESERVATION_INVENTORY_LOCK',
    residenceId: String(residenceId),
    keys,
  });

  return keys;
}

async function acquireInventoryLocks(residenceId, checkIn, checkOut, session) {
  return acquire(residenceId, [{ checkIn, checkOut }], session);
}

async function findOverlap({ residenceId, checkIn, checkOut, excludeId = null, session = null }) {
  const query = {
    residence: residenceId,
    status: { $in: ACTIVE_BLOCKING_STATUSES },
    checkIn: { $lt: new Date(checkOut) },
    checkOut: { $gt: new Date(checkIn) },
  };
  if (excludeId) {
    query._id = { $ne: excludeId };
  }
  const q = Reservation.findOne(query);
  if (session) q.session(session);
  return q;
}

async function findBlockOverlap({ residenceId, checkIn, checkOut, excludeId = null, session = null }) {
  const AvailabilityBlock = require('../models/availability-block.model');
  const query = {
    residence: residenceId,
    status: 'active',
    start: { $lt: new Date(checkOut) },
    end: { $gt: new Date(checkIn) },
  };
  if (excludeId) {
    query._id = { $ne: excludeId };
  }
  const q = AvailabilityBlock.findOne(query);
  if (session) q.session(session);
  return q;
}

async function findExternalOverlap({ residenceId, checkIn, checkOut, excludeId = null, session = null }) {
  const ExternalReservation = require('../models/external-reservation.model');
  const query = {
    residence: residenceId,
    status: 'active',
    checkIn: { $lt: new Date(checkOut) },
    checkOut: { $gt: new Date(checkIn) },
  };
  if (excludeId) {
    query._id = { $ne: excludeId };
  }
  const q = ExternalReservation.findOne(query);
  if (session) q.session(session);
  return q;
}

async function assertNoOverlap(params) {
  const overlapping = await findOverlap(params);
  if (overlapping) {
    if (params.purpose === 'reservation') {
      throwDateConflict(params.residenceId, overlapping._id);
    }
    throwAlreadyReserved(params.residenceId, overlapping._id);
  }
  const blockHit = await findBlockOverlap({
    residenceId: params.residenceId,
    checkIn: params.checkIn,
    checkOut: params.checkOut,
    excludeId: params.excludeBlockId || null,
    session: params.session,
  });
  if (blockHit) {
    throwBlockConflict(params.residenceId, blockHit._id);
  }
  const externalHit = await findExternalOverlap({
    residenceId: params.residenceId,
    checkIn: params.checkIn,
    checkOut: params.checkOut,
    excludeId: params.excludeExternalId || null,
    session: params.session,
  });
  if (externalHit) {
    if (params.purpose === 'external') {
      throwExternalConflict(params.residenceId, externalHit._id);
    }
    if (params.purpose === 'block') {
      throwAlreadyReserved(params.residenceId, externalHit._id);
    }
    throwDateConflict(params.residenceId, externalHit._id);
  }
  return null;
}

/**
 * Lock + overlap dans la session courante (politique unique create/modify/reacquire/block/external).
 * purpose: 'reservation' (défaut) | 'block' | 'external'
 */
async function guardSlot({
  residenceId,
  checkIn,
  checkOut,
  excludeId = null,
  excludeBlockId = null,
  excludeExternalId = null,
  extraRanges = [],
  purpose = 'reservation',
  session,
}) {
  const ranges = [{ checkIn, checkOut }, ...extraRanges];
  const keys = await acquire(residenceId, ranges, session);
  await assertNoOverlap({
    residenceId,
    checkIn,
    checkOut,
    excludeId,
    excludeBlockId,
    excludeExternalId,
    purpose,
    session,
  });
  return keys;
}

async function release({
  residenceId,
  checkIn,
  checkOut,
  reservationId,
  bookingType = 'day',
  session = null,
}) {
  const availabilityService = require('./availability.service');
  await availabilityService.updateAvailabilityForReservation(
    residenceId,
    checkIn,
    checkOut,
    reservationId,
    'available',
    bookingType,
    session
  );
  logger.info('INVENTORY_RELEASED', {
    event: 'INVENTORY_RELEASED',
    residenceId: String(residenceId),
    reservationId: String(reservationId),
    timestamp: new Date().toISOString(),
  });
}

async function withRetry(fn, maxAttempts = MAX_INVENTORY_TXN_ATTEMPTS) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn(attempt);
    } catch (error) {
      if (attempt < maxAttempts && isRetryableTransactionError(error)) {
        await new Promise((resolve) => setTimeout(resolve, 15 * attempt));
        continue;
      }
      throw mapInventoryError(error);
    }
  }
}

module.exports = {
  ACTIVE_BLOCKING_STATUSES,
  MAX_INVENTORY_TXN_ATTEMPTS,
  inventoryDayKeys,
  isRetryableTransactionError,
  mapInventoryError,
  acquire,
  acquireInventoryLocks,
  findOverlap,
  findBlockOverlap,
  findExternalOverlap,
  assertNoOverlap,
  guardSlot,
  withRetry,
  release,
};
