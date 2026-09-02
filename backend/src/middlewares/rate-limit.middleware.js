const crypto = require('crypto');
const rateLimit = require('express-rate-limit');
const logger = require('../utils/logger');
const { POLICIES, IPV6_SUBNET } = require('../security/rate-limit-policies');

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

function getRedisStore() {
  try {
    const mod = require('rate-limit-redis');
    if (mod && mod.RedisStore) return mod.RedisStore;
    if (typeof mod === 'function') return mod;
    return null;
  } catch (e) {
    return null;
  }
}

function useMemoryStore() {
  return (
    process.env.NODE_ENV === 'test'
    || process.env.RATE_LIMIT_USE_MEMORY === 'true'
    || !redisModule
  );
}

const createStore = (prefix) => {
  if (useMemoryStore()) {
    return undefined;
  }
  const RedisStoreClass = getRedisStore();
  const native = getRedisNative();
  if (!RedisStoreClass || !native || native.isMock) {
    return undefined;
  }
  try {
    return new RedisStoreClass({
      prefix: `rl:${prefix}:`,
      sendCommand: (...args) => {
        if (typeof native.call === 'function') return native.call(...args);
        if (typeof native.sendCommand === 'function') return native.sendCommand(...args);
        return Promise.reject(new Error('Redis client incompatible with rate-limit-redis'));
      },
    });
  } catch (error) {
    logger.error(`Failed to create Redis store for "${prefix}":`, error);
    return undefined;
  }
};

function hashIp(ip) {
  return crypto.createHash('sha256').update(String(ip || '')).digest('hex').slice(0, 12);
}

/**
 * IPv4 tel quel ; IPv6 tronqué au préfixe /64 (4 hextets) pour limiter
 * l'explosion d'adresses dans un même préfixe.
 */
function subnetSafeIp(ip) {
  const raw = String(ip || 'unknown').replace(/^::ffff:/i, '');
  if (raw.includes(':')) {
    const groups = raw.split(':').filter((g) => g.length > 0);
    const prefixGroups = Math.max(1, Math.min(4, Math.floor(IPV6_SUBNET / 16)));
    return `${groups.slice(0, prefixGroups).join(':')}::/${IPV6_SUBNET}`;
  }
  return raw;
}

function clientIpKey(req) {
  const ip = req.ip || req.socket?.remoteAddress || 'unknown';
  return subnetSafeIp(ip);
}

function normalizeAccountKey(req) {
  const email = String(req.body?.email || req.body?.identifier || '').trim().toLowerCase();
  return email || null;
}

function normalizePhoneKey(req) {
  try {
    const { normalizePhoneToE164 } = require('../utils/phone.util');
    const raw = req.body?.phoneNumber;
    if (!raw) return null;
    return normalizePhoneToE164(String(raw), req.body?.countryCode || 'CI') || null;
  } catch (_) {
    return null;
  }
}

function keyFor(policy, req) {
  switch (policy.key) {
    case 'account':
      return `acct:${normalizeAccountKey(req) || clientIpKey(req)}`;
    case 'phone':
      return `phone:${normalizePhoneKey(req) || clientIpKey(req)}`;
    case 'user':
      return req.user?._id ? `user:${req.user._id}` : `ip:${clientIpKey(req)}`;
    case 'user-or-ip':
      return req.user?._id ? `user:${req.user._id}` : `ip:${clientIpKey(req)}`;
    default:
      return `ip:${clientIpKey(req)}`;
  }
}

function isWebhookPath(req) {
  const path = `${req.originalUrl || ''} ${req.path || ''}`;
  return /\/webhook(\/|$|\?)/i.test(path) || /cinetpay\/webhook/i.test(path);
}

function isHealthPath(req) {
  const p = req.path || req.originalUrl || '';
  return p.startsWith('/health') || p.startsWith('/ping')
    || p.startsWith('/api/health') || p.startsWith('/api/ping');
}

function emitHit(event, req, policy) {
  logger.warn(event, {
    event,
    route: `${req.method} ${req.originalUrl || req.path}`,
    userId: req.user?._id ? String(req.user._id) : undefined,
    ipHash: hashIp(req.ip),
    policy: policy.name,
    requestId: req.id || req.headers?.['x-request-id'],
    correlationId: req.headers?.['x-correlation-id'],
    timestamp: new Date().toISOString(),
  });
}

function tooMany(req, res, policy) {
  const retryAfter = Math.ceil(policy.windowMs / 1000);
  res.setHeader('Retry-After', String(retryAfter));
  return res.status(429).json({
    success: false,
    code: 'RATE_LIMIT_EXCEEDED',
    message: 'Trop de requêtes. Réessayez plus tard.',
    retryAfter,
  });
}

function buildLimiter(policy, extras = {}) {
  const limiter = rateLimit({
    windowMs: policy.windowMs,
    max: policy.max,
    standardHeaders: true,
    legacyHeaders: false,
    store: createStore(policy.name.toLowerCase()),
    keyGenerator: (req) => keyFor(policy, req),
    validate: false,
    skip: (req) => {
      if (req.headers?.['x-mobile-app'] && extras.skipMobile) return false;
      if (extras.skip && extras.skip(req)) return true;
      return false;
    },
    skipSuccessfulRequests: extras.skipSuccessfulRequests === true,
    handler: (req, res) => {
      emitHit(
        extras.event || 'RATE_LIMIT_HIT',
        req,
        policy
      );
      return tooMany(req, res, policy);
    },
  });

  return function wrappedLimiter(req, res, next) {
    if (req.headers?.['x-forwarded-for'] && req.app?.get('trust proxy') === false) {
      logger.info('SUSPICIOUS_FORWARDED_IP', {
        event: 'SUSPICIOUS_FORWARDED_IP',
        ipHash: hashIp(req.ip),
        forwardedHash: hashIp(String(req.headers['x-forwarded-for']).split(',')[0]),
        route: req.originalUrl,
      });
    }
    try {
      return limiter(req, res, (err) => {
        if (err) {
          logger.error('RATE_LIMIT_STORE_ERROR', { policy: policy.name, message: err.message });
          if (policy.failClosed) {
            return res.status(503).json({
              success: false,
              code: 'RATE_LIMIT_UNAVAILABLE',
              message: 'Service temporairement indisponible',
            });
          }
          return next();
        }
        return next();
      });
    } catch (err) {
      logger.error('RATE_LIMIT_STORE_ERROR', { policy: policy.name, message: err.message });
      if (policy.failClosed) {
        return res.status(503).json({
          success: false,
          code: 'RATE_LIMIT_UNAVAILABLE',
          message: 'Service temporairement indisponible',
        });
      }
      return next();
    }
  };
}

const globalLimiter = buildLimiter(POLICIES.PUBLIC, {
  event: 'RATE_LIMIT_HIT',
  skip: (req) => isHealthPath(req) || isWebhookPath(req),
});

const authLoginLimiter = buildLimiter(POLICIES.AUTH_LOGIN_IP, {
  event: 'AUTH_RATE_LIMIT_HIT',
  skipSuccessfulRequests: true,
});

const authLoginAccountLimiter = buildLimiter(POLICIES.AUTH_LOGIN_ACCOUNT, {
  event: 'AUTH_RATE_LIMIT_HIT',
  skipSuccessfulRequests: true,
});

const authRegisterLimiter = buildLimiter(POLICIES.AUTH_REGISTER, {
  event: 'AUTH_RATE_LIMIT_HIT',
  skipSuccessfulRequests: true,
});

const authForgotPasswordLimiter = buildLimiter(POLICIES.AUTH_FORGOT_IP, {
  event: 'AUTH_RATE_LIMIT_HIT',
});

const authForgotAccountLimiter = buildLimiter(POLICIES.AUTH_FORGOT_ACCOUNT, {
  event: 'AUTH_RATE_LIMIT_HIT',
});

const otpSendPhoneLimiter = buildLimiter(POLICIES.OTP_SEND_PHONE, {
  event: 'OTP_RATE_LIMIT_HIT',
});

const otpSendIpLimiter = buildLimiter(POLICIES.OTP_SEND_IP, {
  event: 'OTP_RATE_LIMIT_HIT',
});

const otpLimiter = (req, res, next) => otpSendPhoneLimiter(req, res, () => otpSendIpLimiter(req, res, next));

const authVerifyCodeLimiter = buildLimiter(POLICIES.OTP_VERIFY, {
  event: 'OTP_RATE_LIMIT_HIT',
});

const paymentLimiter = buildLimiter(POLICIES.FINANCIAL, {
  event: 'PAYMENT_RATE_LIMIT_HIT',
  skip: (req) => isWebhookPath(req),
});

const userLimiter = buildLimiter(POLICIES.AUTHENTICATED);
const uploadLimiter = buildLimiter(POLICIES.UPLOAD);
const adminLimiter = buildLimiter(POLICIES.ADMIN);
const staffMutationLimiter = buildLimiter(POLICIES.STAFF_MUTATION);
const messageSendLimiter = buildLimiter(POLICIES.MESSAGE_SEND);
const smsPartnerSendLimiter = buildLimiter(POLICIES.SMS_SEND);
const stayCredentialIssueLimiter = buildLimiter(POLICIES.STAY_CREDENTIAL_ISSUE);
const stayCredentialResolveLimiter = buildLimiter(POLICIES.STAY_CREDENTIAL_RESOLVE);
const financialLimiter = paymentLimiter;

const authLimiter = authLoginLimiter;

module.exports = {
  globalLimiter,
  authLoginLimiter,
  authLoginAccountLimiter,
  authRegisterLimiter,
  authLimiter,
  paymentLimiter,
  financialLimiter,
  userLimiter,
  uploadLimiter,
  otpLimiter,
  otpSendPhoneLimiter,
  otpSendIpLimiter,
  authForgotPasswordLimiter,
  authForgotAccountLimiter,
  authVerifyCodeLimiter,
  smsPartnerSendLimiter,
  adminLimiter,
  staffMutationLimiter,
  messageSendLimiter,
  stayCredentialIssueLimiter,
  stayCredentialResolveLimiter,
  createStore,
  useMemoryStore,
  clientIpKey,
  subnetSafeIp,
  POLICIES,
  IPV6_SUBNET,
  buildLimiter,
  isWebhookPath,
};
