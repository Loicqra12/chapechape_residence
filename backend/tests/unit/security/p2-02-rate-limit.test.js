process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci_at_least_32_chars_ok';
process.env.RATE_LIMIT_USE_MEMORY = 'true';
process.env.TRUST_PROXY = '0';

const request = require('supertest');
const express = require('express');
const { resolveTrustProxySetting } = require('../../../src/runtime/trust-proxy');
const {
  buildLimiter,
  POLICIES,
  useMemoryStore,
  createStore,
  subnetSafeIp,
  isWebhookPath,
  authRegisterLimiter,
} = require('../../../src/middlewares/rate-limit.middleware');

jest.setTimeout(60000);

function mount(limiter, { trustProxy = false } = {}) {
  const app = express();
  app.set('trust proxy', trustProxy);
  app.use(express.json());
  app.post('/login', limiter, (req, res) => res.json({ ok: true, ip: req.ip }));
  app.post('/otp', limiter, (req, res) => res.json({ ok: true }));
  app.post('/pay', limiter, (req, res) => res.json({ ok: true }));
  app.get('/ops', limiter, (req, res) => res.json({ ok: true }));
  app.get('/me', (req, res, next) => {
    if (req.headers['x-user']) req.user = { _id: req.headers['x-user'] };
    next();
  }, limiter, (req, res) => res.json({ ok: true }));
  return app;
}

describe('P2-02F trust proxy / rate limit', () => {
  it('policies fail-open lectures/auth limiter vs fail-closed OTP/finance/staff', () => {
    expect(POLICIES.PUBLIC.failClosed).toBe(false);
    expect(POLICIES.AUTH_LOGIN_IP.failClosed).toBe(false);
    expect(POLICIES.OTP_SEND_PHONE.failClosed).toBe(true);
    expect(POLICIES.OTP_VERIFY.failClosed).toBe(true);
    expect(POLICIES.FINANCIAL.failClosed).toBe(true);
    expect(POLICIES.STAFF_MUTATION.failClosed).toBe(true);
  });

  it('refuse trust proxy true aveugle', () => {
    expect(resolveTrustProxySetting({ TRUST_PROXY: 'true' })).toBe(1);
    expect(resolveTrustProxySetting({ TRUST_PROXY: '0' })).toBe(false);
    expect(resolveTrustProxySetting({ TRUST_PROXY: 'false' })).toBe(false);
    expect(resolveTrustProxySetting({ TRUST_PROXY: 'true', TRUST_PROXY_ALLOW_TRUE: '1' })).toBe(true);
    expect(resolveTrustProxySetting({ TRUST_PROXY_HOPS: '2' })).toBe(2);
  });

  it('NODE_ENV=test → MemoryStore ; createStore undefined', () => {
    expect(useMemoryStore()).toBe(true);
    expect(createStore('unit')).toBeUndefined();
  });

  it('IPv6 : même préfixe /64 → même clé', () => {
    expect(subnetSafeIp('2001:db8:abcd:1234:1::1')).toBe(subnetSafeIp('2001:db8:abcd:1234:ffff::2'));
    expect(subnetSafeIp('10.0.0.1')).toBe('10.0.0.1');
  });

  it('client direct : X-Forwarded-For / X-Real-IP / x-mobile-app ne contournent pas', async () => {
    const limiter = buildLimiter({ ...POLICIES.AUTH_LOGIN_IP, name: 'SPOOF_IP', max: 3, windowMs: 60_000 });
    const app = mount(limiter, { trustProxy: false });

    for (let i = 0; i < 3; i += 1) {
      const res = await request(app)
        .post('/login')
        .set('X-Forwarded-For', `1.1.1.${i}`)
        .set('X-Real-IP', '8.8.8.8')
        .set('x-mobile-app', 'true')
        .send({ email: 'a@b.com' });
      expect(res.status).toBe(200);
    }

    const blocked = await request(app)
      .post('/login')
      .set('X-Forwarded-For', '9.9.9.9, 2.2.2.2')
      .set('Forwarded', 'for=1.1.1.1')
      .set('CF-Connecting-IP', '1.1.1.1')
      .send({ email: 'other@b.com' });
    expect(blocked.status).toBe(429);
    expect(blocked.body.code).toBe('RATE_LIMIT_EXCEEDED');
    expect(blocked.body.success).toBe(false);
    expect(blocked.headers['retry-after']).toBeTruthy();
    expect(blocked.body.retryAfter).toBeGreaterThan(0);
  });

  it('proxy de confiance (hops=1) : vraie IP extraite de X-Forwarded-For', async () => {
    const limiter = buildLimiter({ ...POLICIES.AUTH_LOGIN_IP, name: 'PROXY_IP', max: 2, windowMs: 60_000 });
    const app = mount(limiter, { trustProxy: 1 });

    expect((await request(app).post('/login').set('X-Forwarded-For', '203.0.113.10').send({})).status).toBe(200);
    expect((await request(app).post('/login').set('X-Forwarded-For', '203.0.113.10').send({})).status).toBe(200);
    expect((await request(app).post('/login').set('X-Forwarded-For', '203.0.113.10').send({})).status).toBe(429);
    expect((await request(app).post('/login').set('X-Forwarded-For', '203.0.113.99').send({})).status).toBe(200);
  });

  it('login limité par identifier même si l’IP change', async () => {
    const limiter = buildLimiter({ ...POLICIES.AUTH_LOGIN_ACCOUNT, name: 'LOGIN_ACCT', max: 2, windowMs: 60_000 });
    const app = mount(limiter, { trustProxy: 1 });

    expect((await request(app).post('/login').set('X-Forwarded-For', '10.0.0.1').send({ email: 'victim@test.com' })).status).toBe(200);
    expect((await request(app).post('/login').set('X-Forwarded-For', '10.0.0.2').send({ email: 'Victim@test.com' })).status).toBe(200);
    expect((await request(app).post('/login').set('X-Forwarded-For', '10.0.0.3').send({ email: 'victim@test.com' })).status).toBe(429);
    expect((await request(app).post('/login').set('X-Forwarded-For', '10.0.0.3').send({ email: 'other@test.com' })).status).toBe(200);
  });

  it('OTP send limité par téléphone E.164 normalisé', async () => {
    const limiter = buildLimiter({ ...POLICIES.OTP_SEND_PHONE, name: 'OTP_PHONE', max: 2, windowMs: 60_000 });
    const app = mount(limiter, { trustProxy: false });

    expect((await request(app).post('/otp').send({ phoneNumber: '07 75 75 75 75', countryCode: 'CI' })).status).toBe(200);
    expect((await request(app).post('/otp').send({ phoneNumber: '0775757575', countryCode: 'CI' })).status).toBe(200);
    expect((await request(app).post('/otp').send({ phoneNumber: '0775757575', countryCode: 'CI' })).status).toBe(429);
    expect((await request(app).post('/otp').send({ phoneNumber: '0700000002', countryCode: 'CI' })).status).toBe(200);
  });

  it('OTP verify bruteforce limité (indépendant du send)', async () => {
    const limiter = buildLimiter({ ...POLICIES.OTP_VERIFY, name: 'OTP_VF', max: 3, windowMs: 60_000 });
    const app = mount(limiter, { trustProxy: 1 });
    const body = { phoneNumber: '0700000099', countryCode: 'CI', code: '000000' };

    for (let i = 0; i < 3; i += 1) {
      expect((await request(app).post('/otp').set('X-Forwarded-For', `11.0.0.${i}`).send(body)).status).toBe(200);
    }
    expect((await request(app).post('/otp').set('X-Forwarded-For', '11.0.0.9').send(body)).status).toBe(429);
  });

  it('inscription Partner reste fluide (40/15 min, 8 essais OK)', async () => {
    const app = express();
    app.set('trust proxy', false);
    app.use(express.json());
    app.post('/api/auth/register-partner', authRegisterLimiter, (req, res) => res.status(201).json({ ok: true }));
    for (let i = 0; i < 8; i += 1) {
      expect((await request(app).post('/api/auth/register-partner').send({})).status).toBe(201);
    }
  });

  it('utilisateur authentifié : clé userId, pas seulement IP NAT', async () => {
    const limiter = buildLimiter({ ...POLICIES.AUTHENTICATED, name: 'NAT_USER', max: 2, windowMs: 60_000 });
    const app = mount(limiter, { trustProxy: 1 });
    const ip = { 'X-Forwarded-For': '198.51.100.1' };

    expect((await request(app).get('/me').set(ip).set('x-user', 'u1')).status).toBe(200);
    expect((await request(app).get('/me').set(ip).set('x-user', 'u1')).status).toBe(200);
    expect((await request(app).get('/me').set(ip).set('x-user', 'u1')).status).toBe(429);
    expect((await request(app).get('/me').set(ip).set('x-user', 'u2')).status).toBe(200);
  });

  it('route financière : policy dédiée plus stricte', async () => {
    const limiter = buildLimiter({ ...POLICIES.FINANCIAL, name: 'FIN_T', max: 2, windowMs: 60_000 });
    const app = mount(limiter);
    expect((await request(app).post('/pay').send({})).status).toBe(200);
    expect((await request(app).post('/pay').send({})).status).toBe(200);
    const blocked = await request(app).post('/pay').send({});
    expect(blocked.status).toBe(429);
    expect(blocked.body.code).toBe('RATE_LIMIT_EXCEEDED');
  });

  it('Admin Ops conserve une limite exploitable', async () => {
    const limiter = buildLimiter({ ...POLICIES.ADMIN, name: 'OPS_T', max: 8, windowMs: 60_000 });
    const app = mount(limiter);
    for (let i = 0; i < 8; i += 1) {
      expect((await request(app).get('/ops')).status).toBe(200);
    }
    expect((await request(app).get('/ops')).status).toBe(429);
  });

  it('webhooks PSP skip le limiter utilisateur', async () => {
    expect(isWebhookPath({ originalUrl: '/api/payments/wave/webhook', path: '/webhook' })).toBe(true);
    expect(isWebhookPath({ originalUrl: '/api/payouts/cinetpay/webhook', path: '/cinetpay/webhook' })).toBe(true);
    expect(isWebhookPath({ originalUrl: '/api/payments', path: '/payments' })).toBe(false);

    const limiter = buildLimiter(
      { ...POLICIES.PUBLIC, name: 'WH_SKIP', max: 2, windowMs: 60_000 },
      { skip: (req) => isWebhookPath(req) }
    );
    const app = express();
    app.set('trust proxy', false);
    app.use('/api/', limiter);
    app.post('/api/payments/wave/webhook', (req, res) => res.status(200).json({ received: true }));
    app.get('/api/residences', (req, res) => res.json({ ok: true }));

    for (let i = 0; i < 8; i += 1) {
      expect((await request(app).post('/api/payments/wave/webhook').send({})).status).toBe(200);
    }
    expect((await request(app).get('/api/residences')).status).toBe(200);
    expect((await request(app).get('/api/residences')).status).toBe(200);
    expect((await request(app).get('/api/residences')).status).toBe(429);
  });
});
