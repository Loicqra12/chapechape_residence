/**
 * Audit READ-ONLY des valeurs Reservation.status réellement persistées.
 * Aucun write. Ne migre rien.
 *
 * Usage :
 *   node scripts/audit-reservation-status.js
 *   node scripts/audit-reservation-status.js --json
 */
require('dotenv').config();
const mongoose = require('mongoose');
const {
  RESERVATION_STATUS_VALUES,
  LEGACY_ALIAS_VALUES,
} = require('../src/constants/reservation-status');

const maskMongoUri = (uri = '') => uri.replace(/:\/\/([^:]+):([^@]+)@/, '://$1:****@');

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('MONGODB_URI manquant — audit DB non exécuté');
    process.exit(2);
  }

  const asJson = process.argv.includes('--json');
  console.error('Audit Reservation.status read-only:', maskMongoUri(uri));
  await mongoose.connect(uri, { autoIndex: false });

  const Reservation = require('../src/models/reservation.model');
  const rows = await Reservation.aggregate([
    { $group: { _id: '$status', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);

  const canonical = {};
  const legacy = {};
  const other = {};
  for (const row of rows) {
    const status = row._id == null ? '(null)' : String(row._id);
    if (RESERVATION_STATUS_VALUES.includes(status)) {
      canonical[status] = row.count;
    } else if (LEGACY_ALIAS_VALUES.includes(status)) {
      legacy[status] = row.count;
    } else {
      other[status] = row.count;
    }
  }

  const report = {
    generatedAt: new Date().toISOString(),
    dryRun: true,
    totalDistinct: rows.length,
    canonical,
    legacy,
    other,
    rows,
  };

  if (asJson) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    console.log('\nCanonical:');
    for (const status of RESERVATION_STATUS_VALUES) {
      console.log(`  ${status}: ${canonical[status] || 0}`);
    }
    console.log('\nLegacy aliases:');
    if (Object.keys(legacy).length === 0) {
      console.log('  (none)');
    } else {
      for (const [status, count] of Object.entries(legacy)) {
        console.log(`  ${status}: ${count}`);
      }
    }
    console.log('\nOther / unexpected:');
    if (Object.keys(other).length === 0) {
      console.log('  (none)');
    } else {
      for (const [status, count] of Object.entries(other)) {
        console.log(`  ${status}: ${count}`);
      }
    }
  }

  await mongoose.disconnect();
  const hasLegacy = Object.keys(legacy).length > 0 || Object.keys(other).length > 0;
  process.exit(hasLegacy ? 1 : 0);
}

main().catch(async (err) => {
  console.error(err);
  try { await mongoose.disconnect(); } catch (_) { /* ignore */ }
  process.exit(1);
});
