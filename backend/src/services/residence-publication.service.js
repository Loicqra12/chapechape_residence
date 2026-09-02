/**
 * Publication Residence — distincte de status (available/unavailable)
 * et de verified (cachet admin historique).
 *
 * Legacy : pas de publicationStatus → déjà au catalogue (comportement actuel).
 * Création nouvelle → draft (invisible). Publication = pending_review.
 */

const Residence = require('../models/residence.model');
const ApiError = require('../utils/apiError');
const errorCodes = require('../utils/errorCodes');
const { isStaff, isPartnerAccount } = require('../security/roles');
const {
  canPublishResidence,
} = require('../security/partner-capabilities');

const PUBLICATION = Object.freeze({
  DRAFT: 'draft',
  PENDING_REVIEW: 'pending_review',
  PUBLISHED: 'published',
  REJECTED: 'rejected',
});

function isPubliclyListed(residence) {
  if (!residence || residence.deleted) return false;
  if (residence.publicationStatus == null || residence.publicationStatus === '') {
    return true;
  }
  return residence.publicationStatus === PUBLICATION.PUBLISHED;
}

function publicCatalogFilter() {
  return {
    deleted: { $ne: true },
    $or: [
      { publicationStatus: PUBLICATION.PUBLISHED },
      { publicationStatus: { $exists: false } },
    ],
  };
}

function applyPublicCatalogFilter(filter = {}) {
  const listing = {
    $or: [
      { publicationStatus: PUBLICATION.PUBLISHED },
      { publicationStatus: { $exists: false } },
    ],
  };
  const base = {
    ...filter,
    deleted: filter.deleted !== undefined ? filter.deleted : { $ne: true },
  };
  if (base.$or) {
    const { $or, ...rest } = base;
    return { ...rest, $and: [{ $or }, listing] };
  }
  return { ...base, ...listing };
}

function canViewUnlistedResidence(residence, user) {
  if (!user) return false;
  if (isStaff(user.role)) return true;
  const partnerId = residence.partner && (residence.partner._id || residence.partner);
  return String(partnerId) === String(user._id || user.id);
}

function stripPublicationFields(payload = {}) {
  const next = { ...payload };
  delete next.publicationStatus;
  delete next.verified;
  delete next.verifiedAt;
  delete next.verifiedBy;
  delete next.publicationRequestedAt;
  return next;
}

async function requestPublication({ residenceId, user }) {
  if (!user) {
    throw new ApiError('Authentification requise', 401, errorCodes.GENERAL.UNAUTHORIZED);
  }
  if (!isPartnerAccount(user.role) && !isStaff(user.role)) {
    throw new ApiError(
      'Seuls les partenaires peuvent demander la publication',
      403,
      errorCodes.GENERAL.FORBIDDEN
    );
  }

  const residence = await Residence.findById(residenceId);
  if (!residence || residence.deleted) {
    throw new ApiError('Résidence non trouvée', 404, errorCodes.RESIDENCE.NOT_FOUND);
  }

  const ownerId = String(residence.partner);
  const isOwner = ownerId === String(user._id || user.id);
  if (!isStaff(user.role) && !isOwner) {
    throw new ApiError(
      'Non autorisé à publier cette résidence',
      403,
      errorCodes.RESIDENCE.UNAUTHORIZED_ACCESS
    );
  }

  if (!canPublishResidence(user)) {
    throw new ApiError(
      'Vérifiez votre numéro de téléphone pour publier cette résidence',
      403,
      errorCodes.CAPABILITY.REQUIRED,
      [],
      {
        capability: 'canPublishResidence',
        requiredCapability: 'canPublishResidence',
        verification: 'phone',
        requiredVerification: 'phone',
      }
    );
  }

  if (residence.publicationStatus === PUBLICATION.PUBLISHED) {
    return { residence, alreadyPublished: true };
  }
  if (residence.publicationStatus === PUBLICATION.PENDING_REVIEW) {
    return { residence, alreadyPending: true };
  }

  residence.publicationStatus = PUBLICATION.PENDING_REVIEW;
  residence.publicationRequestedAt = new Date();
  await residence.save();
  return { residence, alreadyPublished: false, alreadyPending: false };
}

async function markPublished(residence, adminUser) {
  residence.publicationStatus = PUBLICATION.PUBLISHED;
  residence.verified = true;
  residence.verifiedAt = new Date();
  if (adminUser) {
    residence.verifiedBy = adminUser._id || adminUser.id;
  }
  await residence.save();
  return residence;
}

module.exports = {
  PUBLICATION,
  isPubliclyListed,
  publicCatalogFilter,
  applyPublicCatalogFilter,
  canViewUnlistedResidence,
  stripPublicationFields,
  requestPublication,
  markPublished,
};
