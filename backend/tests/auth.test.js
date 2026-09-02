const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/user.model');

describe('Auth Routes', () => {
  const password = 'Password123!';

  it('POST /api/auth/register → 201 + token (rôle forcé client)', async () => {
    const email = `reg-${Date.now()}@test.com`;
    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email,
        password,
        firstName: 'Test',
        lastName: 'User',
        phoneNumber: '+2250700000101',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body).toHaveProperty('token');
    expect(res.body.user.email).toBe(email);
    expect(res.body.user.role).toBe('client');
  });

  it('POST /api/auth/register email déjà pris → 400', async () => {
    const email = `dup-${Date.now()}@test.com`;
    await User.create({
      email,
      password,
      firstName: 'A',
      lastName: 'B',
      role: 'client',
    });

    const res = await request(app)
      .post('/api/auth/register')
      .send({
        email,
        password,
        firstName: 'Test',
        lastName: 'User',
        phoneNumber: '+2250700000102',
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
  });

  it('POST /api/auth/login identifiants valides → 200 + token', async () => {
    const email = `login-${Date.now()}@test.com`;
    await User.create({
      email,
      password,
      firstName: 'Test',
      lastName: 'User',
      role: 'client',
    });

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email, password });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body).toHaveProperty('token');
  });

  it('POST /api/auth/login mot de passe incorrect → 401', async () => {
    const email = `bad-${Date.now()}@test.com`;
    await User.create({
      email,
      password,
      firstName: 'Test',
      lastName: 'User',
      role: 'client',
    });

    const res = await request(app)
      .post('/api/auth/login')
      .send({ email, password: 'WrongPass1!' });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });
});
