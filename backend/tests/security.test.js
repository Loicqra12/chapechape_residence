const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/user.model');
const LoginAttempt = require('../src/models/loginAttempt.model');
const { createClient } = require('./helpers/factories');

function expectRateLimited(res) {
  expect(res.status).toBe(429);
  expect(res.body.success).toBe(false);
  expect(res.body.code).toBe('RATE_LIMIT_EXCEEDED');
  expect(typeof res.body.retryAfter).toBe('number');
  expect(res.headers['retry-after']).toBeTruthy();
}

describe('Security Tests', () => {
  beforeEach(async () => {
    await LoginAttempt.deleteMany({});
  });

  describe('Rate limiting login (contrat P2-02F)', () => {
    it('limite les tentatives login : 429 + RATE_LIMIT_EXCEEDED + Retry-After', async () => {
      const user = await createClient({
        email: `rl-${Date.now()}@test.com`,
        password: 'Password123!',
      });

      let last;
      for (let i = 0; i < 9; i += 1) {
        last = await request(app)
          .post('/api/auth/login')
          .send({ email: user.email, password: 'wrongpassword' });
      }

      expectRateLimited(last);
    });
  });

  describe('Login security', () => {
    it('enregistre une LoginAttempt en échec', async () => {
      const user = await createClient({ password: 'Password123!' });
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: user.email, password: 'wrongpassword' });

      expect(res.status).toBe(401);

      const attempts = await LoginAttempt.find({ email: user.email, success: false });
      expect(attempts.length).toBeGreaterThanOrEqual(1);
    });

    it('un login réussi n’efface pas l’historique (audit, pas reset compteur)', async () => {
      const password = 'Password123!';
      const user = await createClient({ password });
      await request(app)
        .post('/api/auth/login')
        .send({ email: user.email, password: 'wrongpassword' });

      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: user.email, password });

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');

      const failed = await LoginAttempt.find({ email: user.email, success: false });
      expect(failed.length).toBeGreaterThanOrEqual(1);
    });
  });

  describe('Password', () => {
    it('refuse un mot de passe trop faible à l’inscription', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({
          email: `weak-${Date.now()}@test.com`,
          password: 'weak',
          firstName: 'Test',
          lastName: 'User',
          phoneNumber: '+2250700000099',
        });

      expect(res.status).toBe(400);
    });

    it('hashe le mot de passe en base', async () => {
      const password = 'Password123!';
      const user = await createClient({ password });
      const stored = await User.findById(user._id).select('+password');
      expect(stored.password).not.toBe(password);
    });
  });
});
