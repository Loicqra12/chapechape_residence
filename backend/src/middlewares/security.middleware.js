const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const hpp = require('hpp');
const cors = require('cors');

// Configuration du rate limiting
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100 // limite chaque IP à 100 requêtes par windowMs
});

// Middleware de sécurité général
exports.securityMiddleware = [
    // Protection des en-têtes HTTP avec configuration XSS
    helmet(),
    
    // Limite de taux pour toutes les routes
    limiter,
    
    // Sanitization des données MongoDB
    mongoSanitize(),
    
    // Protection XSS
    xss(),
    
    // Prévention de la pollution des paramètres HTTP
    hpp(),
    
    // Enable CORS
    cors({
        origin: process.env.FRONTEND_URL || '*',
        methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
        allowedHeaders: ['Content-Type', 'Authorization'],
        credentials: true
    }),
    
    // Headers de sécurité supplémentaires
    helmet.contentSecurityPolicy({
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", 'data:', 'https:'],
            connectSrc: ["'self'", process.env.FRONTEND_URL || '*']
        }
    }),
    
    helmet.referrerPolicy({ policy: 'same-origin' })
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
