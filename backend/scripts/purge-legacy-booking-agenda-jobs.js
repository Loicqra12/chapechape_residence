/**
 * Purge les jobs Agenda legacy Booking (orphelins après retrait du modèle Booking).
 * Usage (depuis backend/) :
 *   node scripts/purge-legacy-booking-agenda-jobs.js
 *
 * Ne touche PAS aux jobs Reservation / payout / engagement.
 */
require('dotenv').config();
const mongoose = require('mongoose');

const LEGACY_JOB_NAMES = [
  'sendBookingReminder',
  'sendStatusChangeNotification',
  'sendPaymentReminderAfricaSpecific',
];

async function main() {
  const uri = process.env.MONGODB_URI || process.env.MONGO_URI;
  if (!uri) {
    console.error('MONGODB_URI manquant dans .env');
    process.exit(1);
  }

  await mongoose.connect(uri);
  const col = mongoose.connection.collection('agendaJobs');

  const before = await col.countDocuments({ name: { $in: LEGACY_JOB_NAMES } });
  const result = await col.deleteMany({ name: { $in: LEGACY_JOB_NAMES } });

  console.log(`Jobs Booking legacy trouvés: ${before}`);
  console.log(`Jobs Booking legacy supprimés: ${result.deletedCount}`);

  await mongoose.disconnect();
}

main().catch(async (err) => {
  console.error(err);
  try { await mongoose.disconnect(); } catch (_) {}
  process.exit(1);
});
