const mongoose = require('mongoose');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const Payment = require('../../../src/models/payment.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const Availability = require('../../../src/models/availability.model');
const { createReservation, modifyReservation } = require('../../../src/services/reservation.service');
const { applyPaymentPaid } = require('../../../src/services/payment-confirmation.service');
const {
  inventoryDayKeys,
  withRetry,
  mapInventoryError,
} = require('../../../src/services/inventory.service');
const InventoryLock = require('../../../src/models/inventory-lock.model');
const ReservationStateService = require('../../../src/services/reservation-state.service');
const reservationController = require('../../../src/controllers/reservation/reservation.controller');
const {
  processPaymentRefund,
  setRefundAdapter,
  markRefundRequired,
} = require('../../../src/services/refund.service');
const errorCodes = require('../../../src/utils/errorCodes');

jest.setTimeout(120000);

async function seedActors() {
  const partner = await User.create({
    email: `p-${Date.now()}@test.com`,
    password: 'Test1234',
    firstName: 'Part',
    lastName: 'Ner',
    role: 'partner',
  });
  const client = await User.create({
    email: `c-${Date.now()}@test.com`,
    password: 'Test1234',
    firstName: 'Cli',
    lastName: 'Ent',
    role: 'client',
  });
  const policy = await CancellationPolicy.create({
    name: `default-${Date.now()}`,
    description: 'Test policy',
    isDefault: true,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  return { partner, client, policy };
}

async function seedResidence(partner, policy, extras = {}) {
  return Residence.create({
    title: 'Test Res',
    description: 'Desc test résidence assez longue',
    price: 10000,
    pricePeriod: extras.pricePeriod || 'day',
    address: 'Rue 1',
    city: 'Abidjan',
    locationData: { address: 'Rue 1', city: 'Abidjan', country: 'CI' },
    type: 'apartment',
    bedrooms: 1,
    bathrooms: 1,
    area: 40,
    partner: partner._id,
    cancellationPolicy: policy._id,
    reservationMode: 'instant',
    paymentTTLMinutes: 60,
    hourlyRates: { oneHour: 5000, twoHours: 8000, threeHours: 10000, additionalHour: 2000 },
    ...extras,
  });
}

describe('P0 inventaire + paiement tardif', () => {
  describe('Day overlap (ne pas casser)', () => {
    it('10→15 vs 12→17 = REFUSÉ', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2026-06-10T14:00:00.000Z'),
        checkOut: new Date('2026-06-15T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      const clientB = await User.create({
        email: `b-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'B',
        lastName: 'B',
        role: 'client',
      });
      try {
        await createReservation({
          residence: residence._id,
          user: clientB._id,
          checkIn: new Date('2026-06-12T14:00:00.000Z'),
          checkOut: new Date('2026-06-17T11:00:00.000Z'),
          numberOfGuests: 1,
          bookingType: 'day',
        });
        throw new Error('devrait refuser le chevauchement 10→15 vs 12→17');
      } catch (err) {
        // Availability unique → 400 ; overlap Reservation → 409. Les deux = REFUSÉ.
        expect([400, 409]).toContain(err.statusCode);
      }
    });

    it('10→15 vs 15→18 = ACCEPTÉ', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2026-06-10T14:00:00.000Z'),
        checkOut: new Date('2026-06-15T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      const clientB = await User.create({
        email: `b2-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'B',
        lastName: 'B',
        role: 'client',
      });
      const second = await createReservation({
        residence: residence._id,
        user: clientB._id,
        checkIn: new Date('2026-06-15T14:00:00.000Z'),
        checkOut: new Date('2026-06-18T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      expect(second).toBeTruthy();
      expect(second.status).toBe('payment_pending');
    });
  });

  describe('Hour overlap', () => {
    it('13:00→17:00 vs 14:00→16:00 = REFUSÉ', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy, { pricePeriod: 'hour' });
      const day = '2026-08-20';
      await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date(`${day}T13:00:00.000Z`),
        checkOut: new Date(`${day}T17:00:00.000Z`),
        numberOfGuests: 1,
        bookingType: 'hour',
      });
      const clientB = await User.create({
        email: `hb-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'B',
        lastName: 'B',
        role: 'client',
      });
      await expect(
        createReservation({
          residence: residence._id,
          user: clientB._id,
          checkIn: new Date(`${day}T14:00:00.000Z`),
          checkOut: new Date(`${day}T16:00:00.000Z`),
          numberOfGuests: 1,
          bookingType: 'hour',
        })
      ).rejects.toMatchObject({ statusCode: 409 });
    });

    it('13:00→15:00 vs 15:00→17:00 = ACCEPTÉ', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy, { pricePeriod: 'hour' });
      const day = '2026-08-21';
      await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date(`${day}T13:00:00.000Z`),
        checkOut: new Date(`${day}T15:00:00.000Z`),
        numberOfGuests: 1,
        bookingType: 'hour',
      });
      const clientB = await User.create({
        email: `hb2-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'B',
        lastName: 'B',
        role: 'client',
      });
      const second = await createReservation({
        residence: residence._id,
        user: clientB._id,
        checkIn: new Date(`${day}T15:00:00.000Z`),
        checkOut: new Date(`${day}T17:00:00.000Z`),
        numberOfGuests: 1,
        bookingType: 'hour',
      });
      expect(second).toBeTruthy();
    });

    it('20 créations concurrentes même plage horaire → exactement 1 succès', async () => {
      const { partner, policy } = await seedActors();
      const residence = await seedResidence(partner, policy, { pricePeriod: 'hour' });
      const clients = await Promise.all(
        Array.from({ length: 20 }, (_, i) =>
          User.create({
            email: `conc-${Date.now()}-${i}@test.com`,
            password: 'Test1234',
            firstName: 'C',
            lastName: `${i}`,
            role: 'client',
          })
        )
      );
      const checkIn = new Date('2026-08-22T13:00:00.000Z');
      const checkOut = new Date('2026-08-22T17:00:00.000Z');
      const results = await Promise.allSettled(
        clients.map((u) =>
          createReservation({
            residence: residence._id,
            user: u._id,
            checkIn,
            checkOut,
            numberOfGuests: 1,
            bookingType: 'hour',
          })
        )
      );
      const ok = results.filter((r) => r.status === 'fulfilled');
      const ko = results.filter((r) => r.status === 'rejected');
      expect(ok.length).toBe(1);
      expect(ko.length).toBe(19);
      ko.forEach((r) => {
        expect([409, 503]).toContain(r.reason.statusCode);
      });
      const count = await Reservation.countDocuments({
        residence: residence._id,
        status: { $in: ['payment_pending', 'pending', 'awaiting_approval', 'confirmed', 'in_stay'] },
      });
      expect(count).toBe(1);
    });
  });

  describe('Late payment / webhook après expiration', () => {
    it('Test A — expired + inventaire libre → confirmed + paid', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      const reservation = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2026-09-10T14:00:00.000Z'),
        checkOut: new Date('2026-09-15T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });

      await Availability.updateMany(
        { residenceId: residence._id, reservationId: reservation._id },
        { $set: { status: 'available', reservationId: null } }
      );
      await Reservation.updateOne({ _id: reservation._id }, { $set: { status: 'expired' } });

      const payment = await Payment.create({
        reservation: reservation._id,
        amount: reservation.totalPrice,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        status: 'pending',
        phoneNumber: '0102030405',
      });

      const result = await applyPaymentPaid(payment, { allowExpired: true, triggerPayout: false });
      expect(result.refundRequired).not.toBe(true);
      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.status).toBe('confirmed');
      expect(fresh.paymentStatus).toBe('paid');
      const paid = await Payment.findById(payment._id);
      expect(paid.status).toBe('paid');
    });

    it('Test B — expired + dates reprises → refund_required, A non confirmée', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      const reservationA = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2026-10-10T14:00:00.000Z'),
        checkOut: new Date('2026-10-15T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });

      await Availability.updateMany(
        { residenceId: residence._id, reservationId: reservationA._id },
        { $set: { status: 'available', reservationId: null } }
      );
      await Reservation.updateOne({ _id: reservationA._id }, { $set: { status: 'expired' } });

      const clientB = await User.create({
        email: `lateb-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'B',
        lastName: 'B',
        role: 'client',
      });
      await createReservation({
        residence: residence._id,
        user: clientB._id,
        checkIn: new Date('2026-10-10T14:00:00.000Z'),
        checkOut: new Date('2026-10-15T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });

      const payment = await Payment.create({
        reservation: reservationA._id,
        amount: 10000,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        status: 'pending',
        phoneNumber: '0102030405',
      });

      const result = await applyPaymentPaid(payment, { allowExpired: true, triggerPayout: false });
      expect(result.refundRequired).toBe(true);
      const freshA = await Reservation.findById(reservationA._id);
      expect(freshA.status).toBe('expired');
      const paid = await Payment.findById(payment._id);
      expect(paid.status).toBe('paid');
      expect(paid.metadata.get('refund_required')).toBe('true');
      expect(paid.refundStatus).toBe('required');
    });

    it('Test C — même paiement 5 fois → une seule confirmation financière', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      const reservation = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2026-11-10T14:00:00.000Z'),
        checkOut: new Date('2026-11-12T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      const payment = await Payment.create({
        reservation: reservation._id,
        amount: 10000,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        status: 'pending',
        phoneNumber: '0102030405',
      });

      const runs = [];
      for (let i = 0; i < 5; i++) {
        const current = await Payment.findById(payment._id);
        runs.push(await applyPaymentPaid(current, { triggerPayout: false }));
      }
      const applied = runs.filter((r) => r.applied && !r.alreadyPaid);
      const already = runs.filter((r) => r.alreadyPaid);
      expect(applied.length).toBe(1);
      expect(already.length).toBe(4);
      const paidCount = await Payment.countDocuments({ _id: payment._id, status: 'paid' });
      expect(paidCount).toBe(1);
    });
  });

  describe('InventoryLock keys (UTC, ordre déterministe)', () => {
    it('hour cross-midnight verrouille les deux jours calendaires, triés', () => {
      const residenceId = 'abc123';
      const keys = inventoryDayKeys(
        residenceId,
        new Date('2026-08-22T23:00:00.000Z'),
        new Date('2026-08-23T02:00:00.000Z')
      );
      expect(keys).toEqual([
        `${residenceId}:2026-08-22`,
        `${residenceId}:2026-08-23`,
      ]);
      const sorted = [...keys].sort();
      expect(keys).toEqual(sorted);
    });

    it('un TransientTransactionError épuisé n\'est pas présenté comme DATE_CONFLICT', async () => {
      const err = new Error('WriteConflict');
      err.code = 112;
      err.codeName = 'WriteConflict';
      err.errorLabels = ['TransientTransactionError'];
      await expect(
        withRetry(async () => {
          throw err;
        }, 3)
      ).rejects.toMatchObject({
        statusCode: 503,
        errorCode: errorCodes.GENERAL.SERVICE_UNAVAILABLE,
      });
      const mapped = mapInventoryError(err);
      expect(mapped.statusCode).toBe(503);
      expect(mapped.errorCode).not.toBe(errorCodes.RESERVATION.DATE_CONFLICT);
    });

    it('index unique InventoryLock.key présent sur le replica de test', async () => {
      await InventoryLock.syncIndexes();
      const indexes = await InventoryLock.collection.indexes();
      const uniqueKey = indexes.find((idx) => idx.key && idx.key.key === 1 && idx.unique === true);
      expect(uniqueKey).toBeTruthy();
    });
  });

  describe('Hour cross-midnight', () => {
    it('22 23:00→23 02:00 vs 23 00:00→23 01:00 = REFUSÉ', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy, { pricePeriod: 'hour' });
      await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2026-08-22T23:00:00.000Z'),
        checkOut: new Date('2026-08-23T02:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'hour',
      });
      const clientB = await User.create({
        email: `mid-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'B',
        lastName: 'B',
        role: 'client',
      });
      await expect(
        createReservation({
          residence: residence._id,
          user: clientB._id,
          checkIn: new Date('2026-08-23T00:00:00.000Z'),
          checkOut: new Date('2026-08-23T01:00:00.000Z'),
          numberOfGuests: 1,
          bookingType: 'hour',
        })
      ).rejects.toMatchObject({ statusCode: 409 });
    });
  });

  describe('Modify concurrent', () => {
    it('modify vs modify vers une plage chevauchante → au plus une réussit', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      const resA = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2027-03-10T14:00:00.000Z'),
        checkOut: new Date('2027-03-12T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      const clientB = await User.create({
        email: `modb-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'B',
        lastName: 'B',
        role: 'client',
      });
      const resB = await createReservation({
        residence: residence._id,
        user: clientB._id,
        checkIn: new Date('2027-03-20T14:00:00.000Z'),
        checkOut: new Date('2027-03-22T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });

      const results = await Promise.allSettled([
        modifyReservation(
          resA._id,
          {
            checkIn: new Date('2027-03-10T14:00:00.000Z'),
            checkOut: new Date('2027-03-18T11:00:00.000Z'),
          },
          client._id.toString()
        ),
        modifyReservation(
          resB._id,
          {
            checkIn: new Date('2027-03-14T14:00:00.000Z'),
            checkOut: new Date('2027-03-22T11:00:00.000Z'),
          },
          clientB._id.toString()
        ),
      ]);

      const ok = results.filter((r) => r.status === 'fulfilled');
      const ko = results.filter((r) => r.status === 'rejected');
      if (ok.length !== 1) {
        const detail = results.map((r) => ({
          status: r.status,
          message: r.reason?.message,
          statusCode: r.reason?.statusCode,
          errorCode: r.reason?.errorCode,
        }));
        throw new Error(`modify vs modify attendu 1 succès, reçu ${ok.length}: ${JSON.stringify(detail)}`);
      }
      expect(ko.length).toBe(1);
      expect([400, 409, 503]).toContain(ko[0].reason.statusCode);

      const live = await Reservation.find({
        residence: residence._id,
        status: { $in: ['payment_pending', 'pending', 'confirmed', 'in_stay'] },
      });
      expect(live).toHaveLength(2);
      const [x, y] = live;
      const overlap = x.checkIn < y.checkOut && x.checkOut > y.checkIn;
      expect(overlap).toBe(false);
    });

    it('create vs modify (A étend 10→18 pendant que B crée 15→20) → pas de chevauchement', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      const resA = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2027-04-10T14:00:00.000Z'),
        checkOut: new Date('2027-04-15T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      const clientB = await User.create({
        email: `cm-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'B',
        lastName: 'B',
        role: 'client',
      });

      const results = await Promise.allSettled([
        modifyReservation(
          resA._id,
          {
            checkIn: new Date('2027-04-10T14:00:00.000Z'),
            checkOut: new Date('2027-04-18T11:00:00.000Z'),
          },
          client._id.toString()
        ),
        createReservation({
          residence: residence._id,
          user: clientB._id,
          checkIn: new Date('2027-04-15T14:00:00.000Z'),
          checkOut: new Date('2027-04-20T11:00:00.000Z'),
          numberOfGuests: 1,
          bookingType: 'day',
        }),
      ]);

      const live = await Reservation.find({
        residence: residence._id,
        status: { $in: ['payment_pending', 'pending', 'confirmed', 'in_stay'] },
      });
      expect(live.length).toBeGreaterThanOrEqual(1);
      expect(live.length).toBeLessThanOrEqual(2);
      if (live.length === 2) {
        const [x, y] = live;
        expect(x.checkIn < y.checkOut && x.checkOut > y.checkIn).toBe(false);
      }
      const rejected = results.filter((r) => r.status === 'rejected');
      if (rejected.length) {
        expect([400, 409]).toContain(rejected[0].reason.statusCode);
      }
    });
  });

  describe('approval_required ne peut pas être confirmé sans approve', () => {
    it('webhook / applyPaymentPaid ne confirme pas awaiting_approval', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy, { reservationMode: 'approval_required' });
      const reservation = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2026-12-10T14:00:00.000Z'),
        checkOut: new Date('2026-12-12T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      expect(reservation.status).toBe('awaiting_approval');

      const payment = await Payment.create({
        reservation: reservation._id,
        amount: 10000,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        status: 'pending',
        phoneNumber: '0102030405',
      });
      const result = await applyPaymentPaid(payment, { triggerPayout: false });
      expect(result.refundRequired).toBe(true);
      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.status).toBe('awaiting_approval');
      expect(fresh.status).not.toBe('confirmed');
    });

    it('ReservationStateService refuse awaiting_approval → confirmed', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy, { reservationMode: 'approval_required' });
      const reservation = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2026-12-20T14:00:00.000Z'),
        checkOut: new Date('2026-12-22T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      await Reservation.updateOne(
        { _id: reservation._id },
        { $set: { paymentStatus: 'paid' } }
      );
      await expect(
        ReservationStateService.updateStatus(
          reservation._id,
          'confirmed',
          partner._id,
          { reason: 'admin bypass' }
        )
      ).rejects.toMatchObject({ statusCode: 403 });
      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.status).toBe('awaiting_approval');
    });
  });

  describe('P0-05 refund orchestration', () => {
    afterEach(() => setRefundAdapter(null));

    it('Wave / pas d’API auto → ops queue, pas de faux refunded', async () => {
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      const reservation = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2027-05-10T14:00:00.000Z'),
        checkOut: new Date('2027-05-12T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      const payment = await Payment.create({
        reservation: reservation._id,
        amount: 10000,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        status: 'paid',
        phoneNumber: '0102030405',
      });
      await markRefundRequired(payment, 'inventory_taken');
      const result = await processPaymentRefund(payment._id);
      expect(result.opsRequired).toBe(true);
      const fresh = await Payment.findById(payment._id);
      expect(fresh.status).toBe('paid');
      expect(fresh.refundStatus).toBe('required');
      expect(fresh.refundOpsRequired).toBe(true);
    });

    it('job Stripe mock → refunded', async () => {
      setRefundAdapter({
        refund: async () => ({ id: 're_test_1' }),
      });
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      const reservation = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2027-05-20T14:00:00.000Z'),
        checkOut: new Date('2027-05-22T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      const payment = await Payment.create({
        reservation: reservation._id,
        amount: 10000,
        paymentMethod: 'card',
        paymentProvider: 'stripe',
        transactionId: `pi_${Date.now()}`,
        status: 'paid',
      });
      await markRefundRequired(payment, 'inventory_taken');
      const result = await processPaymentRefund(payment._id);
      expect(result.refunded).toBe(true);
      const fresh = await Payment.findById(payment._id);
      expect(fresh.status).toBe('refunded');
      expect(fresh.refundStatus).toBe('succeeded');
      expect(fresh.refundProviderRef).toBe('re_test_1');
    });

    it('provider down → failed puis retry → refunded', async () => {
      let n = 0;
      setRefundAdapter({
        refund: async () => {
          n += 1;
          if (n < 3) {
            const err = new Error('provider_down');
            err.retryable = true;
            throw err;
          }
          return { id: 're_after_retry' };
        },
      });
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      const reservation = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2027-06-01T14:00:00.000Z'),
        checkOut: new Date('2027-06-03T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      const payment = await Payment.create({
        reservation: reservation._id,
        amount: 10000,
        paymentMethod: 'card',
        paymentProvider: 'stripe',
        transactionId: `pi_retry_${Date.now()}`,
        status: 'paid',
      });
      await markRefundRequired(payment, 'inventory_taken');
      await expect(processPaymentRefund(payment._id)).rejects.toThrow('provider_down');
      expect((await Payment.findById(payment._id)).refundStatus).toBe('failed');
      await expect(processPaymentRefund(payment._id)).rejects.toThrow('provider_down');
      const ok = await processPaymentRefund(payment._id);
      expect(ok.refunded).toBe(true);
      expect((await Payment.findById(payment._id)).status).toBe('refunded');
    });

    it('5 exécutions du job → un seul remboursement financier', async () => {
      let calls = 0;
      setRefundAdapter({
        refund: async () => {
          calls += 1;
          return { id: 're_once' };
        },
      });
      const { partner, client, policy } = await seedActors();
      const residence = await seedResidence(partner, policy);
      const reservation = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2027-06-10T14:00:00.000Z'),
        checkOut: new Date('2027-06-12T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      const payment = await Payment.create({
        reservation: reservation._id,
        amount: 10000,
        paymentMethod: 'card',
        paymentProvider: 'stripe',
        transactionId: `pi_idemp_${Date.now()}`,
        status: 'paid',
      });
      await markRefundRequired(payment, 'inventory_taken');
      const runs = await Promise.all(
        Array.from({ length: 5 }, () => processPaymentRefund(payment._id))
      );
      const applied = runs.filter((r) => r.applied && r.refunded);
      expect(applied.length).toBe(1);
      expect(calls).toBe(1);
      expect(await Payment.countDocuments({ _id: payment._id, status: 'refunded' })).toBe(1);
    });
  });

  describe('invariant métier approval_required — tous chemins publics', () => {
    function invoke(handler, req) {
      return new Promise((resolve, reject) => {
        const res = {
          status(code) {
            this.statusCode = code;
            return this;
          },
          json(body) {
            this.body = body;
            resolve({ statusCode: this.statusCode || 200, body });
            return this;
          },
        };
        handler(req, res, (err) => {
          if (err) reject(err);
          else resolve({ statusCode: res.statusCode || 200, body: res.body });
        });
      });
    }

    it('aucun chemin public ne confirme avant approve ; après approve+pay → confirmed', async () => {
      const { partner, client, policy } = await seedActors();
      const admin = await User.create({
        email: `adm-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'Ad',
        lastName: 'Min',
        role: 'admin',
      });
      const residence = await seedResidence(partner, policy, { reservationMode: 'approval_required' });
      const reservation = await createReservation({
        residence: residence._id,
        user: client._id,
        checkIn: new Date('2027-07-10T14:00:00.000Z'),
        checkOut: new Date('2027-07-12T11:00:00.000Z'),
        numberOfGuests: 1,
        bookingType: 'day',
      });
      expect(reservation.status).toBe('awaiting_approval');

      const payment = await Payment.create({
        reservation: reservation._id,
        amount: 10000,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        status: 'pending',
        phoneNumber: '0102030405',
      });

      const webhook = await applyPaymentPaid(payment, { triggerPayout: false, allowExpired: true });
      expect(webhook.refundRequired).toBe(true);
      expect((await Reservation.findById(reservation._id)).status).toBe('awaiting_approval');

      await expect(
        invoke(reservationController.confirmPayment, {
          params: { id: reservation._id },
          user: { _id: client._id, role: 'client' },
          body: { paymentMethod: 'wave' },
        })
      ).rejects.toMatchObject({ statusCode: 403 });

      await expect(
        invoke(reservationController.updateReservationStatus, {
          params: { id: reservation._id },
          user: { _id: partner._id, role: 'partner' },
          body: { status: 'confirmed', reason: 'partner generic' },
        })
      ).rejects.toMatchObject({ statusCode: 403 });

      await expect(
        invoke(reservationController.updateReservationStatus, {
          params: { id: reservation._id },
          user: { _id: admin._id, role: 'admin' },
          body: { status: 'confirmed', reason: 'admin' },
        })
      ).rejects.toMatchObject({ statusCode: 403 });

      expect((await Reservation.findById(reservation._id)).status).not.toBe('confirmed');

      const approved = await invoke(reservationController.approveReservation, {
        params: { id: reservation._id },
        user: { _id: partner._id, role: 'partner' },
        body: {},
      });
      expect(approved.statusCode).toBe(200);
      expect((await Reservation.findById(reservation._id)).status).toBe('payment_pending');

      const pay2 = await Payment.create({
        reservation: reservation._id,
        amount: 10000,
        paymentMethod: 'wave',
        paymentProvider: 'wave',
        status: 'pending',
        phoneNumber: '0102030405',
      });
      const paid = await applyPaymentPaid(pay2, { triggerPayout: false });
      expect(paid.refundRequired).not.toBe(true);
      expect((await Reservation.findById(reservation._id)).status).toBe('confirmed');
    });
  });
});
