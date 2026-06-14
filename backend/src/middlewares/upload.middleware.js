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

// 🔒 SÉCURITÉ CRITIQUE : Magic numbers pour validation de signatures de fichiers
const MAGIC_NUMBERS = {
    // Images JPEG
    'image/jpeg': [
        [0xFF, 0xD8, 0xFF, 0xE0], // JPEG JFIF
        [0xFF, 0xD8, 0xFF, 0xE1], // JPEG Exif
        [0xFF, 0xD8, 0xFF, 0xE2], // JPEG
        [0xFF, 0xD8, 0xFF, 0xE3], // JPEG
        [0xFF, 0xD8, 0xFF, 0xE8], // JPEG SPIFF
        [0xFF, 0xD8, 0xFF, 0xDB]  // JPEG
    ],
    // Images PNG
    'image/png': [
        [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] // PNG signature
    ],
    // Images GIF
    'image/gif': [
        [0x47, 0x49, 0x46, 0x38, 0x37, 0x61], // GIF87a
        [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]  // GIF89a
    ],
    // Images WebP
    'image/webp': [
        [0x52, 0x49, 0x46, 0x46] // RIFF (les 4 premiers bytes, suivi de WEBP)
    ]
};

/**
 * Vérifie la signature magic number d'un fichier
 * @param {Buffer} buffer - Buffer du fichier
 * @param {string} mimeType - Type MIME déclaré
 * @returns {boolean} - True si la signature correspond au type MIME
 */
function verifyMagicNumber(buffer, mimeType) {
    const signatures = MAGIC_NUMBERS[mimeType];
    if (!signatures) return false;
    
    return signatures.some(signature => {
        if (buffer.length < signature.length) return false;
        
        // Vérification spéciale pour WebP
        if (mimeType === 'image/webp') {
            return buffer[0] === 0x52 && buffer[1] === 0x49 && buffer[2] === 0x46 && buffer[3] === 0x46 &&
                   buffer[8] === 0x57 && buffer[9] === 0x45 && buffer[10] === 0x42 && buffer[11] === 0x50;
        }
        
        // Vérification standard
        return signature.every((byte, index) => buffer[index] === byte);
    });
}

// 🔒 Filtre pour les types de fichiers avec validation ULTRA-RENFORCÉE
const fileFilter = (req, file, cb) => {
    // Liste des extensions et types MIME autorisés (double vérification)
    const allowedTypes = {
        'image/jpeg': ['.jpg', '.jpeg'],
        'image/png': ['.png'],
        'image/gif': ['.gif'],
        'image/webp': ['.webp']
    };
    
    const ext = path.extname(file.originalname).toLowerCase();
    const mimeType = file.mimetype;
    
    // Vérification stricte : type MIME ET extension doivent correspondre
    if (!allowedTypes[mimeType] || !allowedTypes[mimeType].includes(ext)) {
        logger.warn(`🚨 SÉCURITÉ : Type de fichier non autorisé: ${file.originalname} (${mimeType})`);
        return cb(new ApiError('🔒 SÉCURITÉ : Seules les images aux formats JPG, JPEG, PNG, GIF et WEBP sont autorisées!', 400), false);
    }
    
    // Vérification du nom de fichier pour éviter les injections
    const sanitizedFilename = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    if (sanitizedFilename !== file.originalname) {
        logger.warn(`🔒 Nom de fichier potentiellement dangereux sanitisé: ${file.originalname} → ${sanitizedFilename}`);
        file.originalname = sanitizedFilename;
    }
    
    // Stocker les informations pour la vérification magic number ultérieure
    file.expectedMimeType = mimeType;
    
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

/**
 * 🔒 Middleware de post-vérification des magic numbers
 * Vérifie la signature réelle du fichier après upload pour détecter les tentatives de spoofing
 */
const verifyMagicNumbers = (req, res, next) => {
    try {
        const files = req.files || (req.file ? [req.file] : []);
        
        for (const file of files) {
            if (file && file.path && file.expectedMimeType) {
                // Lire les premiers bytes du fichier
                const buffer = fs.readFileSync(file.path);
                const first12Bytes = buffer.slice(0, 12);
                
                // Vérifier la signature magic number
                if (!verifyMagicNumber(first12Bytes, file.expectedMimeType)) {
                    // Supprimer le fichier malveillant
                    fs.unlinkSync(file.path);
                    logger.error(`🚨 SÉCURITÉ CRITIQUE : Tentative d'upload de fichier avec signature falsifiée détectée: ${file.originalname} (MIME: ${file.expectedMimeType})`);
                    
                    return res.status(400).json({
                        success: false,
                        message: '🔒 SÉCURITÉ : Fichier rejeté - signature non conforme au type déclaré',
                        error: 'INVALID_FILE_SIGNATURE'
                    });
                }
                
                logger.info(`✅ Signature magic number validée pour: ${file.originalname} (${file.expectedMimeType})`);
            }
        }
        
        next();
    } catch (error) {
        logger.error('🚨 Erreur lors de la vérification des magic numbers:', error);
        return res.status(500).json({
            success: false,
            message: 'Erreur lors de la validation du fichier'
        });
    }
};

// Version sécurisée avec scan antivirus ET vérification magic numbers
const secureUploads = {
    /**
     * Upload sécurisé pour les images de résidences avec scan antivirus + magic numbers
     * @param {string} fieldname - Nom du champ de formulaire
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    residence: (fieldname) => [
        residenceUpload.single(fieldname),
        verifyMagicNumbers,
        virusScan.scanSingleFile
    ],

    /**
     * Upload sécurisé pour les images de résidences (multiple) avec scan antivirus + magic numbers
     * @param {string} fieldname - Nom du champ de formulaire
     * @param {number} maxCount - Nombre maximum de fichiers à uploader
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    residenceMultiple: (fieldname, maxCount = 10) => [
        residenceUpload.array(fieldname, maxCount),
        verifyMagicNumbers,
        virusScan.scanMultipleFiles
    ],

    /**
     * Upload sécurisé pour les images de profil avec scan antivirus + magic numbers
     * @param {string} fieldname - Nom du champ de formulaire
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    profile: (fieldname) => [
        profileUpload.single(fieldname),
        verifyMagicNumbers,
        virusScan.scanSingleFile
    ],

    /**
     * Upload sécurisé pour les documents avec scan antivirus + magic numbers
     * @param {string} fieldname - Nom du champ de formulaire
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    document: (fieldname) => [
        documentUpload.single(fieldname),
        verifyMagicNumbers,
        virusScan.scanSingleFile
    ],

    /**
     * Upload sécurisé pour plusieurs documents avec scan antivirus + magic numbers
     * @param {string} fieldname - Nom du champ de formulaire
     * @param {number} maxCount - Nombre maximum de fichiers à uploader
     * @returns {Array<Function>} Middlewares pour upload sécurisé
     */
    documentMultiple: (fieldname, maxCount = 5) => [
        documentUpload.array(fieldname, maxCount),
        verifyMagicNumbers,
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
    
    if (!filePath) return next();

    // Résoudre le dossier parent absolu (chemin vers backend/uploads)
    const baseUploadDir = path.resolve(__dirname, '../../uploads');
    const resolvedPath = path.resolve(baseUploadDir, filePath);
    
    // S'assurer que le chemin résolu commence par le chemin de base uploads/
    if (!resolvedPath.startsWith(baseUploadDir)) {
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
