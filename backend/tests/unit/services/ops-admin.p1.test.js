const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const Payment = require('../../../src/models/payment.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const OpsAuditLog = require('../../../src/models/ops-audit-log.model');
const {
  allowedReservationActions,
  listReservations,
  getReservation,
  checkinReservation,
  checkoutReservation,
  cancelReservation,
  listRefunds,
  confirmRefund,
  listAnomalies,
} = require('../../../src/services/ops-admin.service');
const { residenceAttrs, reservationSnapshotAttrs } = require('../../helpers/residence.fixture');

jest.setTimeout(180000);

async function seed() {
  const admin = await User.create({
    email: `admin-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234',
    firstName: 'Ada',
    lastName: 'Min',
    role: 'admin',
  });
  const partner = await User.create({
    email: `p-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234',
    firstName: 'Part',
    lastName: 'Ner',
    role: 'partner',
  });
  const client = await User.create({
    email: `c-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234',
    firstName: 'Cli',
    lastName: 'Ent',
    role: 'client',
  });
  const policy = await CancellationPolicy.create({
    name: `policy-${Date.now()}`,
    description: 'Test policy',
    isDefault: true,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  const residence = await Residence.create(residenceAttrs({
    partner: partner._id,
    cancellationPolicy: policy._id,
  }));
  return { admin, partner, client, policy, residence };
}

async function seedReservation(actors, overrides = {}) {
  return Reservation.create({
    user: actors.client._id,
    partner: actors.partner._id,
    residence: actors.residence._id,
    cancellationPolicy: actors.policy._id,
    checkIn: overrides.checkIn || new Date('2027-09-10T14:00:00.000Z'),
    checkOut: overrides.checkOut || new Date('2027-09-15T11:00:00.000Z'),
    numberOfGuests: 1,
    totalPrice: 50000,
    status: overrides.status || 'confirmed',
    paymentStatus: overrides.paymentStatus || 'paid',
    actualCheckIn: overrides.actualCheckIn || null,
    paymentDeadline: overrides.paymentDeadline,
    hostApprovalDeadline: overrides.hostApprovalDeadline,
    ...reservationSnapshotAttrs(),
  });
}

describe('P1-07 ops-admin', () => {
  it('n’expose jamais completed depuis confirmed (check-in requis)', () => {
    expect(allowedReservationActions({ status: 'confirmed', paymentStatus: 'paid' }))
      .toEqual(['cancel', 'checkin']);
    expect(allowedReservationActions({ status: 'confirmed', paymentStatus: 'paid' }))
      .not.toContain('checkout');
    expect(allowedReservationActions({ status: 'in_stay', paymentStatus: 'paid' }))
      .toEqual(['cancel', 'checkout']);
    expect(allowedReservationActions({ status: 'completed', paymentStatus: 'paid' }))
      .toEqual([]);
  });

  it('liste globale paginée avec filtres de statut', async () => {
    const actors = await seed();
    await seedReservation(actors, { status: 'pending', paymentStatus: 'pending' });
    await seedReservation(actors, { status: 'confirmed', paymentStatus: 'paid' });
    await seedReservation(actors, { status: 'cancelled', paymentStatus: 'pending' });

    const page = await listReservations({ status: 'confirmed', page: 1, limit: 10 });
    expect(page.pagination.total).toBe(1);
    expect(page.data).toHaveLength(1);
    expect(page.data[0].status).toBe('confirmed');
    expect(page.data[0].client.name).toContain('Cli');
    expect(page.data[0].allowedActions).toEqual(['cancel', 'checkin']);
    expect(page.data[0].inventoryState).toBe('occupying');
  });

  it('refuse le checkout ops sur confirmed sans check-in', async () => {
    const actors = await seed();
    const reservation = await seedReservation(actors, { status: 'confirmed', paymentStatus: 'paid' });
    await expect(
      checkoutReservation(reservation._id, actors.admin, { reason: 'terminer sans check-in' })
    ).rejects.toMatchObject({ statusCode: 400 });
    const fresh = await Reservation.findById(reservation._id);
    expect(fresh.status).toBe('confirmed');
  });

  it('check-in confirmed→in_stay puis checkout→completed, avec audit', async () => {
    const actors = await seed();
    const reservation = await seedReservation(actors, { status: 'confirmed', paymentStatus: 'paid' });

    const afterIn = await checkinReservation(reservation._id, actors.admin, { reason: 'arrivée client' });
    expect(afterIn.status).toBe('in_stay');
    expect(afterIn.actualCheckIn).toBeTruthy();
    expect(afterIn.allowedActions).toContain('checkout');
    expect(afterIn.allowedActions).not.toContain('checkin');

    const afterOut = await checkoutReservation(reservation._id, actors.admin, { reason: 'départ client' });
    expect(afterOut.status).toBe('completed');
    expect(afterOut.actualCheckOut).toBeTruthy();
    expect(afterOut.allowedActions).toEqual([]);

    const logs = await OpsAuditLog.find({ entityId: reservation._id }).sort({ createdAt: 1 });
    expect(logs.map((l) => l.action)).toEqual(['checkin', 'checkout']);
    expect(String(logs[0].actor)).toBe(String(actors.admin._id));
    expect(logs[0].actorRole).toBe('admin');
    expect(logs[0].correlationId).toBeTruthy();
    expect(logs[0].requestId).toBeTruthy();
    await expect(
      OpsAuditLog.updateOne({ _id: logs[0]._id }, { $set: { reason: 'tamper' } })
    ).rejects.toThrow(/immutable/);
  });

  it('annulation ops exige un motif et passe par cancelled', async () => {
    const actors = await seed();
    const reservation = await seedReservation(actors, { status: 'payment_pending', paymentStatus: 'pending' });
    await expect(cancelReservation(reservation._id, actors.admin, { reason: 'x' }))
      .rejects.toMatchObject({ statusCode: 400 });
    const cancelled = await cancelReservation(reservation._id, actors.admin, {
      reason: 'demande client ops',
    });
    expect(cancelled.status).toBe('cancelled');
    const log = await OpsAuditLog.findOne({ entityId: reservation._id, action: 'cancel' });
    expect(log.reason).toBe('demande client ops');
  });

  it('file refunds : ops_required impossible à rater + confirm manuel auditable', async () => {
    const actors = await seed();
    const reservation = await seedReservation(actors, { status: 'cancelled', paymentStatus: 'paid' });
    const payment = await Payment.create({
      reservation: reservation._id,
      amount: 50000,
      paymentMethod: 'wave',
      paymentProvider: 'wave',
      status: 'paid',
      refundStatus: 'required',
      refundOpsRequired: true,
      refundReason: 'ops_cancel',
      transactionId: `wave_${Date.now()}`,
      phoneNumber: '0102030405',
    });

    const queue = await listRefunds({ bucket: 'ops_required' });
    expect(queue.counts.ops_required).toBeGreaterThanOrEqual(1);
    expect(queue.data.some((row) => String(row._id) === String(payment._id))).toBe(true);
    expect(queue.data[0].allowedActions).toContain('confirm_manual_refund');

    await expect(
      confirmRefund(payment._id, actors.admin, { note: 'ok', externalReference: 'WV-1' })
    ).rejects.toMatchObject({ statusCode: 400 });

    const confirmed = await confirmRefund(payment._id, actors.admin, {
      note: 'Remboursement Wave effectué au dashboard merchant',
      externalReference: 'WV-REF-999',
    });
    expect(confirmed.status).toBe('refunded');
    expect(confirmed.refundStatus).toBe('succeeded');
    expect(confirmed.refundOpsRequired).toBe(false);

    const freshPayment = await Payment.findById(payment._id);
    expect(freshPayment.refundOpsExternalRef).toBe('WV-REF-999');
    expect(String(freshPayment.refundOpsConfirmedBy)).toBe(String(actors.admin._id));
    const freshReservation = await Reservation.findById(reservation._id);
    expect(freshReservation.paymentStatus).toBe('refunded');
    expect(freshReservation.status).toBe('refunded');

    const audit = await OpsAuditLog.findOne({ entityId: payment._id, action: 'refund_confirm' });
    expect(audit.metadata.externalReference).toBe('WV-REF-999');
  });

  it('refuse confirm manuel si refundOpsRequired est absent', async () => {
    const actors = await seed();
    const reservation = await seedReservation(actors, { status: 'cancelled', paymentStatus: 'paid' });
    const payment = await Payment.create({
      reservation: reservation._id,
      amount: 10000,
      paymentMethod: 'wave',
      paymentProvider: 'wave',
      status: 'paid',
      refundStatus: 'required',
      refundOpsRequired: false,
      transactionId: `wave_noops_${Date.now()}`,
      phoneNumber: '0102030405',
    });
    await expect(
      confirmRefund(payment._id, actors.admin, {
        note: 'Tentative sans file ops required xx',
        externalReference: 'WV-NO',
      })
    ).rejects.toMatchObject({ statusCode: 409 });
  });

  it('anomalies : confirmed non paid + payment_pending dépassé', async () => {
    const actors = await seed();
    const unpaid = await seedReservation(actors, { status: 'payment_pending', paymentStatus: 'pending' });
    await Reservation.collection.updateOne(
      { _id: unpaid._id },
      { $set: { status: 'confirmed', paymentStatus: 'pending' } }
    );
    await seedReservation(actors, {
      status: 'payment_pending',
      paymentStatus: 'pending',
      paymentDeadline: new Date(Date.now() - 60 * 60 * 1000),
    });
    const report = await listAnomalies();
    expect(report.summary.confirmedUnpaid).toBeGreaterThanOrEqual(1);
    expect(report.summary.overduePaymentPending).toBeGreaterThanOrEqual(1);
    expect(report.findings.confirmedUnpaid[0].paymentStatus).not.toBe('paid');
  });

  it('détail reservation expose allowedActions calculées, pas un enum libre', async () => {
    const actors = await seed();
    const reservation = await seedReservation(actors, { status: 'in_stay', paymentStatus: 'paid', actualCheckIn: new Date() });
    const detail = await getReservation(reservation._id);
    expect(detail.allowedActions).toEqual(['cancel', 'checkout']);
    expect(detail.allowedActions).not.toContain('completed');
    expect(detail.inventoryState).toBe('occupying');
  });
});
