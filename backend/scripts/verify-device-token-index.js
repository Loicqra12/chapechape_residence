/**
 * Vérification READ-ONLY de l'index unique deviceTokens (P2-06C).
 * Ne crée ni ne supprime aucun index.
 *
 * Usage:
 *   node scripts/verify-device-token-index.js
 *
 * exit 0 = PRESENT (conforme)
 * exit 1 = MISSING / MISMATCH
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');

const EXPECTED = {
  name: 'deviceTokens_subscription_unique',
  key: { deviceTokens: 1 },
  unique: true,
  partialFilterExpression: { 'deviceTokens.0': { $exists: true } },
};

function indexMatches(expected, actual) {
  if (!actual.unique) return false;
  if (actual.key?.deviceTokens !== 1) return false;
  const partial = actual.partialFilterExpression || {};
  return partial['deviceTokens.0']?.$exists === true;
}

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('INDEX_STATUS: ERROR');
    console.error('MONGODB_URI manquant');
    process.exit(1);
  }

  const uriFp = fingerprintFromUri(uri);
  if (uriFp) {
    console.log('fingerprint(host|database):', uriFp.fingerprint);
  }

  await mongoose.connect(uri, { autoIndex: false });
  const indexes = await mongoose.connection.db.collection('users').indexes();

  const named = indexes.find((idx) => idx.name === EXPECTED.name);
  const byShape = indexes.find((idx) => indexMatches(EXPECTED, idx));

  let status = 'MISSING';
  if (named && indexMatches(EXPECTED, named)) {
    status = 'PRESENT';
  } else if (byShape && !named) {
    status = 'MISMATCH';
  } else if (byShape) {
    status = 'MISMATCH';
  }

  console.log('EXPECTED:', JSON.stringify(EXPECTED));
  console.log('INDEX_STATUS:', status);
  if (named) {
    console.log('FOUND:', JSON.stringify(named));
  } else if (byShape) {
    console.log('FOUND_SHAPE:', JSON.stringify(byShape));
  }

  await mongoose.disconnect();
  process.exit(status === 'PRESENT' ? 0 : 1);
}

main().catch((err) => {
  console.error('INDEX_STATUS: ERROR');
  console.error(err);
  process.exit(1);
});
