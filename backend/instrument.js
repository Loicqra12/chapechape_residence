
/**
 * Instrument.js - Initialisation précoce de Sentry
 * IMPORTANT: Ce fichier doit être importé en premier dans server.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '.env') });

const Sentry = require('@sentry/node');
const { buildSentryInitOptions } = require('./src/observability/sentry-init');

const options = buildSentryInitOptions(process.env);

if (options.enabled) {
  options.integrations = [
    Sentry.httpIntegration(),
    Sentry.expressIntegration(),
    Sentry.mongoIntegration(),
    Sentry.nodeContextIntegration(),
  ];
}

Sentry.init(options);
