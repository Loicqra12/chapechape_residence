/**
 * P2-07C — Vérification READ-ONLY de l'index unique arrival reminder.
 * Ne crée / ne supprime aucun index.
 *
 * Usage: node scripts/verify-arrival-reminder-index.js
 *
 * Sortie par index attendu:
 *   PRESENT | MISSING | MISMATCH
 *
 * Gate prod: P2-07C PROD AGENDA ARRIVAL INDEX GATE
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');
const {
  AGENDA_JOBS_COLLECTION,
  ARRIVAL_REMINDER_UNIQUE_INDEX,
  classifyArrivalReminderIndex,
} = require('../src/runtime/agenda-indexes');

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('RESULT: UNSAFE — MONGODB_URI manquant');
    process.exit(1);
  }

  const uriFp = fingerprintFromUri(uri);
  if (uriFp) {
    console.log('fingerprint(host|database):', uriFp.fingerprint);
  }

  await mongoose.connect(uri, { autoIndex: false });
  const indexes = await mongoose.connection.db.collection(AGENDA_JOBS_COLLECTION).indexes();

  console.log('P2-07C PROD AGENDA ARRIVAL INDEX GATE: PENDING');
  console.log('EXPECTED index:');
  console.log(JSON.stringify({
    name: ARRIVAL_REMINDER_UNIQUE_INDEX.name,
    key: ARRIVAL_REMINDER_UNIQUE_INDEX.key,
    unique: ARRIVAL_REMINDER_UNIQUE_INDEX.unique,
    partialFilterExpression: ARRIVAL_REMINDER_UNIQUE_INDEX.partialFilterExpression,
  }, null, 2));

  const result = classifyArrivalReminderIndex(indexes);
  console.log(`${ARRIVAL_REMINDER_UNIQUE_INDEX.name}: ${result.status} (${result.detail})`);

  if (result.index) {
    console.log('ACTUAL index:', JSON.stringify({
      name: result.index.name,
      key: result.index.key,
      unique: result.index.unique,
      partialFilterExpression: result.index.partialFilterExpression,
    }, null, 2));
  }

  await mongoose.disconnect();

  if (result.status === 'PRESENT') {
    console.log('RESULT: SAFE — index present and correct');
    process.exit(0);
  }
  console.error(`RESULT: UNSAFE — index ${result.status}`);
  process.exit(1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
