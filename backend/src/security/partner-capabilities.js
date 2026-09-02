/**
 * P2-02 — rôle Partner ≠ état de vérification.
 *
 * Inscription : role=partner immédiatement, accès produit immédiat.
 * partner_pending : alias legacy (comptes anciens), même accès produit.
 * isVerified (booléen unique) n’est PAS une gate.
 *
 * Les opérations sensibles lisent des capabilities calculées.
 */

const { ROLES, isStaff, isPartnerAccount } = require('./roles');

const PHONE = { PENDING: 'pending', VERIFIED: 'verified' };
const IDENTITY = {
  NOT_REQUESTED: 'not_requested',
  PENDING: 'pending',
  VERIFIED: 'verified',
  REJECTED: 'rejected',
};
const PAYOUT = {
  NOT_CONFIGURED: 'not_configured',
  PENDING: 'pending',
  VERIFIED: 'verified',
};
const PROPERTY = {
  NOT_REQUIRED: 'not_required',
  REQUESTED: 'requested',
  VERIFIED: 'verified',
};

function resolveVerification(user = {}) {
  const overlay = user.verification && typeof user.verification === 'object'
    ? user.verification
    : {};
  return {
    phone: overlay.phone
      || (user.isPhoneVerified ? PHONE.VERIFIED : PHONE.PENDING),
    email: overlay.email || 'pending',
    identity: overlay.identity || IDENTITY.NOT_REQUESTED,
    payout: overlay.payout || PAYOUT.NOT_CONFIGURED,
    property: overlay.property || PROPERTY.NOT_REQUIRED,
  };
}

/**
 * Droits Partner. Staff : tout true (ops). Client : tout false.
 */
function getCapabilities(user = {}) {
  return computeCapabilities(user);
}

function computeCapabilities(user = {}) {
  const role = user.role;
  if (isStaff(role)) {
    return staffCapabilities();
  }
  if (!isPartnerAccount(role)) {
    return clientCapabilities();
  }

  const v = resolveVerification(user);
  const phoneOk = v.phone === PHONE.VERIFIED;
  const identityBlocked = v.identity === IDENTITY.REJECTED;
  const kycHold = v.identity === IDENTITY.PENDING || v.payout === PAYOUT.PENDING;
  const legacyPayoutEligibility = isLegacyPayoutEligible(v);

  return {
    canAccessPartnerApp: true,
    canEditProfile: true,
    canCreateResidence: !identityBlocked,
    canEditResidence: !identityBlocked,
    canManageResidence: !identityBlocked,
    canManageCalendar: !identityBlocked,
    canCreateBlocks: !identityBlocked,
    canCreateExternalBooking: !identityBlocked,
    canPublishResidence: phoneOk && !identityBlocked,
    canReceiveBookings: phoneOk && !identityBlocked,
    canReceivePayout: phoneOk && !identityBlocked && !kycHold
      && (v.payout === PAYOUT.VERIFIED || legacyPayoutEligibility),
  };
}

/**
 * Compatibilité : payout not_configured n’est PAS « verified ».
 * Exception explicite pour les Partners déjà en prod avant KYC payout.
 */
function isLegacyPayoutEligible(verification = {}) {
  return verification.payout === PAYOUT.NOT_CONFIGURED;
}

function canPublishResidence(user) {
  return computeCapabilities(user).canPublishResidence === true;
}

function canReceiveBookings(user) {
  return computeCapabilities(user).canReceiveBookings === true;
}

function canReceivePayout(user) {
  return computeCapabilities(user).canReceivePayout === true;
}

function canManageResidence(user) {
  return computeCapabilities(user).canManageResidence === true
    || computeCapabilities(user).canEditResidence === true;
}

function canManageCalendar(user) {
  return computeCapabilities(user).canManageCalendar === true;
}

function staffCapabilities() {
  return {
    canAccessPartnerApp: true,
    canEditProfile: true,
    canCreateResidence: true,
    canEditResidence: true,
    canManageResidence: true,
    canManageCalendar: true,
    canCreateBlocks: true,
    canCreateExternalBooking: true,
    canPublishResidence: true,
    canReceiveBookings: true,
    canReceivePayout: true,
  };
}

function clientCapabilities() {
  return {
    canAccessPartnerApp: false,
    canEditProfile: true,
    canCreateResidence: false,
    canEditResidence: false,
    canManageResidence: false,
    canManageCalendar: false,
    canCreateBlocks: false,
    canCreateExternalBooking: false,
    canPublishResidence: false,
    canReceiveBookings: false,
    canReceivePayout: false,
  };
}

function publicAuthView(user) {
  if (!user) return null;
  return {
    verification: resolveVerification(user),
    capabilities: computeCapabilities(user),
  };
}

function requireCapability(name) {
  const ApiError = require('../utils/apiError');
  const errorCodes = require('../utils/errorCodes');
  return (req, res, next) => {
    if (!req.user) {
      return next(new ApiError('Authentification requise', 401, errorCodes.GENERAL.UNAUTHORIZED));
    }
    if (isStaff(req.user.role)) {
      return next();
    }
    const caps = computeCapabilities(req.user);
    if (!caps[name]) {
      return next(new ApiError(
        'Vérification supplémentaire requise pour cette opération',
        403,
        errorCodes.CAPABILITY.REQUIRED,
        [],
        {
          capability: name,
          requiredCapability: name,
          verification: name === 'canPublishResidence' || name === 'canReceiveBookings'
            ? 'phone'
            : name === 'canReceivePayout' ? 'payout' : 'phone',
          requiredVerification: name === 'canReceivePayout' ? 'payout' : 'phone',
        }
      ));
    }
    next();
  };
}

module.exports = {
  ROLES,
  PHONE,
  IDENTITY,
  PAYOUT,
  PROPERTY,
  resolveVerification,
  computeCapabilities,
  getCapabilities,
  publicAuthView,
  requireCapability,
  isLegacyPayoutEligible,
  canPublishResidence,
  canReceiveBookings,
  canReceivePayout,
  canManageResidence,
  canManageCalendar,
};
