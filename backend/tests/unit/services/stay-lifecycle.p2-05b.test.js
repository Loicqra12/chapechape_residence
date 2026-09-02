process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci_at_least_32_chars_ok';

const request = require('supertest');
const express = require('express');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const Payment = require('../../../src/models/payment.model');
const { generateAccessToken } = require('../../../src/utils/jwt');
const { errorHandler } = require('../../../src/middlewares/error.middleware');
const reservationRoutes = require('../../../src/routes/reservation.routes');
const ReservationStateService = require('../../../src/services/reservation-state.service');
const { createReservation } = require('../../../src/services/reservation.service');
const { applyPaymentPaid } = require('../../../src/services/payment-confirmation.service');
const errorCodes = require('../../../src/utils/errorCodes');
const {
  normalizeReservationStatusInput,
  RESERVATION_STATUS_INPUT_ALIASES,
} = require('../../../src/constants/reservation-status');
const { residenceAttrs, reservationSnapshotAttrs } = require('../../helpers/residence.fixture');

/** Toutes les entrées brutes qui normalisent vers in_stay ou completed (canoniques + aliases). */
function stayBlockedStatusInputs() {
  const inputs = new Set(['in_stay', 'completed']);
  for (const [raw, canonical] of Object.entries(RESERVATION_STATUS_INPUT_ALIASES)) {
    if (canonical === 'in_stay' || canonical === 'completed') {
      inputs.add(raw);
    }
  }
  return [...inputs];
}

jest.setTimeout(180000);

jest.mock('../../../src/services/socket.service', () => ({
  notifyReservationStatusUpdate: jest.fn().mockResolvedValue(undefined),
  notifyBlockedDatesUpdate: jest.fn().mockResolvedValue(undefined),
  notifyNewReservation: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('../../../src/services/agenda.service', () => ({
  scheduleReviewReminder: jest.fn().mockResolvedValue(undefined),
}));

const { scheduleReviewReminder } = require('../../../src/services/agenda.service');

function authHeader(user) {
  return `Bearer ${generateAccessToken(user._id.toString(), user.role)}`;
}

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/reservations', reservationRoutes);
  app.use(errorHandler);
  return app;
}

async function seedActors() {
  const partner = await User.create({
    email: `p-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234',
    firstName: 'Part',
    lastName: 'Ner',
    role: 'partner',
    isPhoneVerified: true,
    phoneNumber: '+2250700000001',
  });
  const otherPartner = await User.create({
    email: `op-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234',
    firstName: 'Other',
    lastName: 'Partner',
    role: 'partner',
    isPhoneVerified: true,
    phoneNumber: '+2250700000002',
  });
  const client = await User.create({
    email: `c-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234',
    firstName: 'Cli',
    lastName: 'Ent',
    role: 'client',
  });
  const clientB = await User.create({
    email: `cb-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234',
    firstName: 'Cli',
    lastName: 'B',
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
    reservationMode: 'instant',
  }));
  return { partner, otherPartner, client, clientB, policy, residence };
}

async function seedPaidConfirmed(actors, overrides = {}) {
  const checkIn = overrides.checkIn || new Date(Date.now() + 60 * 60 * 1000);
  const checkOut = overrides.checkOut || new Date(checkIn.getTime() + 5 * 24 * 60 * 60 * 1000);
  const reservation = await Reservation.create({
    user: actors.client._id,
    partner: actors.partner._id,
    residence: actors.residence._id,
    cancellationPolicy: actors.policy._id,
    checkIn,
    checkOut,
    numberOfGuests: 1,
    totalPrice: 50000,
    status: overrides.status || 'confirmed',
    paymentStatus: overrides.paymentStatus || 'paid',
    actualCheckIn: overrides.actualCheckIn || null,
    actualCheckOut: overrides.actualCheckOut || null,
    ...reservationSnapshotAttrs(),
  });
  return reservation;
}

describe('P2-05B stay lifecycle (Partner canonical)', () => {
  beforeEach(() => {
    scheduleReviewReminder.mockClear();
  });

  it('normal check-in: confirmed + paid → in_stay + actualCheckIn backend', async () => {
    const app = createApp();
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors);

    const res = await request(app)
      .patch(`/api/reservations/${reservation._id}/checkin`)
      .set('Authorization', authHeader(actors.partner));

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('in_stay');
    expect(res.body.data.actualCheckIn).toBeTruthy();

    const fresh = await Reservation.findById(reservation._id);
    expect(fresh.status).toBe('in_stay');
    expect(fresh.statusHistory.filter((h) => h.status === 'in_stay')).toHaveLength(1);
  });

  it('refuses check-in when unpaid', async () => {
    const app = createApp();
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors);
    await Reservation.updateOne(
      { _id: reservation._id },
      { $set: { paymentStatus: 'pending' } }
    );

    const res = await request(app)
      .patch(`/api/reservations/${reservation._id}/checkin`)
      .set('Authorization', authHeader(actors.partner));

    expect(res.status).toBe(400);
    const fresh = await Reservation.findById(reservation._id);
    expect(fresh.status).toBe('confirmed');
    expect(fresh.status).not.toBe('in_stay');
  });

  it('refuses check-in from wrong partner (403)', async () => {
    const app = createApp();
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors);

    const res = await request(app)
      .patch(`/api/reservations/${reservation._id}/checkin`)
      .set('Authorization', authHeader(actors.otherPartner));

    expect(res.status).toBe(403);
  });

  it('refuses check-in too early (before checkIn - 2h)', async () => {
    const app = createApp();
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors, {
      checkIn: new Date(Date.now() + 6 * 60 * 60 * 1000),
    });

    const res = await request(app)
      .patch(`/api/reservations/${reservation._id}/checkin`)
      .set('Authorization', authHeader(actors.partner));

    expect(res.status).toBe(400);
    expect(res.body.code).toBe(errorCodes.RESERVATION.CHECKIN_TOO_EARLY);
  });

  it.each(stayBlockedStatusInputs())(
    'blocks generic /status stay bypass for raw=%s (after canonical normalize)',
    async (rawStatus) => {
      const canonical = normalizeReservationStatusInput(rawStatus);
      expect(['in_stay', 'completed']).toContain(canonical);

      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);

      const res = await request(app)
        .patch(`/api/reservations/${reservation._id}/status`)
        .set('Authorization', authHeader(actors.partner))
        .send({ status: rawStatus });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(errorCodes.RESERVATION.STAY_ACTION_REQUIRED);

      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.status).toBe('confirmed');
    }
  );

  it('does not block non-stay /status transitions with STAY_ACTION_REQUIRED', async () => {
    const app = createApp();
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors);

    const res = await request(app)
      .patch(`/api/reservations/${reservation._id}/status`)
      .set('Authorization', authHeader(actors.partner))
      .send({ status: 'cancelled' });

    expect(res.body.code).not.toBe(errorCodes.RESERVATION.STAY_ACTION_REQUIRED);
    expect(res.status).not.toBe(400);
    expect([200, 409]).toContain(res.status);
  });

  it('normal checkout: in_stay + actualCheckIn → completed + actualCheckOut', async () => {
    const app = createApp();
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors);
    await ReservationStateService.updateStatus(
      reservation._id,
      'in_stay',
      actors.partner._id,
      { reason: 'setup', fromStatuses: ['confirmed'] }
    );

    const res = await request(app)
      .patch(`/api/reservations/${reservation._id}/checkout`)
      .set('Authorization', authHeader(actors.partner));

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe('completed');
    expect(res.body.data.actualCheckOut).toBeTruthy();
    expect(scheduleReviewReminder).toHaveBeenCalledTimes(1);
  });

  it('refuses checkout before check-in (confirmed)', async () => {
    const app = createApp();
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors);

    const res = await request(app)
      .patch(`/api/reservations/${reservation._id}/checkout`)
      .set('Authorization', authHeader(actors.partner));

    expect(res.status).toBe(400);
    const fresh = await Reservation.findById(reservation._id);
    expect(fresh.status).toBe('confirmed');
  });

  it('double check-in: exactly one transition under concurrency', async () => {
    const app = createApp();
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors);

    const results = await Promise.all(
      Array.from({ length: 20 }, () =>
        request(app)
          .patch(`/api/reservations/${reservation._id}/checkin`)
          .set('Authorization', authHeader(actors.partner))
      )
    );

    const successes = results.filter((r) => r.status === 200);
    expect(successes).toHaveLength(1);

    const fresh = await Reservation.findById(reservation._id);
    expect(fresh.status).toBe('in_stay');
    expect(fresh.statusHistory.filter((h) => h.status === 'in_stay')).toHaveLength(1);
  });

  it('double checkout: exactly one transition and one review reminder', async () => {
    const app = createApp();
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors);
    await ReservationStateService.updateStatus(
      reservation._id,
      'in_stay',
      actors.partner._id,
      { reason: 'setup', fromStatuses: ['confirmed'] }
    );
    scheduleReviewReminder.mockClear();

    const results = await Promise.all(
      Array.from({ length: 20 }, () =>
        request(app)
          .patch(`/api/reservations/${reservation._id}/checkout`)
          .set('Authorization', authHeader(actors.partner))
      )
    );

    const successes = results.filter((r) => r.status === 200);
    expect(successes).toHaveLength(1);

    const fresh = await Reservation.findById(reservation._id);
    expect(fresh.status).toBe('completed');
    expect(fresh.statusHistory.filter((h) => h.status === 'completed')).toHaveLength(1);
    expect(scheduleReviewReminder).toHaveBeenCalledTimes(1);
  });

  it('payment invariant: unpaid never reaches in_stay or completed via state service', async () => {
    const actors = await seedActors();
    const reservation = await seedPaidConfirmed(actors);
    await Reservation.updateOne(
      { _id: reservation._id },
      { $set: { paymentStatus: 'pending' } }
    );

    await expect(
      ReservationStateService.updateStatus(
        reservation._id,
        'in_stay',
        actors.partner._id,
        { reason: 'test', fromStatuses: ['confirmed'] }
      )
    ).rejects.toMatchObject({ statusCode: 400 });

    await Reservation.collection.updateOne(
      { _id: reservation._id },
      { $set: { status: 'in_stay', actualCheckIn: new Date(), paymentStatus: 'pending' } }
    );

    await expect(
      ReservationStateService.updateStatus(
        reservation._id,
        'completed',
        actors.partner._id,
        { reason: 'test', fromStatuses: ['in_stay'] }
      )
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it('state machine forbids confirmed → completed', () => {
    expect(ReservationStateService.isTransitionAllowed('confirmed', 'completed')).toBe(false);
  });

  it('early checkout inventory characterization (10→15, checkout day 12, new booking 12→15)', async () => {
    const actors = await seedActors();
    const residence = actors.residence;

    const reservation = await createReservation({
      residence: residence._id,
      user: actors.client._id,
      checkIn: new Date('2027-06-10T14:00:00.000Z'),
      checkOut: new Date('2027-06-15T11:00:00.000Z'),
      numberOfGuests: 1,
      bookingType: 'day',
    });
    const paidReservation = await Reservation.findById(reservation._id);
    const payment = await Payment.create({
      reservation: reservation._id,
      amount: paidReservation.totalPrice,
      paymentMethod: 'wave',
      paymentProvider: 'wave',
      status: 'pending',
      phoneNumber: '0102030405',
    });
    await applyPaymentPaid(payment, { triggerPayout: false });
    const confirmed = await Reservation.findById(reservation._id);
    expect(confirmed.status).toBe('confirmed');
    expect(confirmed.paymentStatus).toBe('paid');

    await ReservationStateService.updateStatus(
      reservation._id,
      'in_stay',
      actors.partner._id,
      { reason: 'checkin', fromStatuses: ['confirmed'] }
    );
    await ReservationStateService.updateStatus(
      reservation._id,
      'completed',
      actors.partner._id,
      { reason: 'early checkout day 12', fromStatuses: ['in_stay'] }
    );

    const completed = await Reservation.findById(reservation._id);
    expect(completed.status).toBe('completed');
    expect(completed.checkOut.toISOString()).toBe('2027-06-15T11:00:00.000Z');

    let overlapAllowed = false;
    try {
      await createReservation({
        residence: residence._id,
        user: actors.clientB._id,
        checkIn: new Date('2027-06-12T14:00:00.000Z'),
        checkOut: new Date('2027-06-15T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      overlapAllowed = true;
    } catch (err) {
      expect([400, 409]).toContain(err.statusCode);
    }

    // P0 risk: inventory still blocks sold period after early checkout (status completed but dates unchanged)
    expect(overlapAllowed).toBe(false);
  });
});
