/**
 * CRUD vidéos pour une résidence.
 * Toutes les routes nécessitent protect + authorize('partner'|'admin').
 *
 * POST   /:id/videos           — ajouter une vidéo (partner, ownership)
 * DELETE /:id/videos/:videoId  — supprimer une vidéo (partner owner OU admin)
 * PUT    /:id/videos/:videoId/approve  — approuver (admin seulement)
 * PUT    /:id/videos/:videoId/reject   — rejeter   (admin seulement)
 */

const asyncHandler = require('../../middlewares/async');
const ApiError = require('../../utils/apiError');
const Residence = require('../../models/residence.model');
const { CloudinaryService } = require('../../config/cloudinary');
const {
  MAX_VIDEOS_PER_RESIDENCE,
  MAX_VIDEO_DURATION_SECONDS,
  MAX_VIDEO_SIZE_BYTES,
  VIDEO_CLOUDINARY_FOLDER,
  VIDEO_STATUS,
} = require('../../constants/video');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Vérifie qu'un publicId appartient bien au dossier vidéo autorisé. */
function _isValidVideoPublicId(publicId) {
  return (
    typeof publicId === 'string' &&
    publicId.startsWith(VIDEO_CLOUDINARY_FOLDER) &&
    publicId.length > VIDEO_CLOUDINARY_FOLDER.length + 1
  );
}

/** Vérifie qu'une URL est une URL Cloudinary valide pour les vidéos. */
function _isCloudinaryVideoUrl(url) {
  try {
    const parsed = new URL(url);
    return (
      parsed.hostname === 'res.cloudinary.com' &&
      parsed.pathname.includes('/video/upload/')
    );
  } catch {
    return false;
  }
}

// ---------------------------------------------------------------------------
// POST /:id/videos — Ajouter une vidéo
// ---------------------------------------------------------------------------

exports.addVideo = asyncHandler(async (req, res) => {
  const residence = await Residence.findById(req.params.id);

  if (!residence || residence.deleted) {
    throw new ApiError('Résidence introuvable', 404);
  }

  // Ownership : seul le partner propriétaire ou un admin peut uploader
  const userId = String(req.user._id || req.user.id);
  const isAdmin = req.user.role === 'admin';
  const isOwner = String(residence.partner) === userId;

  if (!isAdmin && !isOwner) {
    throw new ApiError('Non autorisé — vous n\'êtes pas le propriétaire de cette résidence', 403);
  }

  // Quota : MVP = 1 vidéo max
  if (residence.videos.length >= MAX_VIDEOS_PER_RESIDENCE) {
    throw new ApiError(
      `Quota atteint : ${MAX_VIDEOS_PER_RESIDENCE} vidéo(s) maximum par résidence. Supprimez l'existante avant d'en ajouter une nouvelle.`,
      409
    );
  }

  const { url, publicId, duration, size } = req.body;

  if (!url || !publicId) {
    throw new ApiError('url et publicId sont requis', 400);
  }

  if (!_isCloudinaryVideoUrl(url)) {
    throw new ApiError('url doit être une URL Cloudinary valide (res.cloudinary.com/…/video/upload/…)', 400);
  }

  if (!_isValidVideoPublicId(publicId)) {
    throw new ApiError(
      `publicId invalide — doit commencer par "${VIDEO_CLOUDINARY_FOLDER}/"`,
      400
    );
  }

  if (duration && Number(duration) > MAX_VIDEO_DURATION_SECONDS) {
    throw new ApiError(
      `Durée vidéo trop longue (max ${MAX_VIDEO_DURATION_SECONDS}s)`,
      400
    );
  }

  if (size && Number(size) > MAX_VIDEO_SIZE_BYTES) {
    throw new ApiError(
      `Vidéo trop volumineuse (max ${Math.round(MAX_VIDEO_SIZE_BYTES / 1024 / 1024)} Mo)`,
      400
    );
  }

  // Générer thumbnail Cloudinary sans requête réseau (transformation URL)
  const thumbnail = CloudinaryService.getVideoThumbnailUrl(publicId);

  residence.videos.push({
    url,
    publicId,
    thumbnail,
    duration: duration ? Number(duration) : undefined,
    size:     size     ? Number(size)     : undefined,
    status:   VIDEO_STATUS.PENDING,
    order:    0,
    uploadedAt: new Date(),
  });

  _sanitizeResidenceStatus(residence);
  await residence.save();

  const addedVideo = residence.videos[residence.videos.length - 1];

  res.status(201).json({
    success: true,
    message: 'Vidéo ajoutée avec succès — en attente de modération',
    data: addedVideo,
  });
});

// ---------------------------------------------------------------------------
// DELETE /:id/videos/:videoId — Supprimer une vidéo
// ---------------------------------------------------------------------------

exports.deleteVideo = asyncHandler(async (req, res) => {
  const residence = await Residence.findById(req.params.id);

  if (!residence || residence.deleted) {
    throw new ApiError('Résidence introuvable', 404);
  }

  const userId = String(req.user._id || req.user.id);
  const isAdmin = ['admin', 'superadmin'].includes(req.user.role);
  const isOwner = String(residence.partner) === userId;

  if (!isAdmin && !isOwner) {
    throw new ApiError('Non autorisé', 403);
  }

  const video = residence.videos.id(req.params.videoId);
  if (!video) {
    throw new ApiError('Vidéo introuvable', 404);
  }

  const publicId = video.publicId;

  // Supprimer le subdoc Mongoose
  video.deleteOne();
  _sanitizeResidenceStatus(residence);
  await residence.save();

  // Supprimer sur Cloudinary (best-effort — ne bloque pas la réponse)
  if (publicId) {
    CloudinaryService.deleteVideo(publicId).catch((err) => {
      console.error(`[Video] Échec suppression Cloudinary ${publicId}:`, err.message);
    });
  }

  res.status(200).json({
    success: true,
    message: 'Vidéo supprimée avec succès',
  });
});

/** Répare un status corrompu (ex. ancien "verified" / "rejected") avant save. */
function _sanitizeResidenceStatus(residence) {
  const allowed = ['available', 'unavailable', 'maintenance'];
  if (!allowed.includes(residence.status)) {
    residence.status = 'available';
  }
}

// ---------------------------------------------------------------------------
// PUT /:id/videos/:videoId/approve — Approuver (admin seulement)
// ---------------------------------------------------------------------------

exports.approveVideo = asyncHandler(async (req, res) => {
  if (!['admin', 'superadmin'].includes(req.user.role)) {
    throw new ApiError('Réservé aux administrateurs', 403);
  }

  const residence = await Residence.findById(req.params.id);
  if (!residence || residence.deleted) {
    throw new ApiError('Résidence introuvable', 404);
  }

  const video = residence.videos.id(req.params.videoId);
  if (!video) {
    throw new ApiError('Vidéo introuvable', 404);
  }

  _sanitizeResidenceStatus(residence);
  video.status = VIDEO_STATUS.APPROVED;
  video.rejectionReason = undefined;
  await residence.save();

  res.status(200).json({
    success: true,
    message: 'Vidéo approuvée',
    data: video,
  });
});

// ---------------------------------------------------------------------------
// PUT /:id/videos/:videoId/reject — Rejeter (admin seulement)
// ---------------------------------------------------------------------------

exports.rejectVideo = asyncHandler(async (req, res) => {
  if (!['admin', 'superadmin'].includes(req.user.role)) {
    throw new ApiError('Réservé aux administrateurs', 403);
  }

  const residence = await Residence.findById(req.params.id);
  if (!residence || residence.deleted) {
    throw new ApiError('Résidence introuvable', 404);
  }

  const video = residence.videos.id(req.params.videoId);
  if (!video) {
    throw new ApiError('Vidéo introuvable', 404);
  }

  const { reason } = req.body;
  _sanitizeResidenceStatus(residence);
  video.status = VIDEO_STATUS.REJECTED;
  video.rejectionReason = reason || 'Non conforme aux règles de la plateforme';
  await residence.save();

  res.status(200).json({
    success: true,
    message: 'Vidéo rejetée',
    data: video,
  });
});
