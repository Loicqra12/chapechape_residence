process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci_at_least_32_chars_ok';

const request = require('supertest');
const express = require('express');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const { generateAccessToken } = require('../../../src/utils/jwt');
const { errorHandler } = require('../../../src/middlewares/error.middleware');
const reservationRoutes = require('../../../src/routes/reservation.routes');
const ReservationStateService = require('../../../src/services/reservation-state.service');
const stayCredentialService = require('../../../src/services/stay-credential.service');
const {
  generateCredential,
  parseCredential,
  hashCredential,
  isCredentialExpired,
  ENTROPY_BYTES,
  VERSION_PREFIX,
} = require('../../../src/security/stay-credential');
const errorCodes = require('../../../src/utils/errorCodes');
const { residenceAttrs, reservationSnapshotAttrs } = require('../../helpers/residence.fixture');
const { checkinReservation: opsCheckin } = require('../../../src/services/ops-admin.service');

jest.setTimeout(180000);

jest.mock('../../../src/services/socket.service', () => ({
  notifyReservationStatusUpdate: jest.fn().mockResolvedValue(undefined),
  notifyBlockedDatesUpdate: jest.fn().mockResolvedValue(undefined),
  notifyNewReservation: jest.fn().mockResolvedValue(undefined),
}));

jest.mock('../../../src/services/agenda.service', () => ({
  scheduleReviewReminder: jest.fn().mockResolvedValue(undefined),
}));

const logger = require('../../../src/utils/logger');

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
    phoneNumber: '+2250700000101',
  });
  const otherPartner = await User.create({
    email: `op-${stamp}@test.com`,
    password: 'Test1234',
    firstName: 'Other',
    lastName: 'Partner',
    role: 'partner',
    isPhoneVerified: true,
    phoneNumber: '+2250700000102',
  });
  const client = await User.create({
    email: `c-${stamp}@test.com`,
    password: 'Test1234',
    firstName: 'Cli',
    lastName: 'Ent',
    role: 'client',
  });
  const otherClient = await User.create({
    email: `oc-${stamp}@test.com`,
    password: 'Test1234',
    firstName: 'Other',
    lastName: 'Client',
    role: 'client',
  });
  const admin = await User.create({
    email: `a-${stamp}@test.com`,
    password: 'Test1234',
    firstName: 'Ad',
    lastName: 'Min',
    role: 'admin',
  });
  const policy = await CancellationPolicy.create({
    name: `policy-${stamp}`,
    description: 'Test',
    isDefault: true,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  const residence = await Residence.create(
    residenceAttrs({
      partner: partner._id,
      cancellationPolicy: policy._id,
      reservationMode: 'instant',
    })
  );
  return { partner, otherPartner, client, otherClient, admin, policy, residence };
}

async function seedPaidConfirmed(actors, overrides = {}) {
  const checkIn = overrides.checkIn || new Date(Date.now() + 60 * 60 * 1000);
  const checkOut = overrides.checkOut || new Date(checkIn.getTime() + 5 * 24 * 60 * 60 * 1000);
  return Reservation.create({
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
    ...reservationSnapshotAttrs(),
  });
}

describe('P2-05C2 stay credentials', () => {
  describe('token format', () => {
    it('issues 256-bit opaque CCSTAY1 credential without PII', () => {
      const { credential, tokenHash } = generateCredential();
      expect(credential.startsWith(`${VERSION_PREFIX}.`)).toBe(true);
      const parsed = parseCredential(credential);
      expect(parsed).not.toBeNull();
      expect(parsed.tokenHash).toBe(tokenHash);
      expect(parsed.tokenHash).toBe(hashCredential(credential));
      expect(credential).not.toMatch(/@/);
      expect(credential.toLowerCase()).not.toContain('userid');
      expect(Buffer.from(credential.split('.')[1], 'base64url').length).toBe(ENTROPY_BYTES);
    });

    it('expiry boundary: now < expiresAt valid; now >= expiresAt expired', () => {
      const expiresAt = new Date('2026-08-27T12:00:00.000Z');
      expect(isCredentialExpired(expiresAt, new Date(expiresAt.getTime() - 1))).toBe(false);
      expect(isCredentialExpired(expiresAt, new Date(expiresAt.getTime()))).toBe(true);
      expect(isCredentialExpired(expiresAt, new Date(expiresAt.getTime() + 1))).toBe(true);
    });
  });

  describe('issuance', () => {
    it('Client owner issues check-in credential', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);

      const res = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.client))
        .send({ purpose: 'checkin' });

      expect(res.status).toBe(200);
      expect(res.body.data.credential).toMatch(/^CCSTAY1\./);
      expect(res.body.data.purpose).toBe('checkin');
      expect(res.body.data.version).toBe(1);

      const stored = await Reservation.findById(reservation._id).select('+stayCredentials');
      expect(stored.stayCredentials.checkIn.tokenHash).toBe(
        hashCredential(res.body.data.credential)
      );
      expect(JSON.stringify(stored.toJSON())).not.toContain('tokenHash');
      expect(JSON.stringify(stored.toJSON())).not.toContain('stayCredentials');
    });

    it('wrong Client cannot issue', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);

      const res = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.otherClient))
        .send({ purpose: 'checkin' });

      expect(res.status).toBe(403);
    });

    it('unpaid check-in issue rejected', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      await Reservation.updateOne({ _id: reservation._id }, { $set: { paymentStatus: 'pending' } });

      const res = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.client))
        .send({ purpose: 'checkin' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE);
    });

    it('too-early check-in issue rejected', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors, {
        checkIn: new Date(Date.now() + 6 * 60 * 60 * 1000),
      });

      const res = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.client))
        .send({ purpose: 'checkin' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(errorCodes.RESERVATION.CHECKIN_TOO_EARLY);
    });

    it('checkout issue before in_stay rejected', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);

      const res = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.client))
        .send({ purpose: 'checkout' });

      expect(res.status).toBe(400);
      expect(res.body.code).toBe(errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE);
    });

    it('regeneration invalidates previous token', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);

      const a = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.client))
        .send({ purpose: 'checkin' });
      const b = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.client))
        .send({ purpose: 'checkin' });

      expect(a.body.data.credential).not.toBe(b.body.data.credential);
      expect(b.body.data.version).toBe(2);

      const resolveA = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: a.body.data.credential, purpose: 'checkin' });
      expect(resolveA.status).toBe(400);
      expect(resolveA.body.code).toBe(errorCodes.STAY_CREDENTIAL.INVALID);

      const resolveB = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: b.body.data.credential, purpose: 'checkin' });
      expect(resolveB.status).toBe(200);
    });
  });

  describe('resolve', () => {
    it('resolve valid / expired / consumed / wrong purpose / wrong partner', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);

      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      const ok = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential, purpose: 'checkin' });
      expect(ok.status).toBe(200);
      expect(ok.body.data.reservationId).toBe(String(reservation._id));
      expect(ok.body.data.email).toBeUndefined();
      expect(ok.body.data.phone).toBeUndefined();

      const wrongPurpose = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential, purpose: 'checkout' });
      expect(wrongPurpose.status).toBe(400);
      expect(wrongPurpose.body.code).toBe(errorCodes.STAY_CREDENTIAL.INVALID);

      const wrongPartner = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.otherPartner))
        .send({ credential: issued.credential, purpose: 'checkin' });
      expect(wrongPartner.status).toBe(400);
      expect(wrongPartner.body.code).toBe(errorCodes.STAY_CREDENTIAL.INVALID);
      expect(JSON.stringify(wrongPartner.body)).not.toContain(String(reservation._id));

      await Reservation.updateOne(
        { _id: reservation._id },
        { $set: { 'stayCredentials.checkIn.expiresAt': new Date(Date.now() - 1000) } }
      );
      const expired = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential, purpose: 'checkin' });
      expect(expired.body.code).toBe(errorCodes.STAY_CREDENTIAL.EXPIRED);

      await Reservation.updateOne(
        { _id: reservation._id },
        {
          $set: {
            'stayCredentials.checkIn.expiresAt': new Date(Date.now() + 600000),
            'stayCredentials.checkIn.consumedAt': new Date(),
          },
        }
      );
      const consumed = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential, purpose: 'checkin' });
      expect(consumed.body.code).toBe(errorCodes.STAY_CREDENTIAL.CONSUMED);
    });

    it('resolve unpaid / cancelled not eligible', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      await Reservation.updateOne({ _id: reservation._id }, { $set: { paymentStatus: 'pending' } });
      const unpaid = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential, purpose: 'checkin' });
      expect(unpaid.body.code).toBe(errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE);

      await Reservation.collection.updateOne(
        { _id: reservation._id },
        { $set: { status: 'cancelled', paymentStatus: 'paid' } }
      );
      const cancelled = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential, purpose: 'checkin' });
      expect(cancelled.body.code).toBe(errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE);
    });
  });

  describe('canonical commit', () => {
    it('normal credential check-in and checkout', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const checkinCred = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      const cin = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: checkinCred.credential });
      expect(cin.status).toBe(200);
      expect(cin.body.data.status).toBe('in_stay');
      expect(cin.body.alreadyApplied).toBe(false);

      const checkoutCred = await stayCredentialService.issueCredential(
        reservation._id,
        'checkout',
        actors.client
      );
      const cout = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkout`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: checkoutCred.credential });
      expect(cout.status).toBe(200);
      expect(cout.body.data.status).toBe('completed');
    });

    it('checkin credential cannot checkout (purpose mismatch)', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const checkinCred = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );
      await ReservationStateService.updateStatus(reservation._id, 'in_stay', actors.partner._id, {
        reason: 'setup',
        fromStatuses: ['confirmed'],
      });

      const res = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkout`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: checkinCred.credential });
      expect(res.status).toBe(400);
      expect(res.body.code).toBe(errorCodes.STAY_CREDENTIAL.PURPOSE_MISMATCH);
    });

    it('20 concurrent credential check-ins → one transition', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      const results = await Promise.all(
        Array.from({ length: 20 }, () =>
          request(app)
            .patch(`/api/reservations/${reservation._id}/checkin`)
            .set('Authorization', authHeader(actors.partner))
            .send({ credential: issued.credential })
        )
      );

      const applied = results.filter((r) => r.status === 200 && r.body.alreadyApplied === false);
      const retries = results.filter((r) => r.status === 200 && r.body.alreadyApplied === true);
      expect(applied).toHaveLength(1);
      expect(applied.length + retries.length).toBeGreaterThanOrEqual(1);

      const fresh = await Reservation.findById(reservation._id).select('+stayCredentials');
      expect(fresh.status).toBe('in_stay');
      expect(fresh.statusHistory.filter((h) => h.status === 'in_stay')).toHaveLength(1);
      expect(fresh.stayCredentials.checkIn.consumedAt).toBeTruthy();
    });

    it('20 concurrent credential checkouts → one transition', async () => {
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

      const results = await Promise.all(
        Array.from({ length: 20 }, () =>
          request(app)
            .patch(`/api/reservations/${reservation._id}/checkout`)
            .set('Authorization', authHeader(actors.partner))
            .send({ credential: issued.credential })
        )
      );
      const applied = results.filter((r) => r.status === 200 && r.body.alreadyApplied === false);
      expect(applied).toHaveLength(1);
      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.status).toBe('completed');
      expect(fresh.statusHistory.filter((h) => h.status === 'completed')).toHaveLength(1);
    });

    it('network retry idempotent after success', async () => {
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
      expect(first.body.alreadyApplied).toBe(false);

      const retry = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: issued.credential });
      expect(retry.status).toBe(200);
      expect(retry.body.alreadyApplied).toBe(true);

      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.statusHistory.filter((h) => h.status === 'in_stay')).toHaveLength(1);
    });

    it('QR vs manual race → one transition', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      const [a, b] = await Promise.all([
        request(app)
          .patch(`/api/reservations/${reservation._id}/checkin`)
          .set('Authorization', authHeader(actors.partner))
          .send({ credential: issued.credential }),
        request(app)
          .patch(`/api/reservations/${reservation._id}/checkin`)
          .set('Authorization', authHeader(actors.partner))
          .send({}),
      ]);

      const successes = [a, b].filter((r) => r.status === 200 && r.body.alreadyApplied !== true);
      const appliedOrIdempotent = [a, b].filter((r) => r.status === 200);
      expect(successes.length + ([a, b].filter((r) => r.status === 409 || r.status === 400).length)).toBeGreaterThanOrEqual(1);
      expect(appliedOrIdempotent.length).toBeGreaterThanOrEqual(1);

      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.status).toBe('in_stay');
      expect(fresh.statusHistory.filter((h) => h.status === 'in_stay')).toHaveLength(1);
    });

    it('QR vs Ops race → one transition', async () => {
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      const results = await Promise.allSettled([
        stayCredentialService.commitWithCredential(
          reservation._id,
          'checkin',
          issued.credential,
          actors.partner
        ),
        opsCheckin(reservation._id, actors.admin, { reason: 'ops race' }),
      ]);

      const fresh = await Reservation.findById(reservation._id);
      expect(fresh.status).toBe('in_stay');
      expect(fresh.statusHistory.filter((h) => h.status === 'in_stay')).toHaveLength(1);
      expect(results.filter((r) => r.status === 'fulfilled').length).toBeGreaterThanOrEqual(1);
    });

    it('scan vs regeneration: old invalid, winner coherent', async () => {
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

      const stale = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: a.credential });
      expect(stale.status).toBe(400);

      const freshCommit = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: b.credential });
      expect(freshCommit.status).toBe(200);

      const regenAfter = await request(app)
        .post(`/api/reservations/${reservation._id}/stay-credentials`)
        .set('Authorization', authHeader(actors.client))
        .send({ purpose: 'checkin' });
      expect(regenAfter.status).toBe(400);
      expect(regenAfter.body.code).toBe(errorCodes.STAY_CREDENTIAL.NOT_ELIGIBLE);
    });

    it('manual P2-05B check-in/checkout still works without credential', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);

      const cin = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({});
      expect(cin.status).toBe(200);
      expect(cin.body.data.status).toBe('in_stay');

      const cout = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkout`)
        .set('Authorization', authHeader(actors.partner))
        .send({});
      expect(cout.status).toBe(200);
      expect(cout.body.data.status).toBe('completed');
    });

    it('/status stay bypass still blocked', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const res = await request(app)
        .patch(`/api/reservations/${reservation._id}/status`)
        .set('Authorization', authHeader(actors.partner))
        .send({ status: 'in_stay' });
      expect(res.body.code).toBe(errorCodes.RESERVATION.STAY_ACTION_REQUIRED);
    });
  });

  describe('legacy + serialization + logs', () => {
    it('legacy Math.random qrCode never accepted', async () => {
      const app = createApp();
      const actors = await seedActors();
      const legacy = Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);
      const reservation = await seedPaidConfirmed(actors);
      await Reservation.updateOne(
        { _id: reservation._id },
        {
          $set: {
            qrCode: {
              checkInCode: legacy,
              checkOutCode: legacy + 'x',
              generatedAt: new Date(),
            },
          },
        }
      );

      const resolve = await request(app)
        .post('/api/reservations/stay-credentials/resolve')
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: legacy, purpose: 'checkin' });
      expect(resolve.status).toBe(400);
      expect(resolve.body.code).toBe(errorCodes.STAY_CREDENTIAL.INVALID);

      const commit = await request(app)
        .patch(`/api/reservations/${reservation._id}/checkin`)
        .set('Authorization', authHeader(actors.partner))
        .send({ credential: legacy });
      expect(commit.status).toBe(400);
      expect(commit.body.code).toBe(errorCodes.STAY_CREDENTIAL.INVALID);
    });

    it('GET reservation never leaks stayCredentials or raw credential', async () => {
      const app = createApp();
      const actors = await seedActors();
      const reservation = await seedPaidConfirmed(actors);
      const issued = await stayCredentialService.issueCredential(
        reservation._id,
        'checkin',
        actors.client
      );

      const getClient = await request(app)
        .get(`/api/reservations/${reservation._id}`)
        .set('Authorization', authHeader(actors.client));
      expect(getClient.status).toBe(200);
      const bodyStr = JSON.stringify(getClient.body);
      expect(bodyStr).not.toContain('stayCredentials');
      expect(bodyStr).not.toContain('tokenHash');
      expect(bodyStr).not.toContain(issued.credential);

      const getPartner = await request(app)
        .get(`/api/reservations/${reservation._id}`)
        .set('Authorization', authHeader(actors.partner));
      expect(JSON.stringify(getPartner.body)).not.toContain('tokenHash');
    });

    it('logger events never include raw credential', async () => {
      const spy = jest.spyOn(logger, 'info');
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

      const logged = spy.mock.calls.map((c) => JSON.stringify(c)).join('\n');
      expect(logged).not.toContain(issued.credential);
      expect(logged).toMatch(/STAY_CREDENTIAL_ISSUED|STAY_CREDENTIAL_CONSUMED/);
      spy.mockRestore();
    });
  });
});
