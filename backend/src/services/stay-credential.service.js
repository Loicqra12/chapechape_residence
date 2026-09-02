/**
 * P2-05C2 — Stay credential issuance / resolve / commit (QR optional).
 * Transitions stay restent via ReservationStateService uniquement.
 */
const Reservation = require('../models/reservation.model');
const ApiError = require('../utils/apiError');
const errorCodes = require('../utils/errorCodes');
const logger = require('../utils/logger');
const { idOf } = require('../security/resource-access');
const ReservationStateService = require('./reservation-state.service');
const {
  PURPOSE,
  purposeToSlot,
  generateCredential,
  parseCredential,
  isCredentialExpired,
  checkInWindowOpen,
  TTL_MS,
} = require('../security/stay-credential');

function isClientOwner(reservation, user) {
  if (!reservation || !user) return false;
  const uid = idOf(user._id || user.id);
  return uid === idOf(reservation.user) || uid === idOf(reservation.client);
}

function isPartnerOwner(reservation, user) {
  if (!reservation || !user) return false;
  const uid = idOf(user._id || user.id);
  const partnerId = idOf(reservation.partner);
  const residencePartnerId = idOf(reservation.residence?.partner);
  return uid === partnerId || (residencePartnerId && uid === residencePartnerId);
}

function logCredentialEvent(event, fields = {}) {
  logger.info(event, {
    event,
    reservationId: fields.reservationId ? String(fields.reservationId) : undefined,
    purpose: fields.purpose,
    version: fields.version,
    reason: fields.reason,
  });
}

function assertClientCanIssue(reservation, user, purpose) {
  if (!isClientOwner(reservation, user)) {
    throw new ApiError('Accès non autorisé à cette réservation', 403);
  }

  if (purpose === PURPOSE.CHECKIN) {
    if (reservation.status !== 'confirmed' || reservation.paymentStatus !== 'paid') {
      throw new ApiError(
        'Credential check-in non éligible',
        400,
        errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE
      );
    }
    if (!checkInWindowOpen(reservation.checkIn)) {
      throw new ApiError(
        'Le check-in ne peut être effectué que 2 heures avant l\'heure prévue',
        400,
        errorCodes.RESERVATION.CHECKIN_TOO_EARLY
      );
    }
    return;
  }

  if (purpose === PURPOSE.CHECKOUT) {
    if (reservation.status !== 'in_stay' || !reservation.actualCheckIn) {
      throw new ApiError(
        'Credential checkout non éligible',
        400,
        errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE
      );
    }
    return;
  }

  throw new ApiError('Purpose invalide', 400, errorCodes.STAY_CREDENTIAL.INVALID);
}

/**
 * Issue or regenerate a stay credential for the Client owner.
 *
 * Concurrent semantics (Option B):
 * - Multiple simultaneous issues may all succeed.
 * - version is incremented atomically via $inc (no lost/duplicate versions).
 * - last write wins on tokenHash; earlier returned credentials become invalid immediately.
 */
async function issueCredential(reservationId, purpose, clientUser) {
  const reservation = await Reservation.findById(reservationId).select(
    '+stayCredentials status paymentStatus checkIn checkOut actualCheckIn user client partner'
  );
  if (!reservation) {
    throw new ApiError('Réservation non trouvée', 404, errorCodes.RESERVATION.NOT_FOUND);
  }

  assertClientCanIssue(reservation, clientUser, purpose);

  const slot = purposeToSlot(purpose);
  const current = reservation.stayCredentials?.[slot];
  const { credential, tokenHash } = generateCredential();
  const now = new Date();
  const expiresAt = new Date(now.getTime() + TTL_MS);

  const path = `stayCredentials.${slot}`;
  const updated = await Reservation.findOneAndUpdate(
    {
      _id: reservationId,
      status: purpose === PURPOSE.CHECKIN ? 'confirmed' : 'in_stay',
      ...(purpose === PURPOSE.CHECKIN ? { paymentStatus: 'paid' } : {}),
    },
    {
      $set: {
        [`${path}.tokenHash`]: tokenHash,
        [`${path}.issuedAt`]: now,
        [`${path}.expiresAt`]: expiresAt,
        [`${path}.consumedAt`]: null,
      },
      $inc: {
        [`${path}.version`]: 1,
      },
    },
    { new: true, select: '+stayCredentials' }
  );

  if (!updated) {
    throw new ApiError(
      'Credential non éligible (état réservation changé)',
      409,
      errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE
    );
  }

  const finalVersion = updated.stayCredentials?.[slot]?.version || 1;
  const event =
    current?.tokenHash && !current.consumedAt
      ? 'STAY_CREDENTIAL_REGENERATED'
      : 'STAY_CREDENTIAL_ISSUED';
  logCredentialEvent(event, {
    reservationId,
    purpose,
    version: finalVersion,
  });

  return {
    credential,
    purpose,
    expiresAt: expiresAt.toISOString(),
    version: finalVersion,
  };
}

/**
 * Non-mutating Partner resolve / preview.
 * Anti-oracle: errors before ownership are generic INVALID.
 */
async function resolveCredential(credentialRaw, purpose, partnerUser) {
  const parsed = parseCredential(credentialRaw);
  if (!parsed) {
    logCredentialEvent('STAY_CREDENTIAL_VALIDATION_FAILED', { purpose, reason: 'format' });
    throw new ApiError('Credential invalide', 400, errorCodes.STAY_CREDENTIAL.INVALID);
  }

  const slot = purposeToSlot(purpose);
  if (!slot) {
    throw new ApiError('Credential invalide', 400, errorCodes.STAY_CREDENTIAL.INVALID);
  }

  const hashPath = `stayCredentials.${slot}.tokenHash`;
  const reservation = await Reservation.findOne({ [hashPath]: parsed.tokenHash })
    .select('+stayCredentials status paymentStatus checkIn checkOut actualCheckIn user partner residence')
    .populate('residence', 'title city partner')
    .populate('user', 'firstName lastName');

  if (!reservation) {
    logCredentialEvent('STAY_CREDENTIAL_VALIDATION_FAILED', { purpose, reason: 'unknown_hash' });
    throw new ApiError('Credential invalide', 400, errorCodes.STAY_CREDENTIAL.INVALID);
  }

  if (!isPartnerOwner(reservation, partnerUser)) {
    logCredentialEvent('STAY_CREDENTIAL_VALIDATION_FAILED', {
      reservationId: reservation._id,
      purpose,
      reason: 'ownership',
    });
    throw new ApiError('Credential invalide', 400, errorCodes.STAY_CREDENTIAL.INVALID);
  }

  const cred = reservation.stayCredentials?.[slot];
  if (!cred || cred.tokenHash !== parsed.tokenHash) {
    throw new ApiError('Credential invalide', 400, errorCodes.STAY_CREDENTIAL.INVALID);
  }

  if (cred.consumedAt) {
    throw new ApiError('Credential déjà consommé', 400, errorCodes.STAY_CREDENTIAL.CONSUMED);
  }
  if (isCredentialExpired(cred.expiresAt)) {
    throw new ApiError('Credential expiré', 400, errorCodes.STAY_CREDENTIAL.EXPIRED);
  }

  if (purpose === PURPOSE.CHECKIN) {
    if (reservation.status !== 'confirmed' || reservation.paymentStatus !== 'paid') {
      throw new ApiError('Réservation non éligible', 400, errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE);
    }
    if (!checkInWindowOpen(reservation.checkIn)) {
      throw new ApiError(
        'Le check-in ne peut être effectué que 2 heures avant l\'heure prévue',
        400,
        errorCodes.RESERVATION.CHECKIN_TOO_EARLY
      );
    }
  } else if (purpose === PURPOSE.CHECKOUT) {
    if (reservation.status !== 'in_stay' || !reservation.actualCheckIn) {
      throw new ApiError('Réservation non éligible', 400, errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE);
    }
  }

  const client = reservation.user;
  const displayName =
    client && typeof client === 'object'
      ? `${client.firstName || ''} ${client.lastName || ''}`.trim() || null
      : null;

  return {
    reservationId: String(reservation._id),
    residence: reservation.residence
      ? {
          id: String(reservation.residence._id),
          title: reservation.residence.title,
          city: reservation.residence.city,
        }
      : null,
    clientDisplayName: displayName,
    checkIn: reservation.checkIn,
    checkOut: reservation.checkOut,
    status: reservation.status,
    purpose,
    expiresAt: cred.expiresAt,
  };
}

async function loadForIdempotentRetry(reservationId, purpose, tokenHash, actorUser) {
  const slot = purposeToSlot(purpose);
  const targetStatus = purpose === PURPOSE.CHECKIN ? 'in_stay' : 'completed';
  const reservation = await Reservation.findById(reservationId)
    .select('+stayCredentials status partner residence')
    .populate('residence', 'partner')
    .populate(['user', 'partner']);
  if (!reservation) return null;

  // Strict: ownership required before alreadyApplied
  if (!isPartnerOwner(reservation, actorUser)) {
    return null;
  }

  const cred = reservation.stayCredentials?.[slot];
  if (
    reservation.status === targetStatus
    && cred
    && cred.tokenHash === tokenHash
    && cred.consumedAt
  ) {
    return reservation;
  }
  return null;
}

/**
 * Atomic commit via ReservationStateService + credential filter.
 * Optional credential: if absent, caller uses manual P2-05B path.
 *
 * alreadyApplied requires ALL of:
 * partner ownership + same reservationId + same purpose + same tokenHash
 * + consumedAt set + exact target status
 */
async function commitWithCredential(reservationId, purpose, credentialRaw, actorUser, options = {}) {
  const parsed = parseCredential(credentialRaw);
  if (!parsed) {
    throw new ApiError('Credential invalide', 400, errorCodes.STAY_CREDENTIAL.INVALID);
  }

  const reservationGate = await Reservation.findById(reservationId)
    .select('partner residence status')
    .populate('residence', 'partner');
  if (!reservationGate) {
    throw new ApiError('Réservation non trouvée', 404, errorCodes.RESERVATION.NOT_FOUND);
  }
  if (!isPartnerOwner(reservationGate, actorUser)) {
    throw new ApiError('Accès non autorisé à cette réservation', 403);
  }

  // Wrong purpose slot: hash won't match other slot → INVALID (or explicit mismatch if found other)
  const otherPurpose = purpose === PURPOSE.CHECKIN ? PURPOSE.CHECKOUT : PURPOSE.CHECKIN;
  const otherSlot = purposeToSlot(otherPurpose);
  const wrongSlotHit = await Reservation.findOne({
    [`stayCredentials.${otherSlot}.tokenHash`]: parsed.tokenHash,
  }).select('_id');
  if (wrongSlotHit) {
    throw new ApiError(
      'Purpose credential incorrect',
      400,
      errorCodes.STAY_CREDENTIAL.PURPOSE_MISMATCH
    );
  }

  const targetStatus = purpose === PURPOSE.CHECKIN ? 'in_stay' : 'completed';
  const fromStatuses = purpose === PURPOSE.CHECKIN ? ['confirmed'] : ['in_stay'];
  const reason = options.reason || `partner_${purpose}_credential`;

  try {
    const updated = await ReservationStateService.updateStatus(
      reservationId,
      targetStatus,
      actorUser._id,
      {
        reason,
        fromStatuses,
        stayCredential: {
          purpose,
          tokenHash: parsed.tokenHash,
        },
      }
    );
    logCredentialEvent('STAY_CREDENTIAL_CONSUMED', {
      reservationId,
      purpose,
    });
    return { reservation: updated, alreadyApplied: false };
  } catch (err) {
    const idempotent = await loadForIdempotentRetry(
      reservationId,
      purpose,
      parsed.tokenHash,
      actorUser
    );
    if (idempotent) {
      return { reservation: idempotent, alreadyApplied: true };
    }

    if (err.errorCode === errorCodes.RESERVATION.CONCURRENT_MODIFICATION) {
      const current = await Reservation.findById(reservationId).select('+stayCredentials status');
      const slot = purposeToSlot(purpose);
      const cred = current?.stayCredentials?.[slot];
      if (cred?.tokenHash === parsed.tokenHash && cred.consumedAt) {
        throw new ApiError(
          'Credential déjà consommé',
          400,
          errorCodes.STAY_CREDENTIAL.CONSUMED
        );
      }
      if (cred?.tokenHash === parsed.tokenHash && isCredentialExpired(cred.expiresAt)) {
        throw new ApiError('Credential expiré', 400, errorCodes.STAY_CREDENTIAL.EXPIRED);
      }
      if (!cred || cred.tokenHash !== parsed.tokenHash) {
        throw new ApiError('Credential invalide', 400, errorCodes.STAY_CREDENTIAL.INVALID);
      }
    }
    throw err;
  }
}

module.exports = {
  PURPOSE,
  issueCredential,
  resolveCredential,
  commitWithCredential,
  isClientOwner,
  isPartnerOwner,
  parseCredential,
};
