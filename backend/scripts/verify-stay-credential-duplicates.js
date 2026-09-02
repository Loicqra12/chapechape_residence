/**
 * P2-09B0 — Audit READ-ONLY des doublons stay credential tokenHash (P2-05C2).
 * Population identique aux partial unique indexes (string only).
 *
 * Usage: node scripts/verify-stay-credential-duplicates.js
 *
 * exit 0 = UNIQUE (check-in + check-out)
 * exit 1 = DUPLICATE détecté
 * exit 2 = MONGODB_URI manquant
 * exit 3 = erreur connexion / runtime
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');

/** Aligné sur reservation.model.js partialFilterExpression */
const FIELDS = Object.freeze({
  checkIn: {
    label: 'CHECKIN_HASHES',
    path: 'stayCredentials.checkIn.tokenHash',
    eligibleMatch: { 'stayCredentials.checkIn.tokenHash': { $exists: true, $type: 'string' } },
    groupId: '$stayCredentials.checkIn.tokenHash',
  },
  checkOut: {
    label: 'CHECKOUT_HASHES',
    path: 'stayCredentials.checkOut.tokenHash',
    eligibleMatch: { 'stayCredentials.checkOut.tokenHash': { $exists: true, $type: 'string' } },
    groupId: '$stayCredentials.checkOut.tokenHash',
  },
});

function maskHash(value) {
  const s = String(value);
  if (s.length <= 12) return `${s.slice(0, 2)}…${s.slice(-2)}`;
  return `${s.slice(0, 4)}…${s.slice(-4)}`;
}

async function auditField(collection, spec) {
  const eligibleCount = await collection.countDocuments(spec.eligibleMatch);

  const duplicateGroups = await collection.aggregate([
    { $match: spec.eligibleMatch },
    {
      $group: {
        _id: spec.groupId,
        count: { $sum: 1 },
        reservationIds: { $push: '$_id' },
      },
    },
    { $match: { count: { $gt: 1 } } },
    { $sort: { count: -1 } },
    { $limit: 20 },
  ]).toArray();

  const uniqueGroups = await collection.aggregate([
    { $match: spec.eligibleMatch },
    { $group: { _id: spec.groupId } },
    { $count: 'n' },
  ]).toArray();

  const uniqueCount = uniqueGroups[0]?.n || 0;
  const duplicateValueCount = duplicateGroups.length;
  const duplicateDocumentCount = duplicateGroups.reduce((sum, g) => sum + g.count, 0);

  console.log(spec.label);
  console.log(`eligible count: ${eligibleCount}`);
  console.log(`unique count: ${uniqueCount}`);
  console.log(`duplicate value count: ${duplicateValueCount}`);
  console.log(`duplicate document count: ${duplicateDocumentCount}`);
  console.log(`RESULT: ${duplicateValueCount === 0 ? 'UNIQUE' : 'DUPLICATE'}`);

  if (duplicateValueCount > 0) {
    console.log('duplicate samples (masked hash, reservation count):');
    for (const group of duplicateGroups.slice(0, 5)) {
      console.log(JSON.stringify({
        hash: maskHash(group._id),
        documentCount: group.count,
        reservationIds: group.reservationIds.slice(0, 3).map(String),
      }));
    }
  }

  console.log('');
  return duplicateValueCount === 0;
}

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('RESULT: ERROR — MONGODB_URI manquant');
    process.exit(2);
  }

  const uriFp = fingerprintFromUri(uri);
  if (uriFp) {
    console.log('fingerprint(host|database):', uriFp.fingerprint);
  }

  await mongoose.connect(uri, { autoIndex: false });
  const collection = mongoose.connection.db.collection('reservations');

  const checkInOk = await auditField(collection, FIELDS.checkIn);
  const checkOutOk = await auditField(collection, FIELDS.checkOut);

  await mongoose.disconnect();

  if (checkInOk && checkOutOk) {
    console.log('OVERALL: UNIQUE');
    process.exit(0);
  }
  console.error('OVERALL: DUPLICATE — index creation blocked');
  process.exit(1);
}

main().catch(async (err) => {
  console.error('RESULT: ERROR');
  console.error(err.message || err);
  try {
    await mongoose.disconnect();
  } catch (_) {
    /* ignore */
  }
  process.exit(3);
});
