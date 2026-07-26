const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');

// Configuration Cloudinary avec les variables d'environnement
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Stockage pour les images de résidences
const residenceStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'chapechape/residences',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [{ quality: 'auto:good' }],
  },
});

// Stockage pour les images de profil
const profileStorage = new CloudinaryStorage({
  cloudinary,
  params: {
    folder: 'chapechape/profiles',
    allowed_formats: ['jpg', 'jpeg', 'png', 'webp'],
    transformation: [{ quality: 'auto:good', width: 500, height: 500, crop: 'fill' }],
  },
});

// Middleware pour uploader les images de résidences
const uploadResidenceImages = multer({ storage: residenceStorage }).array('images');

// Middleware pour uploader l'image de profil
const uploadProfileImage = multer({ storage: profileStorage }).single('image');

// Service pour manipuler les images
const CloudinaryService = {
  // Générer URL optimisée
  getOptimizedUrl(publicId, { width, height, quality = 'auto' } = {}) {
    const options = {
      quality,
      format: 'auto',
    };
    
    if (width) options.width = width;
    if (height) options.height = height;
    
    return cloudinary.url(publicId, options);
  },
  
  // Supprimer une image
  async deleteImage(publicId) {
    try {
      const result = await cloudinary.uploader.destroy(publicId);
      return result;
    } catch (error) {
      console.error('Erreur lors de la suppression de l\'image:', error);
      throw error;
    }
  },

  // Supprimer une vidéo (resource_type: 'video' obligatoire — distinct des images)
  async deleteVideo(publicId) {
    try {
      const result = await cloudinary.uploader.destroy(publicId, {
        resource_type: 'video',
        invalidate: true,
      });
      return result;
    } catch (error) {
      console.error('Erreur lors de la suppression de la vidéo:', error);
      throw error;
    }
  },

  /**
   * Génère une URL thumbnail depuis un publicId vidéo Cloudinary.
   * Utilise la transformation native Cloudinary (pas de requête réseau).
   */
  getVideoThumbnailUrl(publicId, { width = 640, height = 360 } = {}) {
    return cloudinary.url(publicId, {
      resource_type: 'video',
      format: 'jpg',
      transformation: [{ width, height, crop: 'fill', quality: 'auto' }],
    });
  },
  
  // Extraire l'ID public d'une URL
  getPublicIdFromUrl(url) {
    try {
      // Exemple: https://res.cloudinary.com/djeares5m/image/upload/v1612345678/chapechape/residences/abc123.jpg
      // → chapechape/residences/abc123
      const regex = /\/v\d+\/(.+?)\.\w+$/;
      const match = url.match(regex);
      return match ? match[1] : null;
    } catch (error) {
      console.error('Erreur extraction publicId:', error);
      return null;
    }
  }
};

module.exports = {
  cloudinary,
  uploadResidenceImages,
  uploadProfileImage,
  CloudinaryService
};
