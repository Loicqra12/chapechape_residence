const { verifySignature, extractSignatureHeaders } = require('../utils/hmac-signature');
const apiError = require('../utils/apiError');
const logger = require('../utils/logger');

/**
 * Middleware d'authentification pour les apps mobiles
 * 
 * Vérifie la signature HMAC des requêtes provenant des apps mobiles Flutter/React Native
 * Remplace le bypass CSRF basé sur Content-Type (vulnérable)
 * 
 * Headers requis:
 * - X-API-Key: Clé API de l'app mobile
 * - X-Mobile-Signature: Signature HMAC-SHA256
 * - X-Timestamp: Timestamp Unix en millisecondes
 * 
 * Exemple Flutter:
 * ```dart
 * final signature = generateHMAC(apiKey, path, timestamp);
 * headers['X-API-Key'] = apiKey;
 * headers['X-Mobile-Signature'] = signature;
 * headers['X-Timestamp'] = timestamp.toString();
 * ```
 */
const mobileAuthMiddleware = (req, res, next) => {
  try {
    // Extraire les headers de signature
    const headers = extractSignatureHeaders(req);

    // Si headers manquants, ce n'est pas une app mobile authentifiée
    if (!headers) {
      logger.debug('Mobile auth headers missing', {
        path: req.path,
        method: req.method,
        hasApiKey: !!req.headers['x-api-key'],
        hasSignature: !!req.headers['x-mobile-signature'],
        hasTimestamp: !!req.headers['x-timestamp']
      });

      return next(
        new apiError(
          'Headers d\'authentification mobile requis (X-API-Key, X-Mobile-Signature, X-Timestamp)',
          401,
          'AUTH_MOBILE_HEADERS_MISSING'
        )
      );
    }

    const { apiKey, signature, timestamp } = headers;

    // Vérifier la signature HMAC
    const isValid = verifySignature(
      apiKey,
      req.path,
      timestamp,
      signature
    );

    if (!isValid) {
      logger.warn('Invalid mobile signature', {
        apiKey,
        path: req.path,
        ip: req.ip,
        userAgent: req.get('User-Agent')
      });

      return next(
        new apiError(
          'Signature mobile invalide ou expirée',
          401,
          'AUTH_MOBILE_SIGNATURE_INVALID'
        )
      );
    }

    // Signature valide - marquer la requête comme authentifiée (mobile)
    req.isMobileAuthenticated = true;
    req.mobileApiKey = apiKey;

    logger.info('Mobile app authenticated', {
      apiKey,
      path: req.path,
      method: req.method
    });

    next();

  } catch (error) {
    logger.error('Mobile auth middleware error', {
      error: error.message,
      stack: error.stack,
      path: req.path
    });

    return next(
      new apiError(
        'Erreur lors de la vérification de l\'authentification mobile',
        500,
        'AUTH_MOBILE_ERROR'
      )
    );
  }
};

/**
 * Middleware optionnel - Permet requêtes sans signature mobile
 * Mais si signature présente, elle DOIT être valide
 * 
 * Utilité: Routes publiques accessibles via web ET mobile
 */
const optionalMobileAuth = (req, res, next) => {
  const headers = extractSignatureHeaders(req);

  // Pas de headers -> skip authentication
  if (!headers) {
    return next();
  }

  // Headers présents -> vérifier obligatoirement
  return mobileAuthMiddleware(req, res, next);
};

/**
 * Helper pour vérifier si une requête provient d'une app mobile authentifiée
 * 
 * @param {Object} req - Requête Express
 * @returns {boolean}
 */
const isMobileApp = (req) => {
  return req.isMobileAuthenticated === true;
};

module.exports = {
  mobileAuthMiddleware,
  optionalMobileAuth,
  isMobileApp
};
