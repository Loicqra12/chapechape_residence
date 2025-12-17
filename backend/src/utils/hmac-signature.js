const crypto = require('crypto');
const logger = require('../utils/logger');

/**
 * Génère une signature HMAC-SHA256 pour authentifier les requêtes des apps mobiles
 * 
 * Format de la signature:
 * HMAC-SHA256(apiKey + path + timestamp, MOBILE_APP_SECRET)
 * 
 * @param {string} apiKey - Clé API unique de l'app mobile (ex: "chapechape-mobile-v1")
 * @param {string} path - Chemin de la requête (ex: "/api/auth/login")
 * @param {string} timestamp - Timestamp Unix en millisecondes
 * @returns {string} Signature HMAC en hexadécimal
 */
function generateSignature(apiKey, path, timestamp) {
  const secret = process.env.MOBILE_APP_SECRET;

  if (!secret) {
    logger.error('MOBILE_APP_SECRET not configured in environment');
    throw new Error('Configuration erreur: Secret mobile non configuré');
  }

  // Créer le payload à signer
  const payload = `${apiKey}:${path}:${timestamp}`;

  // Générer la signature HMAC-SHA256
  const signature = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');

  return signature;
}

/**
 * Vérifie une signature HMAC
 * 
 * Sécurité:
 * - Utilise crypto.timingSafeEqual pour éviter timing attacks
 * - Vérifie la validité du timestamp (max 5min)
 * - Compare les longueurs avant la comparaison
 * 
 * @param {string} apiKey - Clé API de l'app
 * @param {string} path - Chemin de la requête
 * @param {string} timestamp - Timestamp de la requête
 * @param {string} signature - Signature reçue à vérifier
 * @returns {boolean} true si signature valide, false sinon
 */
function verifySignature(apiKey, path, timestamp, signature) {
  try {
    // Vérifier que tous les paramètres sont présents
    if (!apiKey || !path || !timestamp || !signature) {
      logger.warn('Missing parameters for signature verification');
      return false;
    }

    // Vérifier que le timestamp est récent (5min max)
    const now = Date.now();
    const requestTime = parseInt(timestamp, 10);
    const maxAge = 5 * 60 * 1000; // 5 minutes

    if (isNaN(requestTime)) {
      logger.warn('Invalid timestamp format', { timestamp });
      return false;
    }

    if (Math.abs(now - requestTime) > maxAge) {
      logger.warn('Signature expired', {
        now,
        requestTime,
        diff: Math.abs(now - requestTime)
      });
      return false;
    }

    // Générer la signature attendue
    const expectedSignature = generateSignature(apiKey, path, timestamp);

    // Conversion en Buffer pour comparaison timing-safe
    const expectedBuffer = Buffer.from(expectedSignature, 'hex');
    const signatureBuffer = Buffer.from(signature, 'hex');

    // Vérifier que les longueurs correspondent
    if (expectedBuffer.length !== signatureBuffer.length) {
      logger.warn('Signature length mismatch', {
        expected: expectedBuffer.length,
        received: signatureBuffer.length
      });
      return false;
    }

    // Comparaison timing-safe pour éviter timing attacks
    const isValid = crypto.timingSafeEqual(expectedBuffer, signatureBuffer);

    if (!isValid) {
      logger.warn('Invalid HMAC signature', { apiKey, path });
    }

    return isValid;

  } catch (error) {
    logger.error('Error verifying HMAC signature', {
      error: error.message,
      stack: error.stack
    });
    return false;
  }
}

/**
 * Génère une clé API pour une nouvelle app mobile
 * Utilité: Pour générer des clés API uniques par app/version
 * 
 * @param {string} appName - Nom de l'app (ex: "chapechape-client")
 * @param {string} version - Version de l'app (ex: "1.3.1")
 * @returns {string} Clé API unique
 */
function generateApiKey(appName, version) {
  const timestamp = Date.now();
  const random = crypto.randomBytes(8).toString('hex');
  return `${appName}-${version}-${timestamp}-${random}`;
}

/**
 * Middleware helper pour extraire les headers de signature
 * 
 * @param {Object} req - Requête Express
 * @returns {Object} { apiKey, signature, timestamp } ou null si manquants
 */
function extractSignatureHeaders(req) {
  const apiKey = req.headers['x-api-key'];
  const signature = req.headers['x-mobile-signature'];
  const timestamp = req.headers['x-timestamp'];

  if (!apiKey || !signature || !timestamp) {
    return null;
  }

  return { apiKey, signature, timestamp };
}

module.exports = {
  generateSignature,
  verifySignature,
  generateApiKey,
  extractSignatureHeaders
};
