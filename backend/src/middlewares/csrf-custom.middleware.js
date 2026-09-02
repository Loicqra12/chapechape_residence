/**
 * Middleware de protection CSRF Custom
 * Remplace le package 'csurf' déprécié
 * Implémente le pattern Double Submit Cookie sécurisé
 */

const crypto = require('crypto');
const apiError = require("../utils/apiError");
const errorCodes = require("../utils/errorCodes");
const logger = require("../utils/logger");

// Configuration
const CSRF_COOKIE_NAME = '_csrf';
const CSRF_HEADER_NAME = 'x-csrf-token';

function hasBearerToken(req) {
  const auth = req.headers.authorization || '';
  return /^Bearer\s+\S+/.test(auth);
}

/**
 * Bypass CSRF mobile : JWT Bearer obligatoire.
 * Un header x-mobile-app seul (forgable depuis un site) ne suffit pas.
 */
function isAuthenticatedMobileRequest(req) {
  if (!hasBearerToken(req)) return false;
  const ua = req.headers['user-agent'] || '';
  return (
    req.path.startsWith('/api/mobile/') ||
    req.headers['x-mobile-app'] === 'true' ||
    ua.includes('ChapeChapeApp') ||
    ua.includes('Dart/') ||
    ua.includes('Flutter')
  );
}

/**
 * Génère un token aléatoire sécurisé
 */
const generateToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

/**
 * Middleware principal de vérification CSRF
 */
const csrfMiddleware = (req, res, next) => {
  // 1. Logique de Bypass (identique à l'ancien middleware)
  if (isAuthenticatedMobileRequest(req)) {
    return next();
  }

  // 2. Bypass pour les méthodes non mutatives
  if (["GET", "HEAD", "OPTIONS"].includes(req.method)) {
    return next();
  }

  // 3. Récupération des tokens
  const tokenFromCookie = req.cookies && req.cookies[CSRF_COOKIE_NAME];
  const tokenFromHeader = req.headers[CSRF_HEADER_NAME] || req.headers['csrf-token'] || req.body?._csrf;

  // 4. Vérification
  if (!tokenFromCookie || !tokenFromHeader || tokenFromCookie !== tokenFromHeader) {
    logger.warn('CSRF_ATTACK_DETECTED', {
      ip: req.ip,
      method: req.method,
      path: req.path,
      cookieToken: tokenFromCookie ? 'PRESENT' : 'MISSING',
      headerToken: tokenFromHeader ? 'PRESENT' : 'MISSING',
    });

    return next(
      new apiError(
        "Accès invalide: jeton CSRF manquant ou incorrect",
        403,
        errorCodes.GENERAL.CSRF_ERROR
      )
    );
  }

  next();
};

/**
 * Middleware pour générer et attacher le token
 * Remplace csrfProtection pour la génération
 */
const generateCsrfToken = (req, res, next) => {
  // Uniquement pour GET
  if (req.method !== "GET") {
    return next();
  }

  // Bypass mobile
  if (isAuthenticatedMobileRequest(req)) {
    return next();
  }

  try {
    // Générer nouveau token ou réutiliser l'existant du cookie
    let token = req.cookies && req.cookies[CSRF_COOKIE_NAME];

    if (!token) {
      token = generateToken();

      // Définir le cookie
      res.cookie(CSRF_COOKIE_NAME, token, {
        path: "/",
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "strict",
        maxAge: 3600 * 1000 // 1 heure
      });
    }

    // Attacher aux locals et headers comme avant
    res.locals.csrfToken = token;

    // Méthode helper pour compatibilité avec l'ancien code qui appelait req.csrfToken()
    req.csrfToken = () => token;

    if (req.path.startsWith("/api/")) {
      res.setHeader("X-CSRF-Token", token);
    }

    next();
  } catch (error) {
    logger.error('CSRF_TOKEN_GENERATE_FAILED', { err: error.message });
    next(error);
  }
};

/**
 * Wrapper pour simuler l'ancienne API csrfProtection(req, res, next)
 * Utilisé dans app.js pour la route /api/csrf-token
 */
const csrfProtection = (req, res, next) => {
  // Si c'est pour générer un token (GET)
  if (req.method === 'GET') {
    return generateCsrfToken(req, res, next);
  }
  // Sinon c'est pour vérifier (POST, etc)
  return csrfMiddleware(req, res, next);
};

module.exports = {
  csrfMiddleware,
  generateCsrfToken,
  csrfProtection,
  isAuthenticatedMobileRequest,
};
