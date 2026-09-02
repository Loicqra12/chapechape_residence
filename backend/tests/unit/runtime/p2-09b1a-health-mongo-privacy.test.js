/**
 * P2-09B1A — Health endpoints must not expose Mongo identity (Ops-only).
 */
const request = require('supertest');
const app = require('../../../src/app');
const readiness = require('../../../src/runtime/readiness');

jest.setTimeout(120000);

const FORBIDDEN_KEYS = [
  'mongoFingerprint',
  'mongoFingerprintExpected',
  'mongoFingerprintMatch',
  'MONGODB_URI',
];

const FORBIDDEN_VALUE_PATTERNS = [
  /mongodb(\+srv)?:\/\//i,
  /ondigitalocean\.com/i,
  /efebb871c934cf3c/,
  /4f095ad783737882/,
];

function assertNoMongoIdentityExposure(body) {
  const serialized = JSON.stringify(body);
  for (const key of FORBIDDEN_KEYS) {
    expect(body).not.toHaveProperty(key);
  }
  for (const pattern of FORBIDDEN_VALUE_PATTERNS) {
    expect(serialized).not.toMatch(pattern);
  }
}

describe('P2-09B1A health mongo privacy', () => {
  afterEach(() => {
    readiness.resetForTests();
  });

  it('GET /api/health ne expose pas fingerprint/host/db URI', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(['connected', 'disconnected']).toContain(res.body.database);
    expect(['available', 'unavailable']).toContain(res.body.transactions);
    assertNoMongoIdentityExposure(res.body);
  });

  it('GET /api/health/ready ne expose pas fingerprint/host/db URI', async () => {
    readiness.markReady();
    const res = await request(app).get('/api/health/ready');
    expect([200, 503]).toContain(res.status);
    expect(res.body).toHaveProperty('checks');
    expect(['connected', 'disconnected']).toContain(res.body.checks.mongo);
    expect(['available', 'unavailable']).toContain(res.body.checks.transactions);
    assertNoMongoIdentityExposure(res.body);
    if (res.body.runtime) {
      assertNoMongoIdentityExposure(res.body.runtime);
    }
  });

  it('GET /api/health/live conserve le contrat liveness minimal', async () => {
    const res = await request(app).get('/api/health/live');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('alive');
    assertNoMongoIdentityExposure(res.body);
  });
});
