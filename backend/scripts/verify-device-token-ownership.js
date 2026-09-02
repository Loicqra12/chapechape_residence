/**
 * Audit READ-ONLY — un subscription ID ne doit appartenir qu'à un seul User.
 *
 * Usage:
 *   node scripts/verify-device-token-ownership.js
 *
 * exit 0 = UNIQUE (aucun duplicate)
 * exit 1 = DUPLICATE détecté ou erreur
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('RESULT: ERROR');
    console.error('MONGODB_URI manquant');
    process.exit(1);
  }

  const uriFp = fingerprintFromUri(uri);
  if (uriFp) {
    console.log('uri.host:', uriFp.host);
    console.log('uri.database:', uriFp.database);
    console.log('fingerprint(host|database):', uriFp.fingerprint);
  }

  await mongoose.connect(uri, { autoIndex: false });
  const db = mongoose.connection.db;

  const pipeline = [
    { $match: { deviceTokens: { $exists: true, $ne: [] } } },
    { $unwind: '$deviceTokens' },
    {
      $group: {
        _id: '$deviceTokens',
        userIds: { $addToSet: '$_id' },
        count: { $sum: 1 },
      },
    },
    { $match: { count: { $gt: 1 } } },
    { $sort: { count: -1 } },
    { $limit: 50 },
  ];

  const duplicates = await db.collection('users').aggregate(pipeline).toArray();
  const totalUsersWithTokens = await db.collection('users').countDocuments({
    'deviceTokens.0': { $exists: true },
  });

  console.log('users_with_device_tokens:', totalUsersWithTokens);
  console.log('duplicate_subscription_ids:', duplicates.length);

  if (duplicates.length > 0) {
    console.log('RESULT: DUPLICATE');
    for (const row of duplicates.slice(0, 10)) {
      console.log(JSON.stringify({
        subscriptionIdSuffix: String(row._id).slice(-8),
        ownerCount: row.userIds.length,
        userIds: row.userIds.map(String),
      }));
    }
    await mongoose.disconnect();
    process.exit(1);
  }

  console.log('RESULT: UNIQUE');
  await mongoose.disconnect();
  process.exit(0);
}

main().catch((err) => {
  console.error('RESULT: ERROR');
  console.error(err);
  process.exit(1);
});
