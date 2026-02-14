const rateLimit = require('express-rate-limit');
const logger = require('../utils/logger');

// Chargement optionnel de rate-limit-redis (évite crash si npm install incomplet en prod)
let RedisStore;
try {
  RedisStore = require('rate-limit-redis');
} catch (e) {
  logger.warn('rate-limit-redis not installed, rate limiting will use memory store. Run: npm install rate-limit-redis');
}

// Import du client Redis (avec support Mock)
let redisClient;
try {
  redisClient = require('../config/redis');
} catch (error) {
  logger.warn('Redis client import failed, using memory store for rate limiting');
}

/**
 * Crée un store Redis avec fallback en mémoire
 * Si Redis est indisponible ou rate-limit-redis absent, rate-limit utilisera la mémoire locale
 */
const createStore = (prefix) => {
  // En développement, sans Redis ou sans module rate-limit-redis → mémoire
  if (process.env.NODE_ENV === 'development' || !redisClient || !RedisStore) {
    if (!RedisStore) {
      logger.warn(`Rate limiter "${prefix}" using memory store (rate-limit-redis not available)`);
    } else {
      logger.info(`Rate limiter "${prefix}" using memory store (dev mode)`);
    }
    return undefined; // express-rate-limit utilisera MemoryStore par défaut
  }

  try {
    // En production, utiliser Redis
    return new RedisStore({
      client: redisClient,
      prefix: `rl:${prefix}:`,
      sendCommand: (...args) => redisClient.call(...args),
    });
  } catch (error) {
    logger.error(`Failed to create Redis store for "${prefix}":`, error);
    logger.warn(`Falling back to memory store for "${prefix}"`);
    return undefined; // Fallback mémoire
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

module.exports = {
  globalLimiter,
  authLimiter,
  paymentLimiter,
  userLimiter,
  uploadLimiter
};
