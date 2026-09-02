const crypto = require('crypto');

function parseMongoTarget(uri) {
  if (!uri) return null;
  const normalized = uri
    .replace(/^mongodb\+srv:\/\//i, 'https://')
    .replace(/^mongodb:\/\//i, 'http://');
  let parsed;
  try {
    parsed = new URL(normalized);
  } catch (err) {
    return null;
  }
  const host = parsed.hostname;
  const database = decodeURIComponent((parsed.pathname || '').replace(/^\//, '').split('?')[0] || '') || 'test';
  return { host, database };
}

function fingerprintHostDb(host, database) {
  return crypto.createHash('sha256').update(`${host}|${database}`).digest('hex').slice(0, 16);
}

function fingerprintFromUri(uri) {
  const target = parseMongoTarget(uri);
  if (!target) return null;
  return {
    host: target.host,
    database: target.database,
    fingerprint: fingerprintHostDb(target.host, target.database),
  };
}

module.exports = { parseMongoTarget, fingerprintHostDb, fingerprintFromUri };
