/**
 * Empreinte Mongo sans secret : hash(host SRV | database) à partir de MONGODB_URI.
 * N'affiche jamais user/password. Ne se connecte pas. Ne crée aucun index.
 *
 * Sur le droplet (env du process PM2) :
 *   node scripts/fingerprint-mongo-env.js
 *
 * exit 0 = match EXPECTED_PROD_MONGO_FINGERPRINT → ensuite verify-inventory-indexes.js (read-only)
 * exit 2 = P0_PROD_ENVIRONMENT_MISMATCH → aucun index auto, plan de migration
 */
require('dotenv').config();
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');
const { EXPECTED_PROD_MONGO_FINGERPRINT } = require('../src/runtime/prod-constants');

const info = fingerprintFromUri(process.env.MONGODB_URI);
if (!info) {
  console.error('MONGODB_URI manquant ou illisible');
  process.exit(1);
}

const match = info.fingerprint === EXPECTED_PROD_MONGO_FINGERPRINT;
console.log('host:', info.host);
console.log('database:', info.database);
console.log('fingerprint(host|database):', info.fingerprint);
console.log('expected:', EXPECTED_PROD_MONGO_FINGERPRINT);
console.log('match:', match);
if (!match) {
  console.error('P0_PROD_ENVIRONMENT_MISMATCH — ne pas créer d\'indexes');
  console.error('Suite: fingerprint → verify read-only → data audits → compare → plan de migration');
  process.exit(2);
}
console.log('P0_FINGERPRINT_MATCH — poursuivre: node scripts/verify-inventory-indexes.js');
