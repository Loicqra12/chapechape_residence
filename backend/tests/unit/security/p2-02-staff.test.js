process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci_at_least_32_chars_ok';

const request = require('supertest');
const express = require('express');
const User = require('../../../src/models/user.model');
const OpsAuditLog = require('../../../src/models/ops-audit-log.model');
const { generateAccessToken } = require('../../../src/utils/jwt');
const { errorHandler } = require('../../../src/middlewares/error.middleware');
const superAdminRoutes = require('../../../src/routes/superadmin.routes');
const adminRoutes = require('../../../src/routes/admin.routes');
const partnerRoutes = require('../../../src/routes/partner.routes');

jest.setTimeout(120000);

function authHeader(user) {
  return `Bearer ${generateAccessToken(user._id.toString(), user.role)}`;
}

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/superadmin', superAdminRoutes);
  app.use('/api/admin', adminRoutes);
  app.use('/api/partners', partnerRoutes);
  app.use(errorHandler);
  return app;
}

async function makeUser(role, extra = {}) {
  const stamp = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  return User.create({
    email: `${role}-${stamp}@test.com`,
    password: 'Test1234',
    firstName: role,
    lastName: 'User',
    role,
    ...extra,
  });
}

describe('P2-02E staff / superadmin', () => {
  const app = createApp();

  it('anonymous / client / partner / admin : settings et create-admin refusés', async () => {
    const client = await makeUser('client');
    const partner = await makeUser('partner');
    const admin = await makeUser('admin');

    expect((await request(app).get('/api/superadmin/settings')).status).toBe(401);

    for (const [user, expected] of [[client, 403], [partner, 403], [admin, 403]]) {
      const settings = await request(app)
        .get('/api/superadmin/settings')
        .set('Authorization', authHeader(user));
      expect(settings.status).toBe(expected);

      const created = await request(app)
        .post('/api/superadmin/admins')
        .set('Authorization', authHeader(user))
        .send({
          email: `new-${Date.now()}@test.com`,
          password: 'Test1234',
          firstName: 'New',
          lastName: 'Admin',
        });
      expect(created.status).toBe(expected);

      const viaAdminApi = await request(app)
        .post('/api/admin/admins')
        .set('Authorization', authHeader(user))
        .send({
          email: `new2-${Date.now()}@test.com`,
          password: 'Test1234',
          firstName: 'New',
          lastName: 'Admin',
        });
      expect(viaAdminApi.status).toBe(expected);
    }
  });

  it('superadmin GET settings 200 ; PUT refuse mass assignment ; admin 403', async () => {
    const admin = await makeUser('admin');
    const superadmin = await makeUser('superadmin');

    const asAdmin = await request(app)
      .put('/api/superadmin/settings')
      .set('Authorization', authHeader(admin))
      .send({ 'payment.secretKey': 'steal' });
    expect(asAdmin.status).toBe(403);

    const getSa = await request(app)
      .get('/api/superadmin/settings')
      .set('Authorization', authHeader(superadmin));
    expect(getSa.status).toBe(200);

    const bad = await request(app)
      .put('/api/superadmin/settings')
      .set('Authorization', authHeader(superadmin))
      .send({ 'payment.secretKey': 'steal', jwtSecret: 'x' });
    expect(bad.status).toBe(400);

    const ok = await request(app)
      .put('/api/superadmin/settings')
      .set('Authorization', authHeader(superadmin))
      .send({ 'maintenance.banner': 'Ops window', reason: 'banner' });
    expect(ok.status).toBe(200);
    const logged = await OpsAuditLog.findOne({ action: 'settings_changed' });
    expect(logged).toBeTruthy();
    expect(logged.actorRole).toBe('superadmin');
  });

  it('création admin : superadmin only ; body.role ignoré', async () => {
    const superadmin = await makeUser('superadmin');
    const res = await request(app)
      .post('/api/superadmin/admins')
      .set('Authorization', authHeader(superadmin))
      .send({
        email: `created-${Date.now()}@test.com`,
        password: 'Test1234',
        firstName: 'Staff',
        lastName: 'Admin',
        role: 'superadmin',
      });
    expect(res.status).toBe(201);
    expect(res.body.data.role).toBe('admin');
    const audit = await OpsAuditLog.findOne({ action: 'admin_created', entityId: res.body.data._id });
    expect(audit).toBeTruthy();
  });

  it('Admin ne mute pas un rôle ; Superadmin mute + audit ; dernier superadmin protégé', async () => {
    const client = await makeUser('client');
    const admin = await makeUser('admin');
    const superadmin = await makeUser('superadmin');

    const asAdminUp = await request(app)
      .post(`/api/superadmin/users/${client._id}/role`)
      .set('Authorization', authHeader(admin))
      .send({ role: 'superadmin', reason: 'elevate' });
    expect(asAdminUp.status).toBe(403);

    const asAdminDown = await request(app)
      .post(`/api/superadmin/users/${admin._id}/role`)
      .set('Authorization', authHeader(admin))
      .send({ role: 'client', reason: 'demote peer' });
    expect(asAdminDown.status).toBe(403);

    const viaGeneric = await request(app)
      .put(`/api/admin/users/${client._id}`)
      .set('Authorization', authHeader(admin))
      .send({ role: 'superadmin' });
    expect(viaGeneric.status).toBe(200);
    const stillClient = await User.findById(client._id);
    expect(stillClient.role).toBe('client');

    const mutate = await request(app)
      .post(`/api/superadmin/users/${client._id}/role`)
      .set('Authorization', authHeader(superadmin))
      .send({ role: 'partner', reason: 'ops reclassement' });
    expect(mutate.status).toBe(200);
    expect(mutate.body.data.role).toBe('partner');
    const roleLog = await OpsAuditLog.findOne({ action: 'role_changed', entityId: client._id });
    expect(roleLog.before.role).toBe('client');
    expect(roleLog.after.role).toBe('partner');

    const last = await request(app)
      .post(`/api/superadmin/users/${superadmin._id}/role`)
      .set('Authorization', authHeader(superadmin))
      .send({ role: 'admin', reason: 'self demote' });
    expect(last.status).toBe(403);

    const delLast = await request(app)
      .delete(`/api/superadmin/admins/${superadmin._id}`)
      .set('Authorization', authHeader(superadmin));
    expect(delLast.status).toBe(403);
  });

  it('deux rétrogradations concurrentes ne laissent pas 0 superadmin', async () => {
    const a = await makeUser('superadmin');
    const b = await makeUser('superadmin');

    const [r1, r2] = await Promise.all([
      request(app)
        .post(`/api/superadmin/users/${a._id}/role`)
        .set('Authorization', authHeader(b))
        .send({ role: 'admin', reason: 'concurrent-a' }),
      request(app)
        .post(`/api/superadmin/users/${b._id}/role`)
        .set('Authorization', authHeader(a))
        .send({ role: 'admin', reason: 'concurrent-b' }),
    ]);

    const statuses = [r1.status, r2.status].sort();
    expect(statuses).toEqual([200, 403]);
    const remaining = await User.countDocuments({ role: 'superadmin', isActive: { $ne: false } });
    expect(remaining).toBe(1);
  });

  it('rôle JWT spoofé ignoré : client + claim superadmin → 403 ; superadmin + claim client → 200', async () => {
    const client = await makeUser('client');
    const superadmin = await makeUser('superadmin');

    const spoofed = await request(app)
      .get('/api/superadmin/settings')
      .set('Authorization', `Bearer ${generateAccessToken(client._id.toString(), 'superadmin')}`);
    expect(spoofed.status).toBe(403);

    const realSa = await request(app)
      .get('/api/superadmin/settings')
      .set('Authorization', `Bearer ${generateAccessToken(superadmin._id.toString(), 'client')}`);
    expect(realSa.status).toBe(200);
  });

  it('P1-07 Ops reste admin ; superadmin n’accède pas au dashboard Partner', async () => {
    const admin = await makeUser('admin');
    const superadmin = await makeUser('superadmin');

    const ops = await request(app)
      .get('/api/admin/ops/reservations')
      .set('Authorization', authHeader(admin));
    expect(ops.status).toBe(200);

    const partnerDash = await request(app)
      .get('/api/partners/dashboard/overview')
      .set('Authorization', authHeader(superadmin));
    expect(partnerDash.status).toBe(403);
  });
});
