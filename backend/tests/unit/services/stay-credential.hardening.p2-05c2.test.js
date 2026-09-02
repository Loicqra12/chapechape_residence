process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci_at_least_32_chars_ok';

const request = require('supertest');
const express = require('express');
const mongoose = require('mongoose');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const { generateAccessToken } = require('../../../src/utils/jwt');
const { errorHandler } = require('../../../src/middlewares/error.middleware');
const reservationRoutes = require('../../../src/routes/reservation.routes');
const stayCredentialService = require('../../../src/services/stay-credential.service');
const ReservationStateService = require('../../../src/services/reservation-state.service');
const {
  hashCredential,
  generateCredential,
} = require('../../../src/security/stay-credential');
const errorCodes = require('../../../src/utils/errorCodes');
const { residenceAttrs, reservationSnapshotAttrs } = require('../../helpers/residence.fixture');
const SocketService = require('../../../src/services/socket.service');
const { scheduleReviewReminder } = require('../../../src/services/agenda.service');

jest.setTimeout(180000);

jest.mock('../../../src/services/socket.service', () => ({
  notifyReservationStatusUpdate: jest.fn().mockResolvedValue(undefined),
  notifyBlockedDatesUpdate: jest.fn().mockResolvedValue(undefined),
  notifyNewReservation: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('../../../src/services/agenda.service', () => ({
  scheduleReviewReminder: jest.fn().mockResolvedValue(undefined),
}));

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
  const stamp = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const partner = await User.create({
    email: `p-${stamp}@test.com`,
    password: 'Test1234',
    firstName: 'Part',
    lastName: 'Ner',
    role: 'partner',
    isPhoneVerified: true,
    phoneNumber: '+2250700000201',
  });
  const otherPartner = await User.create({
    email: `op-${stamp}@test.com`,
    password: 'Test1234',
    firstName: 'Other',
    lastName: 'Partner',
    role: 'partner',
    isPhoneVerified: true,
    phoneNumber: '+2250700000202',
  });
  const client = await User.create({
    email: `c-${stamp}@test.com`,
    password: 'Test1234',
    firstName: 'Cli',
    lastName: 'Ent',
    role: 'client',
  });
  const policy = await CancellationPolicy.create({
    name: `pol-${stamp}`,
    description: 'Test',
    isDefault: true,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  const residence = await Residence.create(
    residenceAttrs({
      partner: partner._id,
      cancellationPolicy: policy._id,
    })
  );
  return { partner, otherPartner, client, policy, residence };
}

async function seedPaidConfirmed(actors, overrides = {}) {
  return Reservation.create({
    user: actors.client._id,
    partner: actors.partner._id,
    residence: actors.residence._id,
    cancellationPolicy: actors.policy._id,
    checkIn: overrides.checkIn || new Date(Date.now() + 60 * 60 * 1000),
    checkOut: overrides.checkOut || new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
    numberOfGuests: 1,
    totalPrice: 40000,
    status: overrides.status || 'confirmed',
    paymentStatus: overrides.paymentStatus || 'paid',
    actualCheckIn: overrides.actualCheckIn || null,
    ...reservationSnapshotAttrs(),
  });
}

const CHECKIN_INDEX = {
  key: { 'stayCredentials.checkIn.tokenHash': 1 },
  name: 'stay_cred_checkin_hash_unique',
  unique: true,
  partialFilterExpression: {
    'stayCredentials.checkIn.tokenHash': { $exists: true, $type: 'string' },
  },
};

const CHECKOUT_INDEX = {
  key: { 'stayCredentials.checkOut.tokenHash': 1 },
  name: 'stay_cred_checkout_hash_unique',
  unique: true,
  partialFilterExpression: {
    'stayCredentials.checkOut.tokenHash': { $exists: true, $type: 'string' },
  },
};

describe('P2-05C2 final hardening', () => {
  beforeEach(() => {
    SocketService.notifyReservationStatusUpdate.mockClear();
    scheduleReviewReminder.mockClear();
  });

  describe('GATE A — concurrent issuance', () => {
    it('20 concurrent issues → unique versions, one active hash, Option B last-wins', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);

      const results = await Promise.all(
        Array.from({ length: 20 }, () =>
          request(app)
            .post(`/api/reservations/${reservation._id}/stay-credentials`)
            .set('Authorization', authHeader(actors.client))
            .send({ purpose: 'checkin' })
        )
      );

      const successes = results.filter((r) => r.status === 200);
      expect(successes.length).toBeGreaterThanOrEqual(1);
      expect(successes.every((r) => r.status === 200 || r.status === 409)).toBe(true);
      // All HTTP outcomes must be success or controlled conflict
      expect(results.every((r) => [200, 409].includes(r.status))).toBe(true);

      const versions = successes.map((r) => r.body.data.version).sort((a, b) => a - b);
      expect(new Set(versions).size).toBe(versions.length);

      const stored = await Reservation.findById(reservation._id).select('+stayCredentials').lean();
      expect(stored.stayCredentials.checkIn.tokenHash).toBeTruthy();
      expect(typeof stored.stayCredentials.checkIn.tokenHash).toBe('string');
      expect(JSON.stringify(stored)).not.toMatch(/CCSTAY1\./);

      const activeHash = stored.stayCredentials.checkIn.tokenHash;
      const matching = successes.filter(
        (r) => hashCredential(r.body.data.credential) === activeHash
      );
      expect(matching).toHaveLength(1);
      expect(stored.stayCredentials.checkIn.version).toBe(Math.max(...versions));

      // Earlier returned credentials are invalid at resolve
      const stale = successes.find(
        (r) => hashCredential(r.body.data.credential) !== activeHash
      );
      if (stale) {
        const resolve = await request(app)
          .post('/api/reservations/stay-credentials/resolve')
          .set('Authorization', authHeader(actors.partner))
          .send({ credential: stale.body.data.credential, purpose: 'checkin' });
        expect(resolve.status).toBe(400);
      }
    });
  });

  describe('GATE B — regeneration vs consumption', () => {
    it('regeneration wins: A invalid, B commit ok', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const a = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );
      const b = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      const commitA = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: a.credential });
      expect(commitA.status).toBe(400);

      const commitB = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: b.credential });
      expect(commitB.status).toBe(200);
      expect(commitB.body.data.status).toBe('in_stay');
    });

    it('consumption wins: post in_stay check-in issue NOT_ELIGIBLE, no active check-in cred', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const a = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );
      await stayCredentialService.commitWithCredential(
        reservation._id,
        'checkin',
        a.credential,
        actors.partner
      );

      const regen = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.client))
        .send({ purpose: 'checkin' });
      expect(regen.status).toBe(400);
      expect(regen.body.code).toBe(errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE);

      const stored = await Reservation.findById(reservation._id).select('+stayCredentials');
      expect(stored.status).toBe('in_stay');
      expect(stored.stayCredentials.checkIn.consumedAt).toBeTruthy();
    });

    it('checkout: consumption wins → no new checkout credential', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      await ReservationStateService.updateStatus(reservation._id, 'in_stay', actors.partner._id, {
        reason: 'setup',
        fromStatuses: ['confirmed'],
      });
      const a = await stayCredentialService.issueCredential(
        reservation._id,
        'checkout',
        actors.client
      );
      await stayCredentialService.commitWithCredential(
        reservation._id,
        'checkout',
        a.credential,
        actors.partner
      );

      const regen = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.client))
        .send({ purpose: 'checkout' });
      expect(regen.status).toBe(400);
      expect(regen.body.code).toBe(errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE);

      const stored = await Reservation.findById(reservation._id).select('+stayCredentials');
      expect(stored.status).toBe('completed');
      expect(stored.stayCredentials.checkOut.consumedAt).toBeTruthy();
    });
  });

  describe('GATE C — unique partial indexes', () => {
    it('100 legacy docs + real index create + duplicate hash rejected', async () => {
      const actors = await seedActors();
      const docs = [];
      for (let i = 0; i < 100; i += 1) {
        docs.push({
          user: actors.client._id,
          partner: actors.partner._id,
          residence: actors.residence._id,
          cancellationPolicy: actors.policy._id,
          checkIn: new Date(Date.now() + (i + 1) * 86400000),
          checkOut: new Date(Date.now() + (i + 2) * 86400000),
          numberOfGuests: 1,
          totalPrice: 1000,
          status: 'pending',
          paymentStatus: 'pending',
          ...reservationSnapshotAttrs(),
        });
      }
      await Reservation.insertMany(docs);

      const col = mongoose.connection.db.collection('reservations');
      // Drop schema-auto indexes with same name if present, recreate explicitly
      try {
        await col.dropIndex(CHECKIN_INDEX.name);
      } catch (_) {
        /* absent */
      }
      try {
        await col.dropIndex(CHECKOUT_INDEX.name);
      } catch (_) {
        /* absent */
      }

      await col.createIndex(CHECKIN_INDEX.key, {
        unique: CHECKIN_INDEX.unique,
        name: CHECKIN_INDEX.name,
        partialFilterExpression: CHECKIN_INDEX.partialFilterExpression,
      });
      await col.createIndex(CHECKOUT_INDEX.key, {
        unique: CHECKOUT_INDEX.unique,
        name: CHECKOUT_INDEX.name,
        partialFilterExpression: CHECKOUT_INDEX.partialFilterExpression,
      });

      const indexes = await col.indexes();
      expect(indexes.some((i) => i.name === CHECKIN_INDEX.name && i.unique)).toBe(true);
      expect(indexes.some((i) => i.name === CHECKOUT_INDEX.name && i.unique)).toBe(true);

      const hash = hashCredential(generateCredential().credential);
      const a = await seedPaidConfirmed(actors);
      await Reservation.updateOne(
        { _id: a._id },
        { $set: { 'stayCredentials.checkIn.tokenHash': hash, 'stayCredentials.checkIn.version': 1 } }
      );

      const b = await seedPaidConfirmed(actors);
      await expect(
        Reservation.updateOne(
          { _id: b._id },
          { $set: { 'stayCredentials.checkIn.tokenHash': hash, 'stayCredentials.checkIn.version': 1 } }
        )
      ).rejects.toThrow(/E11000|duplicate/i);

      const hashOut = hashCredential(generateCredential().credential);
      await Reservation.updateOne(
        { _id: a._id },
        { $set: { 'stayCredentials.checkOut.tokenHash': hashOut, 'stayCredentials.checkOut.version': 1 } }
      );
      await expect(
        Reservation.updateOne(
          { _id: b._id },
          {
            $set: {
              'stayCredentials.checkOut.tokenHash': hashOut,
              'stayCredentials.checkOut.version': 1,
            },
          }
        )
      ).rejects.toThrow(/E11000|duplicate/i);
    });
  });

  describe('GATE D — idempotent retry security', () => {
    it('same Partner retry → alreadyApplied without side effects', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      const first = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential });
      expect(first.status).toBe(200);
      expect(first.body.alreadyApplied).toBe(false);

      const historyAfterFirst = (await Reservation.findById(reservation._id)).statusHistory.length;
      const actualCheckIn = (await Reservation.findById(reservation._id)).actualCheckIn;
      SocketService.notifyReservationStatusUpdate.mockClear();
      scheduleReviewReminder.mockClear();

      const retry = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential });
      expect(retry.status).toBe(200);
      expect(retry.body.alreadyApplied).toBe(true);

      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.statusHistory).toHaveLength(historyAfterFirst);
      expect(fresh.actualCheckIn.getTime()).toBe(actualCheckIn.getTime());
      expect(SocketService.notifyReservationStatusUpdate).not.toHaveBeenCalled();
      expect(scheduleReviewReminder).not.toHaveBeenCalled();
    });

    it('wrong Partner never alreadyApplied', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );
      await stayCredentialService.commitWithCredential(
        reservation._id,
        'checkin',
        issued.credential,
        actors.partner
      );

      const res = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.otherPartner))
        .send({ credential: issued.credential });
      expect(res.status).toBe(403);
      expect(res.body.alreadyApplied).not.toBe(true);
    });

    it('wrong Reservation never alreadyApplied', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservationA = await seedPaidConfirmed(actors);
      const reservationB = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservationA._id,
        'checkin',
        actors.client
      );
      await stayCredentialService.commitWithCredential(
        reservationA._id,
        'checkin',
        issued.credential,
        actors.partner
      );

      const res = await request(app)
        .patch(`/api/reservations/${reservationB._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential });
      expect(res.status).toBe(400);
      expect(res.body.alreadyApplied).not.toBe(true);
    });

    it('wrong purpose never alreadyApplied', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );
      await stayCredentialService.commitWithCredential(
        reservation._id,
        'checkin',
        issued.credential,
        actors.partner
      );

      const res = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkout`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential });
      expect(res.status).toBe(400);
      expect(res.body.code).toBe(errorCodes.STAY_CREDENTIAL.PURPOSE_MISMATCH);
      expect(res.body.alreadyApplied).not.toBe(true);
    });

    it('different credential on already in_stay never alreadyApplied', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      await ReservationStateService.updateStatus(reservation._id, 'in_stay', actors.partner._id, {
        reason: 'manual',
        fromStatuses: ['confirmed'],
      });
      const fake = generateCredential().credential;

      const res = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: fake });
      expect(res.status).toBe(400);
      expect(res.body.alreadyApplied).not.toBe(true);
    });

    it('checkout retry alreadyApplied matrix', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      await ReservationStateService.updateStatus(reservation._id, 'in_stay', actors.partner._id, {
        reason: 'setup',
        fromStatuses: ['confirmed'],
      });
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkout',
        actors.client
      );

      const first = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkout`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential });
      expect(first.body.alreadyApplied).toBe(false);
      const historyLen = (await Reservation.findById(reservation._id)).statusHistory.length;
      scheduleReviewReminder.mockClear();

      const retry = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkout`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential });
      expect(retry.status).toBe(200);
      expect(retry.body.alreadyApplied).toBe(true);
      expect((await Reservation.findById(reservation._id)).statusHistory).toHaveLength(historyLen);
      expect(scheduleReviewReminder).not.toHaveBeenCalled();
    });
  });

  describe('serialization regression', () => {
    it('GET paths never leak stayCredentials via toJSON', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      for (const user of [actors.client, actors.partner]) {
        const res = await request(app)
          .get(`/api/reservations/${reservation._id}`)
          .set('Authorization', authHeader(user));
        const raw = JSON.stringify(res.body);
        expect(raw).not.toContain('stayCredentials');
        expect(raw).not.toContain('tokenHash');
        expect(raw).not.toContain(issued.credential);
      }
    });
  });
});
