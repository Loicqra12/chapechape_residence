/**
 * Audit READ-ONLY des valeurs Notification.type réellement persistées.
 * Aucun write. Ne migre rien.
 *
 * Usage :
 *   node scripts/audit-notification-type-values.js
 *   node scripts/audit-notification-type-values.js --json
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');
const {
  ALLOWED_NOTIFICATION_TYPES,
  LEGACY,
  COMMON,
  PARTNER,
  CLIENT,
} = require('../src/utils/notification-types');

const maskMongoUri = (uri = '') => uri.replace(/:\/\/([^:]+):([^@]+)@/, '://$1:****@');

const LEGACY_VALUES = new Set(Object.values(LEGACY));
const CANONICAL_VALUES = new Set([
  ...Object.values(COMMON),
  ...Object.values(PARTNER),
  ...Object.values(CLIENT),
]);
const ALLOWED_SET = new Set(ALLOWED_NOTIFICATION_TYPES);

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('MONGODB_URI manquant — audit DB non exécuté');
    process.exit(2);
  }

  const asJson = process.argv.includes('--json');
  const uriFp = fingerprintFromUri(uri);
  if (uriFp) {
    console.error('fingerprint(host|database):', uriFp.fingerprint);
  }
  console.error('Audit Notification.type read-only:', maskMongoUri(uri));
  await mongoose.connect(uri, { autoIndex: false });

  const Notification = require('../src/models/notification.model');
  const rows = await Notification.aggregate([
    { $group: { _id: '$type', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);

  const table = rows.map((row) => {
    const type = row._id == null ? '(null)' : String(row._id);
    const canonical = CANONICAL_VALUES.has(type) ? 'YES' : 'NO';
    const legacy = LEGACY_VALUES.has(type) ? 'YES' : 'NO';
    let unknown = 'NO';
    if (!ALLOWED_SET.has(type)) {
      unknown = 'YES';
    }
    return {
      TYPE: type,
      COUNT: row.count,
      CANONICAL: canonical,
      LEGACY: legacy,
      UNKNOWN: unknown,
    };
  });

  const report = {
    generatedAt: new Date().toISOString(),
    dryRun: true,
    totalDistinct: rows.length,
    totalDocuments: rows.reduce((sum, r) => sum + r.count, 0),
    allowedEnumSize: ALLOWED_NOTIFICATION_TYPES.length,
    rows: table,
    unknownValues: table.filter((r) => r.UNKNOWN === 'YES'),
    legacyOnlyInDb: table.filter((r) => r.LEGACY === 'YES' && r.CANONICAL === 'NO'),
    canonicalOnlyInDb: table.filter((r) => r.CANONICAL === 'YES' && r.LEGACY === 'NO'),
  };

  if (asJson) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    console.log('\nTYPE\tCOUNT\tCANONICAL\tLEGACY\tUNKNOWN');
    for (const row of table) {
      console.log(
        `${row.TYPE}\t${row.COUNT}\t${row.CANONICAL}\t${row.LEGACY}\t${row.UNKNOWN}`
      );
    }
    console.log(`\nDistinct types: ${report.totalDistinct}`);
    console.log(`Total documents: ${report.totalDocuments}`);
    console.log(`Unknown values: ${report.unknownValues.length}`);
    if (report.unknownValues.length > 0) {
      console.log('Unexpected types (outside current enum):');
      for (const row of report.unknownValues) {
        console.log(`  ${row.TYPE}: ${row.COUNT}`);
      }
    }
  }

  await mongoose.disconnect();

  if (report.unknownValues.length > 0) {
    console.error(`RESULT: UNKNOWN_TYPES (${report.unknownValues.length}) — migration blocked`);
    process.exit(1);
  }
  console.log('RESULT: OK');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(3);
});
