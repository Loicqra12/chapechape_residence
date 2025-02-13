const multer = require('multer');
const sharp = require('sharp');
const path = require('path');
const fs = require('fs').promises;
const ApiError = require('../utils/apiError');

class UploadService {
    constructor() {
        this.storage = multer.memoryStorage();
        this.upload = multer({
            storage: this.storage,
            fileFilter: this._fileFilter,
            limits: {
                fileSize: 5 * 1024 * 1024 // 5MB max
            }
        });
    }

    // Filtre pour les types de fichiers
    _fileFilter(req, file, cb) {
        if (file.mimetype.startsWith('image')) {
            cb(null, true);
        } else {
            cb(new ApiError('Le fichier doit être une image', 400), false);
        }
    }

    // Redimensionner et optimiser l'image
    async resizeImage(file, width = 800) {
        const filename = `image-${Date.now()}.jpeg`;
        const filepath = path.join('public', 'uploads', filename);

        await sharp(file.buffer)
            .resize(width, null, {
                fit: 'contain',
                withoutEnlargement: true
            })
            .toFormat('jpeg')
            .jpeg({ quality: 90 })
            .toFile(filepath);

        return filename;
    }

    // Supprimer une image
    async deleteImage(filename) {
        const filepath = path.join('public', 'uploads', filename);
        await fs.unlink(filepath);
    }

    // Uploader plusieurs images
    async uploadMultipleImages(files, width = 800) {
        const filenames = [];

        for (const file of files) {
            const filename = await this.resizeImage(file, width);
            filenames.push(filename);
        }

        return filenames;
    }

    // Middleware pour l'upload d'une seule image
    uploadSingle(fieldName) {
        return this.upload.single(fieldName);
    }

    // Middleware pour l'upload de plusieurs images
    uploadMultiple(fieldName, maxCount = 5) {
        return this.upload.array(fieldName, maxCount);
    }

    // Créer les dossiers nécessaires
    async createUploadDirectories() {
        const uploadDir = path.join('public', 'uploads');
        try {
            await fs.access(uploadDir);
        } catch {
            await fs.mkdir(uploadDir, { recursive: true });
        }
    }

    // Générer l'URL complète d'une image
    getImageUrl(filename) {
        if (!filename) return null;
        return `${process.env.BASE_URL}/uploads/${filename}`;
    }
}

module.exports = new UploadService();
