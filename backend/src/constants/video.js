/**
 * Constantes centralisées pour la gestion des vidéos de résidences.
 * Modifier ici suffit : toute la chaîne (controller, validation, cloudinary) les utilise.
 */

module.exports = {
  /** Nombre maximum de vidéos par résidence (MVP : 1) */
  MAX_VIDEOS_PER_RESIDENCE: 1,

  /** Durée maximale d'une vidéo en secondes */
  MAX_VIDEO_DURATION_SECONDS: 90,

  /** Taille maximale brute acceptée par le contrôleur (en octets) — 200 Mo */
  MAX_VIDEO_SIZE_BYTES: 200 * 1024 * 1024,

  /** Dossier Cloudinary pour les vidéos résidences */
  VIDEO_CLOUDINARY_FOLDER: 'chapechape/residences/videos',

  /** Formats vidéo acceptés */
  ALLOWED_VIDEO_FORMATS: ['mp4', 'mov', 'avi', 'webm'],

  /** Nombre maximum de signatures vidéo par heure par partenaire */
  VIDEO_SIGNATURE_RATE_LIMIT: 3,

  /** Statuts possibles d'une vidéo dans le sous-document */
  VIDEO_STATUS: {
    PENDING: 'pending_review',
    APPROVED: 'approved',
    REJECTED: 'rejected',
  },

  /**
   * Feature flag : passer à true en production pour activer la section vidéo
   * dans les apps et le site vitrine.
   * Contrôle uniquement l'affichage — l'upload partner reste disponible.
   */
  FEATURE_VIDEO_ENABLED: process.env.FEATURE_VIDEO_ENABLED === 'true',
};
