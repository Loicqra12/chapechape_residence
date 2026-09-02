/**
 * Read-only : listings publiés / legacy dont le Partner n’a pas le téléphone vérifié.
 * Aucune écriture. Ne crée pas d’index.
 *
 * Usage : node scripts/audit-published-unverified-phone.js
 */
require('dotenv').config();
const mongoose = require('mongoose');

async function main() {
  const uri = process.env.MONGODB_URI || process.env.MONGO_URI;
  if (!uri) {
    console.error('MONGODB_URI manquant');
    process.exit(1);
  }
  await mongoose.connect(uri);
  const db = mongoose.connection.db;
  const residences = db.collection('residences');
  const users = db.collection('users');

  const listed = await residences.find({
    deleted: { $ne: true },
    $or: [
      { publicationStatus: 'published' },
      { publicationStatus: { $exists: false } },
    ],
  }, { projection: { partner: 1, title: 1, publicationStatus: 1 } }).toArray();

  const partnerIds = [...new Set(listed.map((r) => String(r.partner)).filter(Boolean))];
  const partners = await users.find({
    _id: { $in: partnerIds.map((id) => new mongoose.Types.ObjectId(id)) },
  }, { projection: { email: 1, isPhoneVerified: 1, role: 1 } }).toArray();

  const unverified = new Map(
    partners.filter((u) => !u.isPhoneVerified).map((u) => [String(u._id), u])
  );

  const rows = listed.filter((r) => unverified.has(String(r.partner)));
  console.log(JSON.stringify({
    listedCount: listed.length,
    unverifiedPartnerPublishedCount: rows.length,
    sample: rows.slice(0, 20).map((r) => ({
      residenceId: String(r._id),
      title: r.title,
      publicationStatus: r.publicationStatus ?? '(legacy absent)',
      partnerId: String(r.partner),
      partnerEmail: unverified.get(String(r.partner))?.email,
    })),
  }, null, 2));
  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
