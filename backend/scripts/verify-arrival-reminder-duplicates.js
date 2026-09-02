/**
 * P2-07C — Audit READ-ONLY des doublons sendReservationReminder par data.reservationId.
 * Ne mute jamais la collection.
 *
 * Usage: node scripts/verify-arrival-reminder-duplicates.js
 *
 * Sortie:
 *   UNIQUE
 *   ou DUPLICATE + détails par reservationId
 *   ou INDEX CREATION BLOCKED (si doublons détectés)
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');
const {
  AGENDA_JOBS_COLLECTION,
  ARRIVAL_REMINDER_JOB_NAME,
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
  const col = mongoose.connection.db.collection(AGENDA_JOBS_COLLECTION);

  const pipeline = [
    { $match: { name: ARRIVAL_REMINDER_JOB_NAME } },
    {
      $group: {
        _id: '$data.reservationId',
        count: { $sum: 1 },
        jobIds: { $push: '$_id' },
        nextRunAt: { $push: '$nextRunAt' },
        lockedAt: { $push: '$lockedAt' },
        lastRunAt: { $push: '$lastRunAt' },
        lastFinishedAt: { $push: '$lastFinishedAt' },
        failedAt: { $push: '$failedAt' },
        disabled: { $push: '$disabled' },
      },
    },
    { $match: { count: { $gt: 1 } } },
    { $sort: { count: -1 } },
  ];

  const duplicates = await col.aggregate(pipeline).toArray();

  if (duplicates.length === 0) {
    console.log('RESULT: UNIQUE');
    await mongoose.disconnect();
    process.exit(0);
  }

  console.log('RESULT: DUPLICATE');
  console.log('INDEX CREATION BLOCKED');
  for (const dup of duplicates) {
    console.log(JSON.stringify({
      reservationId: dup._id,
      count: dup.count,
      jobIds: dup.jobIds.map(String),
      nextRunAt: dup.nextRunAt,
      lockedAt: dup.lockedAt,
      lastRunAt: dup.lastRunAt,
      lastFinishedAt: dup.lastFinishedAt,
      failedAt: dup.failedAt,
      disabled: dup.disabled,
    }));
  }

  await mongoose.disconnect();
  process.exit(1);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
