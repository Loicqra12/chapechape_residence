/**
 * Rapport détaillé READ-ONLY des incohérences Reservation (pré-P1).
 * Aucune écriture.
 *
 * Usage : node scripts/audit-reservation-details.js
 */
require('dotenv').config();
const mongoose = require('mongoose');

const BLOCKING = ['pending', 'awaiting_approval', 'payment_pending', 'confirmed', 'in_stay'];

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('MONGODB_URI manquant');
    process.exit(1);
  }

  await mongoose.connect(uri, { autoIndex: false });
  const Reservation = require('../src/models/reservation.model');
  const Payment = require('../src/models/payment.model');
  const Availability = require('../src/models/availability.model');
  const User = require('../src/models/user.model');
  const Residence = require('../src/models/residence.model');

  const overlapsRaw = await Reservation.aggregate([
    { $match: { status: { $in: BLOCKING } } },
    {
      $lookup: {
        from: 'reservations',
        let: { rid: '$residence', cin: '$checkIn', cout: '$checkOut', id: '$_id' },
        pipeline: [
          {
            $match: {
              $expr: {
                $and: [
                  { $eq: ['$residence', '$$rid'] },
                  { $in: ['$status', BLOCKING] },
                  { $lt: ['$checkIn', '$$cout'] },
                  { $gt: ['$checkOut', '$$cin'] },
                  { $ne: ['$_id', '$$id'] },
                ],
              },
            },
          },
          { $project: { _id: 1 } },
        ],
        as: 'overlaps',
      },
    },
    { $match: { 'overlaps.0': { $exists: true } } },
  ]);

  const pairKey = (a, b) => [String(a), String(b)].sort().join('|');
  const pairs = new Map();
  for (const row of overlapsRaw) {
    for (const o of row.overlaps) {
      pairs.set(pairKey(row._id, o._id), [row._id, o._id]);
    }
  }

  async function loadReservationBundle(id) {
    const r = await Reservation.findById(id).lean();
    if (!r) return { missing: true, id };
    const [client, partner, residence, payments, avail] = await Promise.all([
      User.findById(r.user).select('email firstName lastName role createdAt').lean(),
      User.findById(r.partner).select('email firstName lastName role').lean(),
      Residence.findById(r.residence).select('title city reservationMode').lean(),
      Payment.find({ reservation: r._id }).select('status amount paymentProvider transactionId refundStatus createdAt').lean(),
      Availability.find({ reservationId: r._id }).select('date status').lean(),
    ]);
    return {
      reservationId: r._id,
      residenceId: r.residence,
      residenceTitle: residence?.title,
      client: client ? { id: client._id, email: client.email, name: `${client.firstName || ''} ${client.lastName || ''}`.trim() } : null,
      partner: partner ? { id: partner._id, email: partner.email, name: `${partner.firstName || ''} ${partner.lastName || ''}`.trim() } : null,
      checkIn: r.checkIn,
      checkOut: r.checkOut,
      status: r.status,
      paymentStatus: r.paymentStatus,
      bookingType: r.bookingType || null,
      createdAt: r.createdAt,
      paymentDeadline: r.paymentDeadline || null,
      payments,
      availabilityCount: avail.length,
    };
  }

  console.log('=== 1. OVERLAPS BLOQUANTS (paires uniques) ===\n');
  let pairIndex = 0;
  for (const [a, b] of pairs.values()) {
    pairIndex += 1;
    const [left, right] = await Promise.all([loadReservationBundle(a), loadReservationBundle(b)]);
    const emails = [left.client?.email, right.client?.email].filter(Boolean);
    const looksTest = emails.every((e) => /test|example|chapechape/i.test(e || ''))
      || emails.some((e) => /test@|example\.com/i.test(e || ''));
    const anyPaid = [...(left.payments || []), ...(right.payments || [])].some((p) => p.status === 'paid');
    let classification = 'INCONNU — arbitrage manuel';
    if (looksTest) classification = 'probable donnée de test (emails)';
    else if (!anyPaid && [left.status, right.status].every((s) => s === 'payment_pending')) {
      classification = 'holds payment_pending sans paiement — candidats expiration, pas client débité';
    } else if (anyPaid) {
      classification = 'AU MOINS UN PAIEMENT paid — danger client réel, ne pas auto-cancel';
    }
    console.log(`--- Paire ${pairIndex} ---`);
    console.log('classification:', classification);
    console.log(JSON.stringify({ A: left, B: right }, null, 2));
    console.log('');
  }

  const active = await Reservation.find({ status: { $in: BLOCKING } })
    .select('_id status bookingType residence checkIn checkOut paymentStatus')
    .lean();

  const withoutAvail = [];
  for (const res of active) {
    if (res.bookingType === 'hour') {
      withoutAvail.push({ ...res, reason: 'hour_no_daily_availability_expected' });
      continue;
    }
    const count = await Availability.countDocuments({
      residenceId: res.residence,
      reservationId: res._id,
      status: 'reserved',
    });
    if (count === 0) {
      withoutAvail.push({
        _id: res._id,
        status: res.status,
        bookingType: res.bookingType || '(unset)',
        paymentStatus: res.paymentStatus,
        checkIn: res.checkIn,
        checkOut: res.checkOut,
      });
    }
  }

  const byType = {};
  const byStatus = {};
  const hourExpected = withoutAvail.filter((r) => r.reason === 'hour_no_daily_availability_expected');
  const violating = withoutAvail.filter((r) => r.reason !== 'hour_no_daily_availability_expected');
  for (const r of violating) {
    byType[r.bookingType] = (byType[r.bookingType] || 0) + 1;
    byStatus[r.status] = (byStatus[r.status] || 0) + 1;
  }

  console.log('=== 2. ACTIVES SANS AVAILABILITY ===');
  console.log('hour (absence journalière attendue):', hourExpected.length);
  console.log('day/week/month/unset VIOLATION:', violating.length);
  console.log('ventilation bookingType:', byType);
  console.log('ventilation status:', byStatus);
  const now = new Date();
  const futureOrCurrent = violating.filter((r) => r.checkOut && new Date(r.checkOut) > now);
  console.log('dont checkOut encore dans le futur (blocage inventaire potentiel):', futureOrCurrent.length);
  console.log('liste compacte violations:');
  for (const r of violating) {
    console.log(
      `${r._id} status=${r.status} type=${r.bookingType} pay=${r.paymentStatus} ${r.checkIn} -> ${r.checkOut}`
    );
  }

  const confirmedUnpaid = await Reservation.find({
    status: { $in: ['confirmed', 'in_stay'] },
    paymentStatus: { $ne: 'paid' },
  }).lean();

  console.log('\n=== 3. CONFIRMED / IN_STAY SANS paymentStatus=paid ===\n');
  for (const r of confirmedUnpaid) {
    const bundle = await loadReservationBundle(r._id);
    const paidPay = (bundle.payments || []).filter((p) => p.status === 'paid');
    let cas = 'B — aucun Payment paid (grave)';
    if (paidPay.length) cas = 'A — Payment paid existe, champ Reservation.paymentStatus désynchronisé';
    console.log('cas:', cas);
    console.log(JSON.stringify(bundle, null, 2));
    console.log('');
  }

  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
