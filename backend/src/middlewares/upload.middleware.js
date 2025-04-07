const multer = require('multer');
const path = require('path');
const ApiError = require('../utils/apiError');
const fs = require('fs');

// Création du dossier uploads s'il n'existe pas
const createUploadDirs = () => {
    const dirs = ['uploads', 'uploads/residences', 'uploads/profiles', 'uploads/documents'];
    
    dirs.forEach(dir => {
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
            console.log(`Dossier ${dir} créé avec succès`);
        }
    });
};

// Créer les dossiers nécessaires
createUploadDirs();

// Configuration du stockage pour les résidences
const residenceStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/residences');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// Configuration du stockage pour les profils
const profileStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/profiles');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'profile-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// Configuration du stockage pour les documents
const documentStorage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/documents');
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'document-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// Filtre pour les types de fichiers
const fileFilter = (req, file, cb) => {
    if (file.mimetype.startsWith('image')) {
        cb(null, true);
    } else {
        cb(new ApiError('Seules les images sont autorisées!', 400), false);
    }
};

// Filtre pour les documents
const documentFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'];
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new ApiError('Type de fichier non autorisé. Seuls JPEG, PNG, GIF et PDF sont acceptés.', 400), false);
    }
};

// Middleware pour les uploads de résidences
const residenceUpload = multer({
    storage: residenceStorage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB max
    }
});

// Middleware pour les uploads de profils
const profileUpload = multer({
    storage: profileStorage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 2 * 1024 * 1024 // 2MB max
    }
});

// Middleware pour les uploads de documents
const documentUpload = multer({
    storage: documentStorage,
    fileFilter: documentFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB max
    }
});

module.exports = {
    residence: residenceUpload,
    profile: profileUpload,
    document: documentUpload
};
