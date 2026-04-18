const rateLimit = require('express-rate-limit');
const logger = require('../utils/logger');

// Redis client (optionnel)
let redisClient;
try {
  redisClient = require('../config/redis');
} catch (error) {
  logger.warn('Redis client import failed, using memory store for rate limiting');
}

// Chargement paresseux de rate-limit-redis (évite crash au démarrage si module absent)
function getRedisStore() {
  try {
    return require('rate-limit-redis');
  } catch (e) {
    return null;
  }
}

/**
 * Crée un store Redis avec fallback en mémoire
 * Ne charge rate-limit-redis qu'au moment de créer le store (évite crash au démarrage)
 */
const createStore = (prefix) => {
  if (process.env.NODE_ENV === 'development' || !redisClient) {
    logger.info(`Rate limiter "${prefix}" using memory store (dev or no Redis)`);
    return undefined;
  }
  const RedisStoreClass = getRedisStore();
  if (!RedisStoreClass) {
    logger.warn(`Rate limiter "${prefix}" using memory store (rate-limit-redis not installed)`);
    return undefined;
  }
  try {
    return new RedisStoreClass({
      client: redisClient,
      prefix: `rl:${prefix}:`,
      sendCommand: (...args) => redisClient.call(...args),
    });
  } catch (error) {
    logger.error(`Failed to create Redis store for "${prefix}":`, error);
    return undefined;
  }
};

/**
 * Rate limiter global (100 req/15min par IP)
 * Appliqué à toutes les routes API
 */
const globalLimiter = rateLimit({
  store: createStore('global'),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Réduit de 200 à 100
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip health checks et pings
    return req.path.startsWith('/api/health') ||
      req.path.startsWith('/api/ping');
  },
  handler: (req, res) => {
    logger.warn(`Global rate limit exceeded: ${req.ip} - ${req.method} ${req.path}`);
    res.status(429).json({
      success: false,
      message: 'Trop de requêtes, veuillez réessayer dans 15 minutes',
      retryAfter: 900
    });
  }
});

/**
 * Rate limiter strict pour authentification (5 req/15min par IP)
 * Appliqué aux routes /api/auth/login et /api/auth/register
 */
const authLimiter = rateLimit({
  store: createStore('auth'),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Très strict
  skipSuccessfulRequests: true, // Ne compte que les échecs
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Auth rate limit exceeded: ${req.ip} - ${req.method} ${req.path}`);
    res.status(429).json({
      success: false,
      message: 'Trop de tentatives de connexion. Réessayez dans 15 minutes.',
      retryAfter: 900
    });
  }
});

/**
 * Rate limiter pour paiements (3 req/1min par IP)
 * Appliqué aux routes /api/payments
 */
const paymentLimiter = rateLimit({
  store: createStore('payment'),
  windowMs: 60 * 1000, // 1 minute
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Payment rate limit exceeded: ${req.ip} - ${req.method} ${req.path}`);
    res.status(429).json({
      success: false,
      message: 'Trop de tentatives de paiement. Veuillez patienter 1 minute.',
      retryAfter: 60
    });
  }
});

/**
 * Rate limiter par utilisateur authentifié (100 req/15min par user)
 * Utilise l'ID utilisateur si disponible, sinon l'IP
 */
const userLimiter = rateLimit({
  store: createStore('user'),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Utiliser user ID si authentifié, sinon IP
    return req.user ? req.user._id.toString() : req.ip;
  },
  handler: (req, res) => {
    const identifier = req.user ? `User ${req.user._id}` : `IP ${req.ip}`;
    logger.warn(`User rate limit exceeded: ${identifier} - ${req.method} ${req.path}`);
    res.status(429).json({
      success: false,
      message: 'Trop de requêtes. Veuillez patienter 15 minutes.',
      retryAfter: 900
    });
  }
});

/**
 * Rate limiter pour upload de fichiers (10 req/15min par IP)
 */
const uploadLimiter = rateLimit({
  store: createStore('upload'),
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Upload rate limit exceeded: ${req.ip}`);
    res.status(429).json({
      success: false,
      message: 'Trop d\'uploads. Réessayez dans 15 minutes.',
      retryAfter: 900
    });
  }
});

/**
 * Rate limiter pour requêtes OTP Twilio/WhatsApp (3 req/15min par IP/Numéro)
 */
const otpLimiter = rateLimit({
  store: createStore('otp'),
  windowMs: 15 * 60 * 1000,
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    // Si la requête contient le numéro de téléphone, on limite par numéro, sinon par IP
    return req.body && req.body.phoneNumber ? req.body.phoneNumber : req.ip;
  },
  handler: (req, res) => {
    logger.warn(`OTP rate limit exceeded: ${req.ip} / ${req.body?.phoneNumber}`);
    res.status(429).json({
      success: false,
      message: 'Trop de requêtes de code. Réessayez dans 15 minutes.',
      retryAfter: 900
    });
  }
});

module.exports = {
  globalLimiter,
  authLimiter,
  paymentLimiter,
  userLimiter,
  uploadLimiter,
  otpLimiter
};
