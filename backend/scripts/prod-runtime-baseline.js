/**
 * Baseline runtime production — AUCUN secret affiché.
 *
 * Sur le droplet (env PM2) :
 *   cd backend
 *   node scripts/prod-runtime-baseline.js
 *
 * Comparer mongo fingerprint à EXPECTED_PROD_MONGO_FINGERPRINT (prod-constants.js)
 * Si différent : NE PAS créer d'indexes. Audits read-only uniquement.
 */
require('dotenv').config();
const { execSync } = require('child_process');
const os = require('os');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');
const { EXPECTED_PROD_MONGO_FINGERPRINT } = require('../src/runtime/prod-constants');
const { configPresence } = require('../src/runtime/config-presence');
const { isPrimaryScheduler, workerLabel } = require('../src/runtime/agenda-cluster');

function safeExec(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
  } catch (err) {
    return null;
  }
}

function main() {
  const fp = fingerprintFromUri(process.env.MONGODB_URI);
  const match = fp && fp.fingerprint === EXPECTED_PROD_MONGO_FINGERPRINT;
  const git = process.env.GIT_COMMIT || safeExec('git rev-parse HEAD');
  const gitShort = git ? String(git).slice(0, 12) : null;

  const report = {
    generatedAt: new Date().toISOString(),
    hostname: os.hostname(),
    node: process.version,
    platform: `${os.platform()} ${os.release()}`,
    pm2: {
      version: safeExec('pm2 -v'),
      worker: workerLabel(),
      nodeAppInstance: process.env.NODE_APP_INSTANCE || null,
      primaryScheduler: isPrimaryScheduler(),
    },
    process: {
      NODE_ENV: process.env.NODE_ENV || null,
      PORT: process.env.PORT || null,
      pid: process.pid,
      uptimeSec: Math.round(process.uptime()),
    },
    gitCommit: gitShort,
    mongo: fp
      ? {
          host: fp.host,
          database: fp.database,
          fingerprint: fp.fingerprint,
          expected: EXPECTED_PROD_MONGO_FINGERPRINT,
          match,
        }
      : { fingerprint: null, expected: EXPECTED_PROD_MONGO_FINGERPRINT, match: false },
    redisConfigured: Boolean(process.env.REDIS_URL && String(process.env.REDIS_URL).trim()),
    agendaDisabled: process.env.DISABLE_AGENDA === 'true',
    configPresence: configPresence(),
    verdict: match ? 'P0_FINGERPRINT_MATCH' : 'P0_PROD_ENVIRONMENT_MISMATCH',
    next: match
      ? [
          'node scripts/verify-inventory-indexes.js',
          'node scripts/audit-reservation-consistency.js',
          'node scripts/audit-blocked-dates.js',
          'npm run audit:reservation-status',
        ]
      : [
          'NE PAS créer d\'indexes',
          'fingerprint → verify read-only → data audits → compare → plan de migration',
        ],
  };

  console.log(JSON.stringify(report, null, 2));
  process.exit(match ? 0 : 2);
}

main();
