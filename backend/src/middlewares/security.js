const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const xss = require('xss-clean');
const mongoSanitize = require('express-mongo-sanitize');
const hpp = require('hpp');
const cors = require('cors');
const path = require('path');
const logger = require('../utils/logger');

// Configuration du rate limiting (plus permissif)
const rateLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 500, // Augmenté à 500 requêtes par IP par fenêtre (au lieu de 100)
    message: 'Trop de requêtes depuis cette IP, veuillez réessayer plus tard',
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => {
        // Skip rate limiting pour les health checks et pings
        return req.path.startsWith('/api/health') || req.path.startsWith('/api/ping');
    },
    handler: (req, res) => {
        logger.warn(`Rate limit exceeded for IP: ${req.ip}`);
        res.status(429).json({
            success: false,
            message: 'Trop de requêtes depuis cette IP, veuillez réessayer plus tard'
        });
    }
});

// Définir le nom du middleware pour les tests
Object.defineProperty(rateLimiter, 'name', {
    value: 'rateLimit',
    writable: false
});

// Configuration de CORS
const corsOptions = {
    origin: process.env.FRONTEND_URL || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    exposedHeaders: ['Content-Range', 'X-Content-Range'],
    credentials: true,
    maxAge: 3600
};

// Configuration de Helmet
const helmetConfig = {
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'", "'unsafe-inline'", "'unsafe-eval'"],
            imgSrc: ["'self'", 'data:', 'https:'],
            connectSrc: ["'self'", 'https://api.stripe.com']
        }
    },
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: { policy: "cross-origin" }
};

// Middleware pour les en-têtes de sécurité personnalisés
const securityHeaders = (req, res, next) => {
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'SAMEORIGIN');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
    next();
};
securityHeaders.name = 'securityHeaders';

// Middleware pour la validation des entrées
const inputValidation = (req, res, next) => {
    // Validation des paramètres de requête
    if (req.query) {
        Object.keys(req.query).forEach(key => {
            if (typeof req.query[key] === 'string') {
                req.query[key] = req.query[key].trim();
            }
        });
    }

    // Validation du corps de la requête
    if (req.body) {
        Object.keys(req.body).forEach(key => {
            if (typeof req.body[key] === 'string') {
                req.body[key] = req.body[key].trim();
            }
        });
    }

    next();
};
inputValidation.name = 'inputValidation';

// Configuration de la sécurité des fichiers uploadés
const fileSecurityConfig = {
    allowedExtensions: ['.jpg', '.jpeg', '.png', '.pdf', '.doc', '.docx'],
    maxFileSize: 5 * 1024 * 1024, // 5MB
};

// Middleware pour la sécurité des fichiers
const fileSecurityMiddleware = (req, res, next) => {
    if (!req.files) return next();

    const files = Array.isArray(req.files) ? req.files : [req.files];
    
    for (const file of files) {
        const ext = path.extname(file.originalname).toLowerCase();
        
        // Vérifier l'extension
        if (!fileSecurityConfig.allowedExtensions.includes(ext)) {
            return res.status(400).json({
                success: false,
                message: `Extension de fichier non autorisée: ${ext}`
            });
        }

        // Vérifier la taille
        if (file.size > fileSecurityConfig.maxFileSize) {
            return res.status(400).json({
                success: false,
                message: 'Fichier trop volumineux'
            });
        }
    }

    next();
};

// Export des middlewares
const securityMiddleware = [
    helmet(helmetConfig),
    cors(corsOptions),
    xss(),
    mongoSanitize(),
    hpp(),
    rateLimiter,
    securityHeaders,
    inputValidation
];

module.exports = {
    securityMiddleware,
    fileSecurityMiddleware
};
