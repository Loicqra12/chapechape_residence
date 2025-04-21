/**
 * Version de test du middleware CSRF qui simule le comportement réel
 * pour faciliter les tests automatisés
 */
const ApiError = require('../utils/apiError');
const errorCodes = require('../utils/errorCodes');
const logger = require('../utils/logger');

// Version mock du middleware CSRF qui peut échouer lors des tests
const mockCsrfMiddleware = (req, res, next) => {
    // Bypass pour les méthodes non mutatives (comme le middleware réel)
    if (['GET', 'HEAD', 'OPTIONS'].includes(req.method)) {
        return next();
    }
    
    // Bypass pour les routes mobiles (comme le middleware réel)
    if (req.path.startsWith('/api/mobile/')) {
        return next();
    }
    
    // Pour les tests, on vérifie simplement la présence du header X-CSRF-Token
    const csrfToken = req.get('X-CSRF-Token');
    
    // Si pas de token, ou token invalide, on renvoie une erreur 401
    if (!csrfToken || csrfToken !== 'test-csrf-token') {
        logger.warn(`[MOCK] CSRF Attack Detected: ${req.ip} - ${req.method} ${req.path}`);
        
        // Réponse directe au lieu de passer par next(error) pour éviter les problèmes avec le middleware d'erreur
        return res.status(401).json({
            success: false,
            message: 'Accès invalide: jeton CSRF manquant ou incorrect',
            errorCode: errorCodes.GENERAL.CSRF_ERROR
        });
    }
    
    // Si le token est valide, on continue
    next();
};

// Mock du générateur de token CSRF
const mockGenerateCsrfToken = (req, res, next) => {
    // Générer un token CSRF mock
    const csrfToken = 'test-csrf-token';
    
    // Ajouter le token au locals pour les templates
    res.locals.csrfToken = csrfToken;
    
    // Ajouter le token au header pour les API
    res.setHeader('X-CSRF-Token', csrfToken);
    
    // Ajouter le token au body pour les API (facilite les tests)
    if (req.path === '/api/csrf-token' || req.path === '/get-token') {
        res.json({ csrfToken });
        return;
    }
    
    next();
};

module.exports = {
    csrfMiddleware: mockCsrfMiddleware,
    generateCsrfToken: mockGenerateCsrfToken
};
