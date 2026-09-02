function envInt(name, fallback) {
  const n = parseInt(process.env[name], 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
}

const MINUTE = 60 * 1000;
const WINDOW_15 = 15 * MINUTE;

/**
 * Policies centralisées (overridable via env). Pas de secrets.
 * ipv6Subnet : /64 (préfixe typique, évite l’explosion d’adresses).
 */
const POLICIES = {
  PUBLIC: {
    name: 'PUBLIC',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_PUBLIC', 600),
    failClosed: false,
    key: 'ip',
  },
  AUTH_LOGIN_IP: {
    name: 'AUTH_LOGIN_IP',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_AUTH_LOGIN_IP', 25),
    failClosed: false,
    key: 'ip',
  },
  AUTH_LOGIN_ACCOUNT: {
    name: 'AUTH_LOGIN_ACCOUNT',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_AUTH_LOGIN_ACCOUNT', 8),
    failClosed: false,
    key: 'account',
  },
  AUTH_REGISTER: {
    name: 'AUTH_REGISTER',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_AUTH_REGISTER', 40),
    failClosed: false,
    key: 'ip',
  },
  AUTH_FORGOT_IP: {
    name: 'AUTH_FORGOT_IP',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_AUTH_FORGOT_IP', 8),
    failClosed: false,
    key: 'ip',
  },
  AUTH_FORGOT_ACCOUNT: {
    name: 'AUTH_FORGOT_ACCOUNT',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_AUTH_FORGOT_ACCOUNT', 4),
    failClosed: false,
    key: 'account',
  },
  OTP_SEND_PHONE: {
    name: 'OTP_SEND_PHONE',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_OTP_SEND_PHONE', 4),
    failClosed: true,
    key: 'phone',
  },
  OTP_SEND_IP: {
    name: 'OTP_SEND_IP',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_OTP_SEND_IP', 20),
    failClosed: true,
    key: 'ip',
  },
  OTP_VERIFY: {
    name: 'OTP_VERIFY',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_OTP_VERIFY', 12),
    failClosed: true,
    key: 'phone',
  },
  AUTHENTICATED: {
    name: 'AUTHENTICATED',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_AUTHENTICATED', 400),
    failClosed: false,
    key: 'user',
  },
  FINANCIAL: {
    name: 'FINANCIAL',
    windowMs: MINUTE,
    max: envInt('RATE_LIMIT_FINANCIAL', 20),
    failClosed: true,
    key: 'user-or-ip',
  },
  ADMIN: {
    name: 'ADMIN',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_ADMIN', 400),
    failClosed: false,
    key: 'user-or-ip',
  },
  STAFF_MUTATION: {
    name: 'STAFF_MUTATION',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_STAFF_MUTATION', 30),
    failClosed: true,
    key: 'user-or-ip',
  },
  UPLOAD: {
    name: 'UPLOAD',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_UPLOAD', 40),
    failClosed: false,
    key: 'user-or-ip',
  },
  MESSAGE_SEND: {
    name: 'MESSAGE_SEND',
    windowMs: MINUTE,
    max: envInt('RATE_LIMIT_MESSAGE_SEND', 30),
    failClosed: false,
    key: 'user-or-ip',
  },
  SMS_SEND: {
    name: 'SMS_SEND',
    windowMs: 60 * MINUTE,
    max: envInt('SMS_SEND_MAX_PER_HOUR', 40),
    failClosed: false,
    key: 'user-or-ip',
  },
  STAY_CREDENTIAL_ISSUE: {
    name: 'STAY_CREDENTIAL_ISSUE',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_STAY_CREDENTIAL_ISSUE', 20),
    failClosed: false,
    key: 'user-or-ip',
  },
  STAY_CREDENTIAL_RESOLVE: {
    name: 'STAY_CREDENTIAL_RESOLVE',
    windowMs: WINDOW_15,
    max: envInt('RATE_LIMIT_STAY_CREDENTIAL_RESOLVE', 60),
    failClosed: false,
    key: 'user-or-ip',
  },
};

const IPV6_SUBNET = envInt('RATE_LIMIT_IPV6_SUBNET', 64);

module.exports = { POLICIES, IPV6_SUBNET, envInt };
