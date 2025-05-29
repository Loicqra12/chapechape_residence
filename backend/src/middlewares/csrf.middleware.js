/**
 * Middleware de protection CSRF pour l'API ChapeChape
 * Fournit une protection contre les attaques CSRF pour les routes sensibles
 */

const csrf = require("csurf");
const apiError = require("../utils/apiError");
const errorCodes = require("../utils/errorCodes");
// Commenté temporairement car il pourrait ne pas être correctement initialisé
// const { logger } = require("../utils/logger");

// Configuration de base de csurf
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
  // Bypass pour les applications mobiles (détection par header ou route)
  if (
    req.path.startsWith("/api/mobile/") ||
    req.headers["x-mobile-app"] === "true" ||
    req.headers["user-agent"]?.includes("ChapeChapeApp") ||
    (req.path.startsWith("/api/auth/") && req.headers["content-type"]?.includes("application/json"))
  ) {
    return next();
  }

  // Bypass pour les méthodes non mutatives
  if (["GET", "HEAD", "OPTIONS"].includes(req.method)) {
    return next();
  }

  csrfProtection(req, res, (err) => {
    if (err) {
      // Utiliser console.warn au lieu de logger.warn pour éviter l'erreur
      console.warn(
        `CSRF Attack Detected: ${req.ip} - ${req.method} ${req.path}`,
        {
          headers: req.headers,
          body: req.body,
        }
      );

      return next(
        apiError.forbidden(
          "Accès invalide: jeton CSRF manquant ou incorrect",
          errorCodes.GENERAL.CSRF_ERROR,
          { originalError: err.message }
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
  // Bypass pour les applications mobiles (détection par header ou route)
  if (
    req.path.startsWith("/api/mobile/") ||
    req.headers["x-mobile-app"] === "true" ||
    req.headers["user-agent"]?.includes("ChapeChapeApp") ||
    (req.path.startsWith("/api/auth/") && req.headers["content-type"]?.includes("application/json"))
  ) {
    return next();
  }

  // Appliquer directement csrfProtection sans vérification d'authentification
  csrfProtection(req, res, (err) => {
    if (err) {
      // Utiliser console.warn au lieu de logger.warn qui n'est pas défini
      console.warn(
        `Erreur lors de la génération du token CSRF: ${err.message}`
      );

      // Si c'est une route API, retourner une réponse JSON
      if (req.path.startsWith("/api/")) {
        // Bypass l'erreur et générer un nouveau cookie CSRF
        try {
          const token = req.csrfToken();
          res.setHeader("X-CSRF-Token", token);
          res.locals.csrfToken = token;
          return next();
        } catch (e) {
          console.error(`Impossible de générer un token CSRF: ${e.message}`);
          return res.status(500).json({
            success: false,
            message: "Erreur serveur lors de la génération du token CSRF",
          });
        }
      }

      return next();
    }

    // Ajouter le token CSRF à l'objet response pour y accéder dans les routes
    res.locals.csrfToken = req.csrfToken();

    // Si c'est une API, ajouter le token aux headers
    if (req.path.startsWith("/api/")) {
      res.setHeader("X-CSRF-Token", req.csrfToken());
    }

    next();
  });
};

module.exports = {
  csrfMiddleware,
  generateCsrfToken,
};
