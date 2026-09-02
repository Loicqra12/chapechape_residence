/**
 * Audit read-only : Users role=partner vs discriminator Partner + documents.
 * Ne crée aucun index. Ne migrate rien.
 *
 *   node scripts/audit-partner-discriminator.js
 *
 * Classes :
 *   user_only_no_docs          — User partner sans doc Partner (accès documents non nécessaire)
 *   partner_disc_with_docs     — discriminator OK, documents liés
 *   partner_disc_no_docs       — discriminator OK, pas de documents
 *   user_with_orphan_doc_urls  — documents ailleurs (à adapter ciblé)
 */
require('dotenv').config();
const mongoose = require('mongoose');
const { fingerprintFromUri } = require('../src/utils/mongo-fingerprint');

const EXPECTED_FINGERPRINT = 'efebb871c934cf3c';

async function main() {
  const uri = process.env.MONGODB_URI || process.env.MONGO_URI;
  if (!uri) {
    console.log(JSON.stringify({
      skipped: true,
      reason: 'MONGODB_URI absent — pas de connexion',
    }, null, 2));
    return;
  }

  const parsed = fingerprintFromUri(uri);
  const fp = parsed?.fingerprint || null;
  console.error(`mongo fingerprint: ${fp} (attendu prod ${EXPECTED_FINGERPRINT})`);

  await mongoose.connect(uri, { serverSelectionTimeoutMS: 8000 });
  const db = mongoose.connection.db;
  const users = db.collection('users');

  const partners = await users.find(
    { role: { $in: ['partner', 'partner_pending'] } },
    { projection: { email: 1, role: 1, documents: 1, __t: 1, company: 1 } }
  ).toArray();

  const classes = {
    user_only_no_docs: 0,
    partner_disc_with_docs: 0,
    partner_disc_no_docs: 0,
    user_with_orphan_doc_urls: 0,
  };

  for (const u of partners) {
    const isDisc = u.__t === 'Partner' || !!u.company;
    const docs = Array.isArray(u.documents) ? u.documents : [];
    const hasDocs = docs.length > 0;
    if (isDisc && hasDocs) classes.partner_disc_with_docs += 1;
    else if (isDisc && !hasDocs) classes.partner_disc_no_docs += 1;
    else if (!isDisc && hasDocs) classes.user_with_orphan_doc_urls += 1;
    else classes.user_only_no_docs += 1;
  }

  console.log(JSON.stringify({
    generatedAt: new Date().toISOString(),
    fingerprint: fp,
    productionFingerprintMatch: fp === EXPECTED_FINGERPRINT,
    totalRolePartner: partners.length,
    classes,
    recommendation:
      classes.user_with_orphan_doc_urls === 0
        ? 'Aucun document orphelin hors discriminator — garder le 403 fail-closed.'
        : 'Des documents existent hors discriminator Partner — adaptation ciblée, ne pas ouvrir le folder documents à tout partner.',
  }, null, 2));

  await mongoose.disconnect();
}

main().catch(async (err) => {
  console.error(err.message);
  try { await mongoose.disconnect(); } catch (_) { /* ignore */ }
  process.exit(1);
});
