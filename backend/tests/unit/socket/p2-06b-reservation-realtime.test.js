/**
 * P2-06B — Canonical reservation realtime (Socket.IO producers/consumers)
 */
const http = require('http');
const ioClient = require('socket.io-client');
const mongoose = require('mongoose');
const { generateAccessToken } = require('../../../src/utils/jwt');
const SocketService = require('../../../src/services/socket.service');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const Payment = require('../../../src/models/payment.model');
const { applyPaymentPaid } = require('../../../src/services/payment-confirmation.service');
const { checkAndExpireReservation } = require('../../../src/services/payment-timer.service');
const { checkinReservation, checkoutReservation } = require('../../../src/services/ops-admin.service');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const { residenceAttrs, reservationSnapshotAttrs } = require('../../helpers/residence.fixture');

jest.setTimeout(120000);

function waitForEvent(socket, event, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Timeout waiting for ${event}`)), timeoutMs);
    socket.once(event, (payload) => {
      clearTimeout(timer);
      resolve(payload);
    });
  });
}

async function seedActors() {
  const partner = await User.create({
    email: `p-${Date.now()}-${Math.random()}@p2-06b.test`,
    password: 'Test1234!',
    firstName: 'Partner',
    lastName: 'Test',
    role: 'partner',
  });
  const client = await User.create({
    email: `c-${Date.now()}-${Math.random()}@p2-06b.test`,
    password: 'Test1234!',
    firstName: 'Client',
    lastName: 'Test',
    role: 'client',
  });
  const admin = await User.create({
    email: `a-${Date.now()}-${Math.random()}@p2-06b.test`,
    password: 'Test1234!',
    firstName: 'Admin',
    lastName: 'Test',
    role: 'admin',
  });
  const policy = await CancellationPolicy.create({
    name: `policy-p2-06b-${Date.now()}`,
    description: 'Test',
    isDefault: true,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  const residence = await Residence.create(
    residenceAttrs({ partner: partner._id, title: 'Res P2-06B', cancellationPolicy: policy._id })
  );
  return { partner, client, admin, residence, policy };
}

describe('P2-06B reservation realtime', () => {
  let server;
  let baseUrl;

  beforeAll(async () => {
    server = http.createServer();
    await new Promise((resolve) => server.listen(0, resolve));
    const { port } = server.address();
    baseUrl = `http://127.0.0.1:${port}`;
    SocketService.initialize(server);
  });

  afterAll(async () => {
    await SocketService.close();
    await new Promise((resolve) => server.close(resolve));
  });

  afterEach(async () => {
    jest.restoreAllMocks();
  });

  describe('socket auth + rooms', () => {
    it('rejects connection without JWT', (done) => {
      const socket = ioClient(baseUrl, {
        transports: ['websocket'],
        forceNew: true,
        reconnection: false,
      });
      socket.on('connect', () => done(new Error('Should not connect')));
      socket.on('connect_error', () => {
        socket.close();
        done();
      });
    });

    it('connects with valid JWT and auto-joins user room', async () => {
      const actors = await seedActors();
      const token = generateAccessToken(actors.client._id, 'client');
      const socket = ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      });
      const authPromise = waitForEvent(socket, 'socket_authenticated');
      await new Promise((resolve, reject) => {
        socket.on('connect', resolve);
        socket.on('connect_error', reject);
      });
      const authPayload = await authPromise;
      expect(authPayload.userId).toBe(String(actors.client._id));
      socket.close();
    });

    it('rejects unauthorized residence join', async () => {
      const actors = await seedActors();
      const otherPartner = await User.create({
        email: `op-${Date.now()}@p2-06b.test`,
        password: 'Test1234!',
        firstName: 'Other',
        lastName: 'Partner',
        role: 'partner',
      });
      const token = generateAccessToken(otherPartner._id, 'partner');
      const socket = ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      });
      await new Promise((resolve, reject) => {
        socket.on('connect', resolve);
        socket.on('connect_error', reject);
      });
      socket.emit('join_residence', String(actors.residence._id));
      const err = await waitForEvent(socket, 'socket_error');
      expect(err.code).toBe('FORBIDDEN');
      socket.close();
    });

    it('allows partner to join own residence room', async () => {
      const actors = await seedActors();
      const token = generateAccessToken(actors.partner._id, 'partner');
      const socket = ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      });
      await new Promise((resolve, reject) => {
        socket.on('connect', resolve);
        socket.on('connect_error', reject);
      });
      socket.emit('join_residence', String(actors.residence._id));
      await new Promise((r) => setTimeout(r, 200));
      socket.close();
    });
  });

  describe('new reservation Partner signal', () => {
    it('notifyNewReservation emits new_reservation_received to partner user room', async () => {
      const actors = await seedActors();
      const reservation = await Reservation.create({
        user: actors.client._id,
        partner: actors.partner._id,
        residence: actors.residence._id,
        cancellationPolicy: actors.policy._id,
        checkIn: new Date('2027-10-10T14:00:00.000Z'),
        checkOut: new Date('2027-10-15T11:00:00.000Z'),
        numberOfGuests: 1,
        totalPrice: 10000,
        status: 'payment_pending',
        paymentStatus: 'pending',
        ...reservationSnapshotAttrs(),
      });

      const token = generateAccessToken(actors.partner._id, 'partner');
      const socket = ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      });
      await new Promise((resolve, reject) => {
        socket.on('connect', resolve);
        socket.on('connect_error', reject);
      });

      const received = waitForEvent(socket, 'new_reservation_received');
      await SocketService.notifyNewReservation(
        await Reservation.findById(reservation._id).populate('user residence partner')
      );
      const payload = await received;
      expect(String(payload.reservationId)).toBe(String(reservation._id));
      socket.close();
    });
  });

  describe('status change canonical', () => {
    it('emitReservationStatusChange includes previousStatus and targets client + partner', async () => {
      const emitSpy = jest.spyOn(require('../../../src/services/socket.service'), 'emitReservationStatusChange');
      const actors = await seedActors();
      const reservation = await Reservation.create({
        user: actors.client._id,
        partner: actors.partner._id,
        residence: actors.residence._id,
        cancellationPolicy: actors.policy._id,
        checkIn: new Date('2027-10-10T14:00:00.000Z'),
        checkOut: new Date('2027-10-15T11:00:00.000Z'),
        numberOfGuests: 1,
        totalPrice: 10000,
        status: 'confirmed',
        paymentStatus: 'paid',
        ...reservationSnapshotAttrs(),
      });
      const populated = await Reservation.findById(reservation._id)
        .populate('user residence partner');

      SocketService.emitReservationStatusChange(populated, 'confirmed', 'in_stay');
      expect(emitSpy).toHaveBeenCalled();
      emitSpy.mockRestore();

      const token = generateAccessToken(actors.client._id, 'client');
      const socket = ioClient(baseUrl, {
        transports: ['websocket'],
        auth: { token },
        forceNew: true,
        reconnection: false,
      });
      await new Promise((resolve, reject) => {
        socket.on('connect', resolve);
        socket.on('connect_error', reject);
      });

      const statusPromise = waitForEvent(socket, 'reservation_status_changed');
      SocketService.emitReservationStatusChange(populated, 'confirmed', 'in_stay');
      const payload = await statusPromise;
      expect(payload.previousStatus).toBe('confirmed');
      expect(payload.newStatus).toBe('in_stay');
      expect(String(payload.reservationId)).toBe(String(reservation._id));
      socket.close();
    });
  });

  describe('Ops parity', () => {
    it('Ops check-in emits same canonical status signal as Partner path would', async () => {
      const emitSpy = jest.spyOn(SocketService, 'emitReservationStatusChange');
      const actors = await seedActors();
      const reservation = await Reservation.create({
        user: actors.client._id,
        partner: actors.partner._id,
        residence: actors.residence._id,
        cancellationPolicy: actors.policy._id,
        checkIn: new Date('2027-10-10T14:00:00.000Z'),
        checkOut: new Date('2027-10-15T11:00:00.000Z'),
        numberOfGuests: 1,
        totalPrice: 10000,
        status: 'confirmed',
        paymentStatus: 'paid',
        ...reservationSnapshotAttrs(),
      });

      await checkinReservation(reservation._id, actors.admin, { reason: 'ops checkin test' });
      expect(emitSpy).toHaveBeenCalledWith(
        expect.objectContaining({ _id: reservation._id }),
        'confirmed',
        'in_stay'
      );
      emitSpy.mockRestore();
    });

    it('Ops checkout emits completed transition', async () => {
      const emitSpy = jest.spyOn(SocketService, 'emitReservationStatusChange');
      const actors = await seedActors();
      const reservation = await Reservation.create({
        user: actors.client._id,
        partner: actors.partner._id,
        residence: actors.residence._id,
        cancellationPolicy: actors.policy._id,
        checkIn: new Date('2027-10-10T14:00:00.000Z'),
        checkOut: new Date('2027-10-15T11:00:00.000Z'),
        numberOfGuests: 1,
        totalPrice: 10000,
        status: 'in_stay',
        paymentStatus: 'paid',
        actualCheckIn: new Date('2027-10-10T14:00:00.000Z'),
        ...reservationSnapshotAttrs(),
      });

      await checkoutReservation(reservation._id, actors.admin, { reason: 'ops checkout test' });
      expect(emitSpy).toHaveBeenCalledWith(
        expect.objectContaining({ _id: reservation._id }),
        'in_stay',
        'completed'
      );
      emitSpy.mockRestore();
    });
  });

  describe('Wave payment confirmation socket', () => {
    it('emits socket once on first payment confirmation', async () => {
      const emitSpy = jest.spyOn(SocketService, 'emitReservationStatusChange');
      const actors = await seedActors();
      const reservation = await Reservation.create({
        user: actors.client._id,
        partner: actors.partner._id,
        residence: actors.residence._id,
        cancellationPolicy: actors.policy._id,
        checkIn: new Date('2027-11-10T14:00:00.000Z'),
        checkOut: new Date('2027-11-15T11:00:00.000Z'),
        numberOfGuests: 1,
        totalPrice: 25000,
        status: 'payment_pending',
        paymentStatus: 'pending',
        ...reservationSnapshotAttrs(),
      });
      const payment = await Payment.create({
        reservation: reservation._id,
        amount: 25000,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        status: 'pending',
        phoneNumber: '0700000000',
      });

      const prevEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';

      const first = await applyPaymentPaid(payment, { triggerPayout: false });
      expect(first.reservationConfirmed !== false).toBe(true);
      expect(emitSpy).toHaveBeenCalledTimes(1);
      expect(emitSpy.mock.calls[0][2]).toBe('confirmed');

      emitSpy.mockClear();
      const replay = await applyPaymentPaid(
        await Payment.findById(payment._id),
        { triggerPayout: false }
      );
      expect(replay.alreadyPaid).toBe(true);
      expect(emitSpy).not.toHaveBeenCalled();

      process.env.NODE_ENV = prevEnv;
      emitSpy.mockRestore();
    });
  });

  describe('payment timeout socket idempotence', () => {
    it('emits once on first expiration, zero on job retry', async () => {
      const emitSpy = jest.spyOn(SocketService, 'emitReservationStatusChange');
      const actors = await seedActors();
      const reservation = await Reservation.create({
        user: actors.client._id,
        partner: actors.partner._id,
        residence: actors.residence._id,
        cancellationPolicy: actors.policy._id,
        checkIn: new Date('2027-12-10T14:00:00.000Z'),
        checkOut: new Date('2027-12-15T11:00:00.000Z'),
        numberOfGuests: 1,
        totalPrice: 15000,
        status: 'payment_pending',
        paymentStatus: 'pending',
        paymentDeadline: new Date(Date.now() - 60 * 1000),
        ...reservationSnapshotAttrs(),
      });

      const prevEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';

      const first = await checkAndExpireReservation(reservation._id);
      expect(first.expired).toBe(true);
      expect(emitSpy).toHaveBeenCalledTimes(1);
      expect(emitSpy.mock.calls[0][1]).toBe('payment_pending');
      expect(emitSpy.mock.calls[0][2]).toBe('expired');

      emitSpy.mockClear();
      const retry = await checkAndExpireReservation(reservation._id);
      expect(retry.expired).toBe(false);
      expect(retry.reason).toMatch(/déjà traitée/i);
      expect(emitSpy).not.toHaveBeenCalled();

      process.env.NODE_ENV = prevEnv;
      emitSpy.mockRestore();
    });

    it('20 concurrent expiration attempts → exactly 1 transition and 1 socket', async () => {
      const emitSpy = jest.spyOn(SocketService, 'emitReservationStatusChange');
      const actors = await seedActors();
      const reservation = await Reservation.create({
        user: actors.client._id,
        partner: actors.partner._id,
        residence: actors.residence._id,
        cancellationPolicy: actors.policy._id,
        checkIn: new Date('2027-12-20T14:00:00.000Z'),
        checkOut: new Date('2027-12-25T11:00:00.000Z'),
        numberOfGuests: 1,
        totalPrice: 15000,
        status: 'payment_pending',
        paymentStatus: 'pending',
        paymentDeadline: new Date(Date.now() - 60 * 1000),
        ...reservationSnapshotAttrs(),
      });

      const prevEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'development';

      const attempts = 20;
      const settled = await Promise.allSettled(
        Array.from({ length: attempts }, () => checkAndExpireReservation(reservation._id))
      );

      const winners = settled.filter(
        (r) => r.status === 'fulfilled' && r.value?.expired === true
      );
      const losers = settled.filter(
        (r) => r.status === 'fulfilled' && r.value?.expired === false
      );
      const rejected = settled.filter((r) => r.status === 'rejected');

      const fresh = await Reservation.findById(reservation._id);
      const expiredHistory = (fresh.statusHistory || []).filter(
        (h) => h.status === 'expired' && /Délai de paiement expiré/i.test(h.reason || '')
      );
      const paymentTimeoutSockets = emitSpy.mock.calls.filter(
        (call) => call[1] === 'payment_pending' && call[2] === 'expired'
      );

      expect(settled).toHaveLength(attempts);
      expect(fresh.status).toBe('expired');
      expect(fresh.expirationReason).toBe('payment_timeout');
      expect(winners.length + losers.length + rejected.length).toBe(attempts);
      expect(winners.length).toBe(1);
      expect(expiredHistory.length).toBe(1);
      expect(paymentTimeoutSockets.length).toBe(1);
      expect(emitSpy).toHaveBeenCalledTimes(1);
      expect(losers.length + rejected.length).toBe(attempts - 1);

      process.env.NODE_ENV = prevEnv;
      emitSpy.mockRestore();
    });
  });

  describe('Ops socket idempotence', () => {
    it('check-in retry emits no duplicate socket', async () => {
      const emitSpy = jest.spyOn(SocketService, 'emitReservationStatusChange');
      const actors = await seedActors();
      const reservation = await Reservation.create({
        user: actors.client._id,
        partner: actors.partner._id,
        residence: actors.residence._id,
        cancellationPolicy: actors.policy._id,
        checkIn: new Date('2027-10-10T14:00:00.000Z'),
        checkOut: new Date('2027-10-15T11:00:00.000Z'),
        numberOfGuests: 1,
        totalPrice: 10000,
        status: 'confirmed',
        paymentStatus: 'paid',
        ...reservationSnapshotAttrs(),
      });

      await checkinReservation(reservation._id, actors.admin, { reason: 'ops checkin first' });
      expect(emitSpy).toHaveBeenCalledTimes(1);

      emitSpy.mockClear();
      await expect(
        checkinReservation(reservation._id, actors.admin, { reason: 'ops checkin retry' })
      ).rejects.toMatchObject({ statusCode: 400 });
      expect(emitSpy).not.toHaveBeenCalled();
      emitSpy.mockRestore();
    });

    it('checkout retry emits no duplicate socket', async () => {
      const emitSpy = jest.spyOn(SocketService, 'emitReservationStatusChange');
      const actors = await seedActors();
      const reservation = await Reservation.create({
        user: actors.client._id,
        partner: actors.partner._id,
        residence: actors.residence._id,
        cancellationPolicy: actors.policy._id,
        checkIn: new Date('2027-10-10T14:00:00.000Z'),
        checkOut: new Date('2027-10-15T11:00:00.000Z'),
        numberOfGuests: 1,
        totalPrice: 10000,
        status: 'in_stay',
        paymentStatus: 'paid',
        actualCheckIn: new Date('2027-10-10T14:00:00.000Z'),
        ...reservationSnapshotAttrs(),
      });

      await checkoutReservation(reservation._id, actors.admin, { reason: 'ops checkout first' });
      expect(emitSpy).toHaveBeenCalledTimes(1);

      emitSpy.mockClear();
      await expect(
        checkoutReservation(reservation._id, actors.admin, { reason: 'ops checkout retry' })
      ).rejects.toMatchObject({ statusCode: 400 });
      expect(emitSpy).not.toHaveBeenCalled();
      emitSpy.mockRestore();
    });
  });
});
