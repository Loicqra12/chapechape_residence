/**
 * Audit READ-ONLY de l'ancien Residence.blockedDates (LEGACY, hors schéma).
 * Usage : node scripts/audit-blocked-dates.js
 */
require('dotenv').config();
const mongoose = require('mongoose');

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('MONGODB_URI manquant');
    process.exit(1);
  }
  await mongoose.connect(uri, { autoIndex: false });
  const residences = mongoose.connection.db.collection('residences');
  const withField = await residences.countDocuments({
    blockedDates: { $exists: true, $nin: [null, []] },
  });
  const sample = await residences.find(
    { blockedDates: { $exists: true, $nin: [null, []] } },
    { projection: { _id: 1, title: 1, blockedDates: 1 } }
  ).limit(10).toArray();

  console.log('Residences with non-empty blockedDates:', withField);
  console.log('sample:', JSON.stringify(sample, null, 2));
  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
