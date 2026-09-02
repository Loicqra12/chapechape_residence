const { shouldCaptureSentry } = require('./http-error-policy');

function readDsn(env = process.env) {
  const dsn = typeof env.SENTRY_DSN === 'string' ? env.SENTRY_DSN.trim() : '';
  if (!dsn || dsn === 'your-sentry-dsn-here') return undefined;
  if (!/^https:\/\//i.test(dsn)) return undefined;
  return dsn;
}

function stripSensitiveRequest(event) {
  if (!event.request) return;
  if (event.request.headers) {
    delete event.request.headers.authorization;
    delete event.request.headers.cookie;
    delete event.request.headers['x-csrf-token'];
  }
  if (event.request.data && typeof event.request.data === 'object') {
    delete event.request.data.password;
    delete event.request.data.token;
    delete event.request.data.refreshToken;
    delete event.request.data.otp;
  }
}

function buildSentryInitOptions(env = process.env) {
  const dsn = readDsn(env);
  const isTest = env.NODE_ENV === 'test';

  return {
    dsn,
    enabled: Boolean(dsn) && !isTest,
    environment: env.NODE_ENV || 'development',
    release: env.npm_package_version || '1.0.0',
    tracesSampleRate: env.NODE_ENV === 'production' ? 0.1 : 1.0,
    sendDefaultPii: false,
    beforeSend(event, hint) {
      const original = hint?.originalException;
      if (original && !shouldCaptureSentry(original)) {
        return null;
      }
      stripSensitiveRequest(event);
      return event;
    },
    initialScope: {
      tags: {
        component: 'backend',
        service: 'chapechape-residences',
      },
    },
    maxBreadcrumbs: 50,
    maxValueLength: 250,
    captureUnhandledRejections: false,
    autoSessionTracking: Boolean(dsn) && !isTest,
  };
}

module.exports = {
  readDsn,
  buildSentryInitOptions,
};
