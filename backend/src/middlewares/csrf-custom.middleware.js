/**
 * Middleware de protection CSRF Custom
 * Remplace le package 'csurf' déprécié
 * Implémente le pattern Double Submit Cookie sécurisé
 */

const crypto = require('crypto');
const apiError = require("../utils/apiError");
const errorCodes = require("../utils/errorCodes");

// Configuration
const CSRF_COOKIE_NAME = '_csrf';
const CSRF_HEADER_NAME = 'x-csrf-token';

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
  if (
    req.path.startsWith("/api/mobile/") ||
    req.headers["x-mobile-app"] === "true" ||
    req.headers["user-agent"]?.includes("ChapeChapeApp") ||
    req.headers["user-agent"]?.includes("Dart/") ||
    req.headers["user-agent"]?.includes("Flutter")
  ) {
    return next();
  }

  // 2. Bypass pour les méthodes non mutatives
  if (["GET", "HEAD", "OPTIONS"].includes(req.method)) {
    return next();
  }

  // 3. Récupération des tokens
  const tokenFromCookie = req.cookies[CSRF_COOKIE_NAME];
  const tokenFromHeader = req.headers[CSRF_HEADER_NAME] || req.headers['csrf-token'] || req.body?._csrf;

  // 4. Vérification
  if (!tokenFromCookie || !tokenFromHeader || tokenFromCookie !== tokenFromHeader) {
    console.warn(
      `CSRF Attack Detected (Custom): ${req.ip} - ${req.method} ${req.path}`,
      {
        cookieToken: tokenFromCookie ? 'PRESENT' : 'MISSING',
        headerToken: tokenFromHeader ? 'PRESENT' : 'MISSING'
      }
    );

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
  if (
    req.path.startsWith("/api/mobile/") ||
    req.headers["x-mobile-app"] === "true" ||
    req.headers["user-agent"]?.includes("ChapeChapeApp")
  ) {
    return next();
  }

  try {
    // Générer nouveau token ou réutiliser l'existant du cookie
    let token = req.cookies[CSRF_COOKIE_NAME];

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
    console.error(`Erreur génération CSRF custom: ${error.message}`);
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
  csrfProtection
};
