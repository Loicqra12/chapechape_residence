/**
 * P2-08C — CSRF production contract (real csrf-custom.middleware + app.js wiring)
 */
const request = require('supertest');
const app = require('../../../src/app');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
const errorCodes = require('../../../src/utils/errorCodes');
const { residenceAttrs } = require('../../helpers/residence.fixture');
const { authHeader } = require('../../helpers/factories');

jest.setTimeout(120000);

const CSRF_PROTECTED_ROUTE = '/api/users/register';

function registerPayload() {
  const id = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  return {
    firstName: 'Csrf',
    lastName: 'Test',
    email: `csrf-${id}@test.com`,
    password: 'Test1234!',
    phone: '+2250700000100',
  };
}

async function fetchCsrfContext() {
  const agent = request.agent(app);
  const tokenRes = await agent.get('/api/csrf-token');
  expect(tokenRes.status).toBe(200);
  expect(tokenRes.body.success).toBe(true);
  expect(typeof tokenRes.body.csrfToken).toBe('string');
  expect(tokenRes.headers['x-csrf-token']).toBe(tokenRes.body.csrfToken);
  return { agent, token: tokenRes.body.csrfToken };
}

async function seedPublishedResidence() {
  const partner = await User.create({
    email: `p-csrf-${Date.now()}@test.com`,
    password: 'Test1234!',
    firstName: 'Partner',
    lastName: 'Csrf',
    role: 'partner',
  });
  const policy = await CancellationPolicy.create({
    name: `policy-csrf-${Date.now()}`,
    description: 'CSRF test policy',
    isDefault: true,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  const residence = await Residence.create(residenceAttrs({
    partner: partner._id,
    cancellationPolicy: policy._id,
    reservationMode: 'instant',
    paymentTTLMinutes: 60,
    publicationStatus: 'published',
    pricePeriod: 'day',
    hourlyRates: { oneHour: 5000, twoHours: 8000, threeHours: 10000, additionalHour: 2000 },
  }));
  return { partner, residence };
}

function futureStay(daysFromNow = 14, nights = 3) {
  const checkIn = new Date();
  checkIn.setDate(checkIn.getDate() + daysFromNow);
  checkIn.setHours(14, 0, 0, 0);
  const checkOut = new Date(checkIn);
  checkOut.setDate(checkOut.getDate() + nights);
  checkOut.setHours(11, 0, 0, 0);
  return { checkIn, checkOut };
}

describe('P2-08C CSRF production contract', () => {
  describe('route matrix evidence', () => {
    it('documents /api/users as CSRF-protected in app.js', () => {
      const source = require('fs').readFileSync(
        require('path').join(__dirname, '../../../src/app.js'),
        'utf8'
      );
      expect(source).toMatch(/app\.use\("\/api\/users", csrfMiddleware\)/);
      expect(source).not.toMatch(/app\.use\("\/api\/reservations", csrfMiddleware\)/);
      expect(source).toMatch(/\/api\/payments.*DÉSACTIVÉ|\/\/ app\.use\("\/api\/payments", csrfMiddleware\)/);
    });
  });

  describe('protected web route — POST /api/users/register', () => {
    it('rejects missing CSRF token with 403 GENERAL_CSRF_ERROR', async () => {
      const res = await request(app)
        .post(CSRF_PROTECTED_ROUTE)
        .send(registerPayload());

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.errorCode).toBe(errorCodes.GENERAL.CSRF_ERROR);
    });

    it('rejects invalid CSRF token with 403 GENERAL_CSRF_ERROR', async () => {
      const { agent } = await fetchCsrfContext();
      const res = await agent
        .post(CSRF_PROTECTED_ROUTE)
        .set('x-csrf-token', 'invalid-token-not-matching-cookie')
        .send(registerPayload());

      expect(res.status).toBe(403);
      expect(res.body.errorCode).toBe(errorCodes.GENERAL.CSRF_ERROR);
    });

    it('accepts valid double-submit CSRF and reaches business handler', async () => {
      const { agent, token } = await fetchCsrfContext();
      const payload = registerPayload();

      const res = await agent
        .post(CSRF_PROTECTED_ROUTE)
        .set('x-csrf-token', token)
        .send(payload);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.token).toBeDefined();
      expect(res.body.errorCode).not.toBe(errorCodes.GENERAL.CSRF_ERROR);
    });

    it('mobile Bearer bypass passes CSRF on protected route without token header', async () => {
      const client = await User.create({
        email: `mobile-csrf-${Date.now()}@test.com`,
        password: 'Test1234!',
        firstName: 'Mobile',
        lastName: 'Client',
        role: 'client',
      });
      const bearer = authHeader(client);

      const res = await request(app)
        .post(CSRF_PROTECTED_ROUTE)
        .set('Authorization', bearer)
        .set('x-mobile-app', 'true')
        .send(registerPayload());

      expect(res.status).not.toBe(403);
      expect(res.body.errorCode).not.toBe(errorCodes.GENERAL.CSRF_ERROR);
    });
  });

  describe('mobile reservation API — not web-CSRF scoped', () => {
    it('POST /api/reservations without CSRF is not rejected by csrfProtection', async () => {
      const client = await User.create({
        email: `res-csrf-${Date.now()}@test.com`,
        password: 'Test1234!',
        firstName: 'Res',
        lastName: 'Client',
        role: 'client',
      });
      const { residence } = await seedPublishedResidence();
      const { checkIn, checkOut } = futureStay();
      const bearer = authHeader(client);

      const res = await request(app)
        .post('/api/reservations')
        .set('Authorization', bearer)
        .set('x-mobile-app', 'true')
        .send({
          residence: residence._id.toString(),
          checkIn: checkIn.toISOString(),
          checkOut: checkOut.toISOString(),
          numberOfGuests: 1,
        });

      expect(res.body.errorCode).not.toBe(errorCodes.GENERAL.CSRF_ERROR);
      expect(res.status).not.toBe(403);
      expect([201, 400, 409, 422, 500]).toContain(res.status);
    });
  });
});
