const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const hpp = require('hpp');

// Middleware de sécurité général
exports.securityMiddleware = [
    // Sanitization des données MongoDB
    mongoSanitize(),
    
    // Protection XSS
    xss(),
    
    // Prévention de la pollution des paramètres HTTP
    hpp()
];

// Middleware de sécurité pour les fichiers
exports.fileSecurityMiddleware = (req, res, next) => {
    // Liste des types MIME autorisés
    const allowedMimes = [
        'image/jpeg',
        'image/png',
        'image/gif',
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ];

    // Vérification du type de fichier
    if (req.files) {
        const files = Array.isArray(req.files) ? req.files : [req.files];
        
        for (const file of files) {
            if (!allowedMimes.includes(file.mimetype)) {
                return res.status(415).json({
                    success: false,
                    message: `Type de fichier non autorisé: ${file.mimetype}`
                });
            }

            // Limite de taille (5MB)
            if (file.size > 5 * 1024 * 1024) {
                return res.status(413).json({
                    success: false,
                    message: `Fichier trop volumineux: ${file.originalname}`
                });
            }
        }
    }

    next();
};
