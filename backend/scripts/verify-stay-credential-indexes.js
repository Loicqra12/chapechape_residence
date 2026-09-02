/**
 * Vérification READ-ONLY des indexes stay credential (P2-05C2).
 * Ne crée / ne supprime aucun index.
 *
 * Usage: node scripts/verify-stay-credential-indexes.js
 *
 * Sortie par index:
 *   EXPECTED | PRESENT | MISSING | MISMATCH
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');

const EXPECTED = [
  {
    name: 'stay_cred_checkin_hash_unique',
    key: { 'stayCredentials.checkIn.tokenHash': 1 },
    unique: true,
    partialField: 'stayCredentials.checkIn.tokenHash',
  },
  {
    name: 'stay_cred_checkout_hash_unique',
    key: { 'stayCredentials.checkOut.tokenHash': 1 },
    unique: true,
    partialField: 'stayCredentials.checkOut.tokenHash',
  },
];

function classifyIndex(indexes, expected) {
  const byName = indexes.find((idx) => idx.name === expected.name);
  const byKey = indexes.find(
    (idx) =>
      idx.key
      && idx.key[expected.partialField] === 1
      && Object.keys(idx.key).length === 1
  );

  if (!byName && !byKey) {
    return { status: 'MISSING', detail: 'index absent' };
  }

  const idx = byName || byKey;
  const problems = [];
  if (!idx.unique) problems.push('not unique');
  if (byName && byKey && byName.name !== byKey.name && byName !== byKey) {
    // same logical key under different name — still ok if unique+partial
  }
  if (idx.name !== expected.name) problems.push(`name=${idx.name}`);

  const pfe = idx.partialFilterExpression;
  const sparse = idx.sparse === true;
  const hasPartialString =
    pfe
    && pfe[expected.partialField]
    && (pfe[expected.partialField].$type === 'string'
      || (Array.isArray(pfe[expected.partialField].$type)
        && pfe[expected.partialField].$type.includes('string')));

  if (!hasPartialString && !sparse) {
    problems.push('missing partialFilterExpression($type:string) and not sparse');
  } else if (!hasPartialString && sparse) {
    problems.push('sparse without partialFilterExpression($type:string) — null collision risk');
  }

  if (problems.length) {
    return { status: 'MISMATCH', detail: problems.join('; ') };
  }
  return { status: 'PRESENT', detail: hasPartialString ? 'partial unique' : 'sparse unique' };
}

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
  const indexes = await mongoose.connection.db.collection('reservations').indexes();

  console.log('EXPECTED indexes:');
  for (const exp of EXPECTED) {
    console.log(`  - ${exp.name} unique partial on ${exp.partialField}`);
  }

  let unsafe = false;
  for (const exp of EXPECTED) {
    const result = classifyIndex(indexes, exp);
    console.log(`${exp.name}: ${result.status} (${result.detail})`);
    if (result.status !== 'PRESENT') unsafe = true;
  }

  await mongoose.disconnect();
  if (unsafe) {
    console.error('RESULT: UNSAFE — indexes stay credential incomplets (création Ops séparée)');
    process.exit(1);
  }
  console.log('RESULT: SAFE');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
