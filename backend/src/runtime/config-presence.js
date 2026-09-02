/**
 * P2-01 — présence de configuration (booléens uniquement, jamais les valeurs).
 */
const SECRET_KEYS = [
  'JWT_SECRET',
  'MONGODB_URI',
  'REDIS_URL',
  'WAVE_API_KEY',
  'WAVE_SIGNING_SECRET',
  'WAVE_WEBHOOK_SECRET',
  'CINETPAY_API_KEY',
  'CINETPAY_SITE_ID',
  'STRIPE_SECRET_KEY',
  'SENTRY_DSN',
  'ONESIGNAL_APP_ID',
  'ONESIGNAL_API_KEY',
  'BREVO_API_KEY',
  'TWILIO_ACCOUNT_SID',
  'TWILIO_AUTH_TOKEN',
  'CLOUDINARY_API_SECRET',
  'CLOUDINARY_API_KEY',
];

const PUBLIC_KEYS = [
  'NODE_ENV',
  'PORT',
  'DISABLE_AGENDA',
  'REDIS_REQUIRED',
  'SYNC_INVENTORY_LOCK_INDEXES',
  'TRUST_PROXY_HOPS',
  'FRONTEND_URL',
  'CLIENT_URL',
  'SOCKET_CORS_ORIGIN',
  'GIT_COMMIT',
];

function isSet(key) {
  const value = process.env[key];
  return Boolean(value && String(value).trim());
}

function configPresence() {
  const secrets = {};
  for (const key of SECRET_KEYS) {
    secrets[key] = isSet(key);
  }
  const publicEnv = {};
  for (const key of PUBLIC_KEYS) {
    if (key === 'PORT' || key === 'NODE_ENV' || key === 'GIT_COMMIT' || key === 'DISABLE_AGENDA') {
      publicEnv[key] = process.env[key] || null;
    } else {
      publicEnv[key] = isSet(key) ? (['PORT', 'NODE_ENV', 'GIT_COMMIT', 'DISABLE_AGENDA', 'TRUST_PROXY_HOPS'].includes(key)
        ? process.env[key]
        : true) : false;
    }
  }
  return {
    secretsConfigured: secrets,
    public: {
      NODE_ENV: process.env.NODE_ENV || null,
      PORT: process.env.PORT || null,
      DISABLE_AGENDA: process.env.DISABLE_AGENDA || null,
      REDIS_REQUIRED: process.env.REDIS_REQUIRED || null,
      SYNC_INVENTORY_LOCK_INDEXES: process.env.SYNC_INVENTORY_LOCK_INDEXES || null,
      TRUST_PROXY_HOPS: process.env.TRUST_PROXY_HOPS || null,
      GIT_COMMIT: process.env.GIT_COMMIT || null,
      FRONTEND_URL: isSet('FRONTEND_URL'),
      CLIENT_URL: isSet('CLIENT_URL'),
      SOCKET_CORS_ORIGIN: isSet('SOCKET_CORS_ORIGIN'),
      HTTPS_HINT: isSet('FRONTEND_URL') && String(process.env.FRONTEND_URL || '').startsWith('https'),
    },
  };
}

module.exports = { SECRET_KEYS, PUBLIC_KEYS, isSet, configPresence };
