const multer = require('multer');
const path = require('path');
const ApiError = require('../utils/apiError');
const fs = require('fs');
const logger = require('../utils/logger');

// Création du dossier uploads s'il n'existe pas
const createUploadDirs = () => {
    const dirs = ['uploads', 'uploads/residences', 'uploads/profiles', 'uploads/documents', 'uploads/quarantine'];
    
    dirs.forEach(dir => {
        if (!fs.existsSync(dir)) {
            fs.mkdirSync(dir, { recursive: true });
            logger.info(`Dossier ${dir} créé avec succès`);
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

// Filtre pour les types de fichiers avec validation renforcée
const fileFilter = (req, file, cb) => {
    // Liste des extensions d'images autorisées
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    // Vérification de l'extension
    const ext = path.extname(file.originalname).toLowerCase();
    
    if (!file.mimetype.startsWith('image') || !allowedExtensions.includes(ext)) {
        logger.warn(`Type de fichier non autorisé: ${file.originalname} (${file.mimetype})`);
        return cb(new ApiError('Seules les images aux formats JPG, JPEG, PNG, GIF et WEBP sont autorisées!', 400), false);
    }

    // Vérification supplémentaire du magic number (à implémenter plus tard)
    // TODO: Vérifier les premiers octets du fichier pour confirmer qu'il s'agit bien d'une image
    
    cb(null, true);
};

// Filtre pour les documents avec validation renforcée
const documentFilter = (req, file, cb) => {
    // Types MIME et extensions autorisés pour les documents
    const allowedTypes = {
        'image/jpeg': ['.jpg', '.jpeg'],
        'image/png': ['.png'],
        'image/gif': ['.gif'],
        'application/pdf': ['.pdf']
    };
    
    const ext = path.extname(file.originalname).toLowerCase();
    
    // Vérifier à la fois le type MIME et l'extension correspondante
    if (!allowedTypes[file.mimetype] || !allowedTypes[file.mimetype].includes(ext)) {
        logger.warn(`Type de document non autorisé: ${file.originalname} (${file.mimetype})`);
        return cb(new ApiError('Type de fichier non autorisé. Seuls JPEG, PNG, GIF et PDF sont acceptés.', 400), false);
    }
    
    // Vérification du nom de fichier pour éviter les injections
    const sanitizedFilename = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    if (sanitizedFilename !== file.originalname) {
        logger.warn(`Nom de fichier potentiellement dangereux sanitisé: ${file.originalname} -> ${sanitizedFilename}`);
        file.originalname = sanitizedFilename;
    }
    
    cb(null, true);
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

// Import du scanner antivirus
const virusScan = require('./virus-scan.middleware');

// Version standard sans scan antivirus (pour compatibilité)
const standardUploads = {
    residence: residenceUpload,
    profile: profileUpload,
    document: documentUpload
};

// Version sécurisée avec scan antivirus
const secureUploads = {
    /**
     * Upload sécurisé pour les images de résidences avec scan antivirus
     * @param {string} fieldname - Nom du champ de formulaire
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    residence: (fieldname) => [
        residenceUpload.single(fieldname),
        virusScan.scanSingleFile
    ],

    /**
     * Upload sécurisé pour les images de résidences (multiple) avec scan antivirus
     * @param {string} fieldname - Nom du champ de formulaire
     * @param {number} maxCount - Nombre maximum de fichiers à uploader
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    residenceMultiple: (fieldname, maxCount = 10) => [
        residenceUpload.array(fieldname, maxCount),
        virusScan.scanMultipleFiles
    ],

    /**
     * Upload sécurisé pour les images de profil avec scan antivirus
     * @param {string} fieldname - Nom du champ de formulaire
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    profile: (fieldname) => [
        profileUpload.single(fieldname),
        virusScan.scanSingleFile
    ],

    /**
     * Upload sécurisé pour les documents avec scan antivirus
     * @param {string} fieldname - Nom du champ de formulaire
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    document: (fieldname) => [
        documentUpload.single(fieldname),
        virusScan.scanSingleFile
    ],

    /**
     * Upload sécurisé pour plusieurs documents avec scan antivirus
     * @param {string} fieldname - Nom du champ de formulaire
     * @param {number} maxCount - Nombre maximum de fichiers à uploader
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    documentMultiple: (fieldname, maxCount = 5) => [
        documentUpload.array(fieldname, maxCount),
        virusScan.scanMultipleFiles
    ]
};

/**
 * Middleware pour vérifier si un fichier est sûr avant de le servir
 * @param {Request} req - Requête Express
 * @param {Response} res - Réponse Express
 * @param {NextFunction} next - Fonction suivante
 */
const verifyFileSecurity = (req, res, next) => {
    const filePath = req.params.path;
    
    // Vérifier que le chemin est sécurisé (pas de directory traversal)
    if (filePath.includes('../') || filePath.includes('..\\')) {
        logger.warn(`Tentative de directory traversal détectée: ${filePath}`);
        return res.status(403).json({
            success: false,
            message: 'Accès non autorisé'
        });
    }

    // Continuer vers le middleware suivant
    next();
};

// Export des différentes versions du middleware
module.exports = {
    // Export de la version standard (compatibilité)
    ...standardUploads,
    
    // Export de la version sécurisée
    secure: secureUploads,
    
    // Middleware de vérification de sécurité pour les fichiers servis
    verifyFileSecurity
};
