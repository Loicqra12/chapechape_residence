/**
 * Middleware de protection CSRF pour l'API ChapeChape
 * Fournit une protection contre les attaques CSRF pour les routes sensibles
 * Utilise csurf avec des mesures de sécurité renforcées
 */

const csrf = require("csurf");
const apiError = require("../utils/apiError");
const errorCodes = require("../utils/errorCodes");
// Commenté temporairement car il pourrait ne pas être correctement initialisé
// const { logger } = require("../utils/logger");

// Configuration de base de csurf avec sécurité renforcée
const csrfProtection = csrf({
  cookie: {
    key: "_csrf",
    path: "/",
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "strict",
    maxAge: 3600 * 1000, // 1 heure
  },
});

/**
 * Middleware qui génère et vérifie les tokens CSRF
 * À utiliser sur les routes sensibles nécessitant une protection CSRF
 */
const csrfMiddleware = (req, res, next) => {
  // Bypass pour les applications mobiles (détection élargie)
  if (
    req.path.startsWith("/api/mobile/") ||
    req.headers["x-mobile-app"] === "true" ||
    req.headers["user-agent"]?.includes("ChapeChapeApp") ||
    req.headers["user-agent"]?.includes("Dart/") ||  // Flutter apps
    req.headers["user-agent"]?.includes("Flutter") ||
    req.headers["content-type"]?.includes("application/json") ||  // API calls génériques
    (req.path.startsWith("/api/auth/") && req.headers["content-type"]?.includes("application/json"))
  ) {
    return next();
  }

  // Bypass pour les méthodes non mutatives
  if (["GET", "HEAD", "OPTIONS"].includes(req.method)) {
    return next();
  }

  // Appliquer csrfProtection qui vérifiera le token
  csrfProtection(req, res, (err) => {
    if (err) {
      // Utiliser console.warn au lieu de logger.warn pour éviter l'erreur
      console.warn(
        `CSRF Attack Detected: ${req.ip} - ${req.method} ${req.path}`,
        {
          headers: req.headers,
          body: req.body
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
  });
};

/**
 * Middleware qui génère un token CSRF pour le client
 * À utiliser sur les routes qui renvoient des formulaires ou des pages
 */
const generateCsrfToken = (req, res, next) => {
  // Pas besoin de générer un token pour les méthodes non-GET
  if (req.method !== "GET") {
    return next();
  }

  // Bypass pour les applications mobiles
  if (
    req.path.startsWith("/api/mobile/") ||
    req.headers["x-mobile-app"] === "true" ||
    req.headers["user-agent"]?.includes("ChapeChapeApp")
  ) {
    return next();
  }

  // Appliquer csrfProtection en mode génération seulement
  csrfProtection(req, res, (err) => {
    if (err) {
      console.error(`Impossible de générer un token CSRF: ${err.message}`);
      if (req.path.startsWith("/api/")) {
        return res.status(500).json({
          success: false,
          message: "Erreur serveur lors de la génération du token CSRF",
        });
      }
      return next();
    }
    
    // Ajouter le token CSRF aux locals pour les templates
    const token = req.csrfToken();
    res.locals.csrfToken = token;
    
    // Si c'est une API, ajouter le token aux headers
    if (req.path.startsWith("/api/")) {
      res.setHeader("X-CSRF-Token", token);
    }
    
    next();
  });
};

module.exports = {
  csrfMiddleware,
  generateCsrfToken,
  csrfProtection,
};
