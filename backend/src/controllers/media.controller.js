const asyncHandler = require('../middlewares/async');
const ApiError = require('../utils/apiError');
const { cloudinary } = require('../config/cloudinary');
const { VIDEO_CLOUDINARY_FOLDER } = require('../constants/video');
const { isStaff, isPartnerAccount } = require('../security/roles');

function assertCloudinaryFolderAccess(req, folder) {
  const normalized = String(folder || '').replace(/\/+$/, '');
  const uid = String(req.user.id || req.user._id);

  if (normalized === 'chapechape/profiles' || normalized.startsWith('chapechape/profiles/')) {
    if (normalized.startsWith('chapechape/profiles/')) {
      const allowed = `chapechape/profiles/${uid}`;
      if (normalized !== allowed && !normalized.startsWith(`${allowed}/`) && !isStaff(req.user.role)) {
        throw new ApiError('Dossier profil Cloudinary non autorisé', 403);
      }
    }
    return;
  }

  if (normalized === 'chapechape/documents' || normalized.startsWith('chapechape/documents/')) {
    if (!isPartnerAccount(req.user.role) && !isStaff(req.user.role)) {
      throw new ApiError('Dossier documents réservé aux partenaires', 403);
    }
    if (normalized.startsWith('chapechape/documents/')) {
      const allowed = `chapechape/documents/${uid}`;
      if (normalized !== allowed && !normalized.startsWith(`${allowed}/`) && !isStaff(req.user.role)) {
        throw new ApiError('Dossier documents Cloudinary non autorisé', 403);
      }
    }
    return;
  }

  if (normalized === 'chapechape/messages' || normalized.startsWith('chapechape/messages/')) {
    if (normalized.startsWith('chapechape/messages/')) {
      const allowed = `chapechape/messages/${uid}`;
      if (normalized !== allowed && !normalized.startsWith(`${allowed}/`) && !isStaff(req.user.role)) {
        throw new ApiError('Dossier messages Cloudinary non autorisé', 403);
      }
    }
    return;
  }

  if (normalized === 'chapechape/residences' || normalized.startsWith('chapechape/residences/')) {
    if (!isPartnerAccount(req.user.role) && !isStaff(req.user.role)) {
      throw new ApiError('Upload résidence réservé aux partenaires', 403);
    }
  }
}

/** Préfixes dossiers images autorisés (sous-dossiers OK, ex. chapechape/residences/:id) */
const ALLOWED_IMAGE_FOLDER_PREFIXES = [
  'chapechape/residences',
  'chapechape/profiles',
  'chapechape/documents',
  'chapechape/messages',
];

/** Préfixes dossiers vidéo autorisés */
const ALLOWED_VIDEO_FOLDER_PREFIXES = [
  VIDEO_CLOUDINARY_FOLDER,
];

/**
 * Accepte le dossier exact ou un sous-dossier sûr (pas de `..`).
 */
function isAllowedCloudinaryFolder(folder, prefixes) {
  if (!folder || folder.includes('..') || folder.includes('\\')) {
    return false;
  }
  const normalized = folder.replace(/\/+$/, '');
  return prefixes.some(
    (prefix) => normalized === prefix || normalized.startsWith(`${prefix}/`)
  );
}

/**
 * Signature Cloudinary signée côté serveur (api_secret jamais exposé).
 * Supporte resource_type=image (défaut) et resource_type=video.
 * @route GET /api/media/cloudinary-signature
 */
exports.getCloudinarySignature = asyncHandler(async (req, res) => {
  const folder = String(req.query.folder || 'chapechape/residences').trim();
  const resourceType = String(req.query.resource_type || 'image').trim();

  if (!['image', 'video'].includes(resourceType)) {
    throw new ApiError('resource_type doit être "image" ou "video"', 400);
  }

  if (resourceType === 'video') {
    if (!isAllowedCloudinaryFolder(folder, ALLOWED_VIDEO_FOLDER_PREFIXES)) {
      throw new ApiError('Dossier vidéo Cloudinary non autorisé', 400);
    }
  } else if (!isAllowedCloudinaryFolder(folder, ALLOWED_IMAGE_FOLDER_PREFIXES)) {
    throw new ApiError('Dossier Cloudinary non autorisé', 400);
  }

  assertCloudinaryFolderAccess(req, folder);

  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;

  if (!cloudName || !apiKey || !apiSecret) {
    throw new ApiError('Cloudinary non configuré sur le serveur', 503);
  }

  const timestamp = Math.round(Date.now() / 1000);
  // Cloudinary exclut resource_type de la signature (il est dans l'URL /video|image/upload).
  const paramsToSign = { timestamp, folder };

  const signature = cloudinary.utils.api_sign_request(paramsToSign, apiSecret);

  res.status(200).json({
    success: true,
    data: {
      cloudName,
      apiKey,
      timestamp,
      signature,
      folder,
      resourceType,
    },
  });
});
