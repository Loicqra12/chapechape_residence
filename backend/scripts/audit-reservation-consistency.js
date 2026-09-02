/**
 * Audit READ-ONLY de cohérence Reservation / Payment / Availability.
 * --dry-run par défaut (aucun write).
 *
 * Usage :
 *   node scripts/audit-reservation-consistency.js
 *   node scripts/audit-reservation-consistency.js --json
 */
require('dotenv').config();
const mongoose = require('mongoose');

const maskMongoUri = (uri = '') => uri.replace(/:\/\/([^:]+):([^@]+)@/, '://$1:****@');
const BLOCKING = ['pending', 'awaiting_approval', 'payment_pending', 'confirmed', 'in_stay'];
const LIMIT = 100;
const STALE_APPROVAL_MS = 48 * 60 * 60 * 1000;

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) {
    console.error('MONGODB_URI manquant');
    process.exit(1);
  }

  const asJson = process.argv.includes('--json');
  console.error('Audit read-only:', maskMongoUri(uri));
  await mongoose.connect(uri, { autoIndex: false });

  const Reservation = require('../src/models/reservation.model');
  const Payment = require('../src/models/payment.model');
  const Availability = require('../src/models/availability.model');

  const report = {
    generatedAt: new Date().toISOString(),
    dryRun: true,
    findings: {},
  };

  report.findings.blockingOverlaps = await Reservation.aggregate([
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
          { $project: { _id: 1, status: 1, checkIn: 1, checkOut: 1 } },
          { $limit: 3 },
        ],
        as: 'overlaps',
      },
    },
    { $match: { 'overlaps.0': { $exists: true } } },
    { $project: { _id: 1, residence: 1, status: 1, checkIn: 1, checkOut: 1, overlaps: 1 } },
    { $limit: LIMIT },
  ]);

  const activeDay = await Reservation.find({
    status: { $in: BLOCKING },
    bookingType: { $in: ['day', 'week', 'month', null] },
  })
    .select('_id residence checkIn checkOut bookingType status')
    .limit(500)
    .lean();

  const missingAvailability = [];
  for (const res of activeDay) {
    if (res.bookingType === 'hour') continue;
    const count = await Availability.countDocuments({
      residenceId: res.residence,
      reservationId: res._id,
      status: 'reserved',
    });
    if (count === 0) {
      missingAvailability.push({ reservationId: res._id, status: res.status, residence: res.residence });
      if (missingAvailability.length >= LIMIT) break;
    }
  }
  report.findings.activeReservationWithoutAvailability = missingAvailability;

  report.findings.orphanReservedAvailability = await Availability.find({
    status: 'reserved',
    $or: [{ reservationId: null }, { reservationId: { $exists: false } }],
  })
    .select('_id residenceId date status reservationId')
    .limit(LIMIT)
    .lean();

  const reservedWithId = await Availability.find({
    status: 'reserved',
    reservationId: { $ne: null },
  })
    .select('reservationId residenceId date')
    .limit(1000)
    .lean();
  const resIds = [...new Set(reservedWithId.map((a) => String(a.reservationId)))];
  const existing = await Reservation.find({ _id: { $in: resIds } }).select('_id').lean();
  const existingSet = new Set(existing.map((r) => String(r._id)));
  report.findings.reservedAvailabilityDanglingReservation = reservedWithId
    .filter((a) => !existingSet.has(String(a.reservationId)))
    .slice(0, LIMIT);

  const paidExpired = await Payment.aggregate([
    { $match: { status: 'paid' } },
    {
      $lookup: {
        from: 'reservations',
        localField: 'reservation',
        foreignField: '_id',
        as: 'res',
      },
    },
    { $unwind: { path: '$res', preserveNullAndEmptyArrays: true } },
    { $match: { 'res.status': 'expired' } },
    {
      $project: {
        _id: 1,
        refundStatus: 1,
        refundOpsRequired: 1,
        reservation: 1,
        amount: 1,
      },
    },
    { $limit: LIMIT },
  ]);
  report.findings.paidPlusExpired = paidExpired;

  report.findings.confirmedUnpaid = await Reservation.find({
    status: { $in: ['confirmed', 'in_stay'] },
    paymentStatus: { $ne: 'paid' },
  })
    .select('_id status paymentStatus')
    .limit(LIMIT)
    .lean();

  const staleBefore = new Date(Date.now() - STALE_APPROVAL_MS);
  report.findings.staleAwaitingApproval = await Reservation.find({
    status: 'awaiting_approval',
    createdAt: { $lt: staleBefore },
  })
    .select('_id createdAt status reservationModeSnapshot')
    .limit(LIMIT)
    .lean();

  report.findings.paymentMissingReservation = await Payment.aggregate([
    {
      $lookup: {
        from: 'reservations',
        localField: 'reservation',
        foreignField: '_id',
        as: 'res',
      },
    },
    { $match: { res: { $size: 0 } } },
    { $project: { _id: 1, status: 1, reservation: 1, amount: 1 } },
    { $limit: LIMIT },
  ]);

  const db = mongoose.connection.db;
  try {
    report.findings.inventoryLockCount = await db.collection('inventorylocks').countDocuments();
  } catch (err) {
    report.findings.inventoryLockCount = { error: err.message };
  }

  report.summary = Object.fromEntries(
    Object.entries(report.findings).map(([k, v]) => [
      k,
      Array.isArray(v) ? v.length : v,
    ])
  );

  if (asJson) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    console.log('=== AUDIT Reservation consistency (dry-run) ===');
    console.log(JSON.stringify(report.summary, null, 2));
    console.log('\nDétail limité à', LIMIT, 'par catégorie.');
    for (const [key, rows] of Object.entries(report.findings)) {
      if (Array.isArray(rows) && rows.length) {
        console.log(`\n--- ${key} (${rows.length}) ---`);
        console.log(JSON.stringify(rows.slice(0, 5), null, 2));
      }
    }
    console.log('\nAucune correction appliquée.');
  }

  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
