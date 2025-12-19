const errorCodes = require('./errorCodes');
const logger = require('./logger');

/**
 * Sanitise une erreur pour éviter l'exposition d'informations sensibles
 * 
 * Sécurité:
 * - Supprime stack traces en production
 * - Messages génériques pour erreurs 5xx
 * - Préserve détails pour erreurs 4xx (client)
 * - Log complet côté serveur uniquement
 * 
 * @param {Error} error - Erreur à sanitiser
 * @param {boolean} isProduction - Mode production ou non
 * @returns {Object} Erreur sanitisée {message, code, statusCode, stack?}
 */
function sanitizeError(error, isProduction = process.env.NODE_ENV === 'production') {
  // Erreur opérationnelle (attendue et gérée)
  if (error.isOperational || error.statusCode) {
    return {
      message: error.message,
      code: error.errorCode || error.code || errorCodes.GENERAL.SERVER_ERROR,
      statusCode: error.statusCode || 500,
      errors: error.errors || [],
      // Stack trace seulement en dev
      stack: !isProduction && process.env.SHOW_STACK === 'true' ? error.stack : undefined
    };
  }

  // Erreur de programmation (non attendue - bug)
  if (isProduction) {
    // En production: message générique
    logger.error('🚨 NON-OPERATIONAL ERROR (BUG):', {
      message: error.message,
      stack: error.stack,
      name: error.name
    });

    return {
      message: 'Une erreur inattendue s\'est produite. Nos équipes ont été notifiées.',
      code: errorCodes.GENERAL.SERVER_ERROR,
      statusCode: 500,
      errors: []
    };
  }

  // En développement: plus de détails (mais toujours sanitisé)
  return {
    message: error.message,
    code: errorCodes.GENERAL.SERVER_ERROR,
    statusCode: 500,
    errors: [],
    // Stack trace optionnelle même en dev
    stack: process.env.SHOW_STACK === 'true' ? error.stack : undefined,
    // Type d'erreur pour debug
    errorType: error.name
  };
}

/**
 * Vérifie si une erreur est opérationnelle (attendue/gérée)
 * vs erreur de programmation (bug)
 * 
 * @param {Error} error - Erreur à vérifier
 * @returns {boolean}
 */
function isOperationalError(error) {
  // Erreurs marquées explicitement
  if (error.isOperational === true) {
    return true;
  }

  // Erreurs avec statusCode 4xx sont généralement opérationnelles
  if (error.statusCode && error.statusCode >= 400 && error.statusCode < 500) {
    return true;
  }

  // Erreurs Mongoose connues
  const operationalErrors = [
    'ValidationError',
    'CastError',
    'DocumentNotFoundError'
  ];

  if (operationalErrors.includes(error.name)) {
    return true;
  }

  return false;
}

/**
 * Sanitise un message d'erreur pour supprimer infos sensibles
 * 
 * @param {string} message - Message à sanitiser
 * @returns {string} Message sanitisé
 */
function sanitizeMessage(message) {
  if (!message) return 'Erreur inconnue';

  // Masquer chemins de fichiers
  message = message.replace(/\/[^\s]+\/([^\s]+)/g, '[PATH]/$1');

  // Masquer IPs
  message = message.replace(/\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/g, '[IP]');

  // Masquer tokens/secrets (patterns communs)
  message = message.replace(/[a-f0-9]{32,}/gi, '[TOKEN]');

  // Masquer emails
  message = message.replace(/[\w.-]+@[\w.-]+\.\w+/g, '[EMAIL]');

  return message;
}

/**
 * Extrait des infos sûres d'une erreur pour logging
 * 
 * @param {Error} error - Erreur
 * @param {Object} req - Requête Express (optionnel)
 * @returns {Object} Infos sûres pour logging
 */
function extractSafeErrorInfo(error, req = null) {
  const info = {
    name: error.name,
    message: error.message,
    code: error.errorCode || error.code,
    statusCode: error.statusCode,
    timestamp: new Date().toISOString()
  };

  if (req) {
    info.request = {
      method: req.method,
      path: req.path,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      userId: req.user?._id?.toString()
    };
  }

  // Stack en dev uniquement
  if (process.env.NODE_ENV !== 'production') {
    info.stack = error.stack;
  }

  return info;
}

module.exports = {
  sanitizeError,
  isOperationalError,
  sanitizeMessage,
  extractSafeErrorInfo
};
