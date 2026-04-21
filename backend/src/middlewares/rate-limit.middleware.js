const rateLimit = require('express-rate-limit');
const logger = require('../utils/logger');

// Module Redis (singleton) — utiliser getClient() pour l’instance ioredis native (méthode .call)
let redisModule;
try {
  redisModule = require('../config/redis');
} catch (error) {
  logger.warn('Redis client import failed, using memory store for rate limiting');
}

const getRedisNative = () => {
  if (!redisModule) return null;
  return typeof redisModule.getClient === 'function' ? redisModule.getClient() : redisModule;
};

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
  if (process.env.NODE_ENV === 'development' || process.env.RATE_LIMIT_USE_MEMORY === 'true' || !redisModule) {
    logger.info(`Rate limiter "${prefix}" using memory store (dev or no Redis)`);
    return undefined;
  }
  const RedisStoreClass = getRedisStore();
  if (!RedisStoreClass) {
    logger.warn(`Rate limiter "${prefix}" using memory store (rate-limit-redis not installed)`);
    return undefined;
  }
  const native = getRedisNative();
  if (!native) {
    logger.warn(`Rate limiter "${prefix}" using memory store (no native Redis client)`);
    return undefined;
  }
  try {
    return new RedisStoreClass({
      client: native,
      prefix: `rl:${prefix}:`,
      sendCommand: (...args) => {
        if (typeof native.call === 'function') {
          return native.call(...args);
        }
        if (typeof native.sendCommand === 'function') {
          return native.sendCommand(...args);
        }
        logger.error(`Rate limiter "${prefix}": Redis client has no call/sendCommand`);
        return Promise.reject(new Error('Redis client incompatible with rate-limit-redis'));
      },
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
 * Connexion : strict (5 échecs / 15 min par IP).
 * Les réponses 2xx/3xx ne comptent pas (skipSuccessfulRequests).
 */
const authLoginLimiter = rateLimit({
  store: createStore('auth-login'),
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Auth login rate limit exceeded: ${req.ip} - ${req.method} ${req.path}`);
    res.status(429).json({
      success: false,
      message: 'Trop de tentatives de connexion. Réessayez dans 15 minutes.',
      retryAfter: 900
    });
  }
});

/**
 * Inscription : plafond plus haut (erreurs métier ex. email déjà pris comptent comme échecs).
 * Évite de bloquer l’IP après quelques essais légitimes tout en limitant l’abus.
 */
const authRegisterLimiter = rateLimit({
  store: createStore('auth-register'),
  windowMs: 15 * 60 * 1000,
  max: 40,
  skipSuccessfulRequests: true,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Auth register rate limit exceeded: ${req.ip} - ${req.method} ${req.path}`);
    res.status(429).json({
      success: false,
      message: 'Trop de tentatives d’inscription. Réessayez dans 15 minutes.',
      retryAfter: 900
    });
  }
});

/** @deprecated Utiliser authLoginLimiter ; conservé pour compatibilité des imports */
const authLimiter = authLoginLimiter;

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

/**
 * Mot de passe oublié — limite l’email bombing (par IP)
 */
const authForgotPasswordLimiter = rateLimit({
  store: createStore('auth-forgot-password'),
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => {
    logger.warn(`Forgot-password rate limit exceeded: ${req.ip}`);
    res.status(429).json({
      success: false,
      message: 'Trop de demandes de réinitialisation. Réessayez dans 15 minutes.',
      retryAfter: 900
    });
  }
});

/**
 * Vérification du code SMS — complète otpLimiter (envoi) en limitant les essais (IP + téléphone)
 */
const authVerifyCodeLimiter = rateLimit({
  store: createStore('auth-verify-code'),
  windowMs: 15 * 60 * 1000,
  max: 25,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    const phone = req.body && req.body.phoneNumber ? String(req.body.phoneNumber) : '';
    return phone ? `${req.ip}:${phone}` : req.ip;
  },
  handler: (req, res) => {
    logger.warn(`Verify-code rate limit exceeded: ${req.ip}`);
    res.status(429).json({
      success: false,
      message: 'Trop de tentatives de vérification. Réessayez dans 15 minutes.',
      retryAfter: 900
    });
  }
});

const smsSendMaxPerHour = (() => {
  const n = parseInt(process.env.SMS_SEND_MAX_PER_HOUR || '40', 10);
  return Number.isFinite(n) && n > 0 ? n : 40;
})();

/**
 * Envoi SMS libre (Partner/Admin) — POST /api/sms/send
 * Limite par utilisateur authentifié pour limiter l’abus si compte compromis.
 * Plafond configurable : SMS_SEND_MAX_PER_HOUR (défaut 40 / heure).
 */
const smsPartnerSendLimiter = rateLimit({
  store: createStore('partner-sms-send'),
  windowMs: 60 * 60 * 1000,
  max: smsSendMaxPerHour,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => (req.user && req.user._id ? req.user._id.toString() : req.ip),
  handler: (req, res) => {
    const id = req.user && req.user._id ? req.user._id.toString() : req.ip;
    logger.warn(`Partner SMS send rate limit exceeded: ${id}`);
    res.status(429).json({
      success: false,
      message: 'Trop d’envois SMS. Réessayez dans une heure ou contactez le support.',
      retryAfter: 3600
    });
  }
});

module.exports = {
  globalLimiter,
  authLoginLimiter,
  authRegisterLimiter,
  authLimiter,
  paymentLimiter,
  userLimiter,
  uploadLimiter,
  otpLimiter,
  authForgotPasswordLimiter,
  authVerifyCodeLimiter,
  smsPartnerSendLimiter
};
