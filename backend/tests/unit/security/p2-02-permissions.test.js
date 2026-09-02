process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci_at_least_32_chars_ok';

const request = require('supertest');
const express = require('express');
const User = require('../../../src/models/user.model');
const { protect, authorize } = require('../../../src/middlewares/auth.middleware');
const { isAdmin, isPartner, isPartnerAccount, isSuperAdmin } = require('../../../src/lib/roleMiddleware');
const { generateAccessToken, verifyToken } = require('../../../src/utils/jwt');
const { pickUserSafePatch, ROLES } = require('../../../src/security/roles');
const { computeCapabilities } = require('../../../src/security/partner-capabilities');
const {
  csrfMiddleware,
  isAuthenticatedMobileRequest,
} = require('../../../src/middlewares/csrf-custom.middleware');
const adminRoutes = require('../../../src/routes/admin.routes');
const partnerRoutes = require('../../../src/routes/partner.routes');

jest.setTimeout(120000);

function errorHandler(err, req, res, next) {
  const status = err.statusCode || err.status || 500;
  res.status(status).json({ success: false, message: err.message });
}

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/admin', adminRoutes);
  app.use('/api/partners', partnerRoutes);

  app.get('/probe/partner-only', protect, authorize('partner'), (req, res) => {
    res.json({ ok: true, role: req.user.role });
  });
  app.get('/probe/partner-admin', protect, authorize('partner', 'admin'), (req, res) => {
    res.json({ ok: true, role: req.user.role });
  });
  app.post('/probe/payout-execute', protect, authorize('admin'), (req, res) => {
    res.json({ ok: true, role: req.user.role });
  });
  app.get('/probe/superadmin', protect, isSuperAdmin, (req, res) => {
    res.json({ ok: true });
  });
  app.get('/probe/staff', protect, isAdmin, (req, res) => {
    res.json({ ok: true });
  });
  app.get('/probe/validated-partner', protect, isPartner, (req, res) => {
    res.json({ ok: true });
  });
  app.get('/probe/partner-account', protect, isPartnerAccount, (req, res) => {
    res.json({ ok: true });
  });

  app.use(errorHandler);
  return app;
}

function authHeader(user) {
  return `Bearer ${generateAccessToken(user._id.toString(), user.role)}`;
}

async function seedUsers() {
  const stamp = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  const make = (role) => User.create({
    email: `${role}-${stamp}@test.com`,
    password: 'Test1234',
    firstName: role,
    lastName: 'User',
    role,
  });
  return {
    client: await make('client'),
    partnerPending: await make('partner_pending'),
    partner: await make('partner'),
    admin: await make('admin'),
    superadmin: await make('superadmin'),
    owner: await make('owner'),
  };
}

describe('P2-02 permissions', () => {
  const app = createApp();
  let users;

  beforeEach(async () => {
    users = await seedUsers();
  });

  describe('pickUserSafePatch', () => {
    it('retire role/password même si le body les envoie', () => {
      const patch = pickUserSafePatch({
        firstName: 'Ada',
        role: 'superadmin',
        password: 'hacked',
        isActive: false,
      });
      expect(patch.firstName).toBe('Ada');
      expect(patch.role).toBeUndefined();
      expect(patch.password).toBeUndefined();
      expect(patch.isActive).toBeUndefined();
    });

    it('autorise isActive seulement pour superadmin', () => {
      const patch = pickUserSafePatch({ isActive: false }, { allowActive: true });
      expect(patch.isActive).toBe(false);
    });
  });

  describe('anonymous → 401', () => {
    const paths = [
      ['GET', '/api/admin/ops/reservations'],
      ['POST', '/api/admin/ops/refunds/000000000000000000000000/confirm'],
      ['GET', '/api/partners/dashboard/overview'],
      ['GET', '/probe/partner-only'],
      ['POST', '/probe/payout-execute'],
    ];
    it.each(paths)('%s %s', async (method, path) => {
      const req = method === 'GET' ? request(app).get(path) : request(app).post(path);
      const res = await req;
      expect(res.status).toBe(401);
    });
  });

  describe('matrice rôles', () => {
    const cases = [
      ['client', 'GET', '/api/admin/ops/reservations', 403],
      ['partnerPending', 'GET', '/api/admin/ops/reservations', 403],
      ['partner', 'GET', '/api/admin/ops/reservations', 403],
      ['admin', 'GET', '/api/admin/ops/reservations', 200],
      ['superadmin', 'GET', '/api/admin/ops/reservations', 200],

      ['client', 'POST', '/api/admin/ops/refunds/aaaaaaaaaaaaaaaaaaaaaaaa/confirm', 403],
      ['partner', 'POST', '/api/admin/ops/refunds/aaaaaaaaaaaaaaaaaaaaaaaa/confirm', 403],
      ['partnerPending', 'POST', '/api/admin/ops/refunds/aaaaaaaaaaaaaaaaaaaaaaaa/confirm', 403],

      ['client', 'GET', '/api/partners/dashboard/overview', 403],
      ['partnerPending', 'GET', '/api/partners/capabilities', 200],
      ['partner', 'GET', '/api/partners/capabilities', 200],
      ['admin', 'GET', '/api/partners/dashboard/overview', 403],
      ['superadmin', 'GET', '/api/partners/dashboard/overview', 403],

      ['client', 'GET', '/probe/partner-account', 403],
      ['partnerPending', 'GET', '/probe/partner-account', 200],
      ['partner', 'GET', '/probe/partner-account', 200],

      ['client', 'GET', '/probe/partner-only', 403],
      ['partnerPending', 'GET', '/probe/partner-only', 200],
      ['partner', 'GET', '/probe/partner-only', 200],
      ['admin', 'GET', '/probe/partner-only', 403],
      ['superadmin', 'GET', '/probe/partner-only', 403],

      ['partner', 'GET', '/probe/partner-admin', 200],
      ['admin', 'GET', '/probe/partner-admin', 200],
      ['superadmin', 'GET', '/probe/partner-admin', 200],
      ['partnerPending', 'GET', '/probe/partner-admin', 200],
      ['client', 'GET', '/probe/partner-admin', 403],

      ['partner', 'POST', '/probe/payout-execute', 403],
      ['partnerPending', 'POST', '/probe/payout-execute', 403],
      ['client', 'POST', '/probe/payout-execute', 403],
      ['admin', 'POST', '/probe/payout-execute', 200],
      ['superadmin', 'POST', '/probe/payout-execute', 200],

      ['admin', 'POST', '/api/admin/admins', 403],
      ['client', 'GET', '/probe/superadmin', 403],
      ['admin', 'GET', '/probe/superadmin', 403],
      ['superadmin', 'GET', '/probe/superadmin', 200],
      ['owner', 'GET', '/api/admin/ops/reservations', 403],
    ];

    it.each(cases)('%s %s %s → %s', async (who, method, path, expected) => {
      const req = method === 'GET' ? request(app).get(path) : request(app).post(path).send({});
      const res = await req.set('Authorization', authHeader(users[who]));
      expect(res.status).toBe(expected);
    });
  });

  describe('JWT bypass', () => {
    it('ignore le rôle dans le token si la DB dit client', async () => {
      const forged = generateAccessToken(users.client._id.toString(), 'superadmin');
      const res = await request(app)
        .get('/api/admin/ops/reservations')
        .set('Authorization', `Bearer ${forged}`);
      expect(res.status).toBe(403);
    });

    it('rejette un JWT alg=none', async () => {
      const header = Buffer.from(JSON.stringify({ alg: 'none', typ: 'JWT' })).toString('base64url');
      const payload = Buffer.from(JSON.stringify({ id: users.admin._id.toString() })).toString('base64url');
      const noneToken = `${header}.${payload}.`;
      expect(() => verifyToken(noneToken, 'JWT_SECRET')).toThrow();
      const res = await request(app)
        .get('/api/admin/ops/reservations')
        .set('Authorization', `Bearer ${noneToken}`);
      expect(res.status).toBe(401);
    });
  });

  describe('CSRF mobile', () => {
    it('x-mobile-app sans Bearer n’est pas un bypass', () => {
      expect(isAuthenticatedMobileRequest({
        headers: { 'x-mobile-app': 'true' },
        path: '/api/users',
      })).toBe(false);
    });

    it('Bearer + x-mobile-app autorise le bypass', () => {
      expect(isAuthenticatedMobileRequest({
        headers: { authorization: 'Bearer abc', 'x-mobile-app': 'true' },
        path: '/api/users',
      })).toBe(true);
    });

    it('refuse POST cookie-only avec x-mobile-app forgé', async () => {
      const csrfApp = express();
      csrfApp.use(express.json());
      csrfApp.post('/api/users', csrfMiddleware, (req, res) => res.json({ ok: true }));
      csrfApp.use(errorHandler);
      const res = await request(csrfApp)
        .post('/api/users')
        .set('x-mobile-app', 'true')
        .send({ firstName: 'x' });
      expect(res.status).toBe(403);
    });
  });

  describe('mass assignment', () => {
    it('un admin ne peut pas s’auto-promouvoir superadmin via updateUser', async () => {
      const before = await User.findById(users.client._id);
      expect(before.role).toBe(ROLES.CLIENT);
      const res = await request(app)
        .put(`/api/admin/users/${users.client._id}`)
        .set('Authorization', authHeader(users.admin))
        .send({ role: 'superadmin', firstName: 'Hacked' });
      expect(res.status).toBe(200);
      expect(res.body.data.role).toBe('client');
      expect(res.body.data.firstName).toBe('Hacked');
      const after = await User.findById(users.client._id);
      expect(after.role).toBe('client');
    });
  });

  describe('capabilities Partner', () => {
    it('nouveau partner : produit ouvert, payout/publication fermés sans téléphone', () => {
      const caps = computeCapabilities({ role: 'partner', isPhoneVerified: false });
      expect(caps.canAccessPartnerApp).toBe(true);
      expect(caps.canCreateResidence).toBe(true);
      expect(caps.canManageCalendar).toBe(true);
      expect(caps.canCreateExternalBooking).toBe(true);
      expect(caps.canPublishResidence).toBe(false);
      expect(caps.canReceivePayout).toBe(false);
    });

    it('partner_pending a le même accès produit (alias legacy)', () => {
      const pending = computeCapabilities({ role: 'partner_pending', isPhoneVerified: false });
      const partner = computeCapabilities({ role: 'partner', isPhoneVerified: false });
      expect(pending.canCreateResidence).toBe(partner.canCreateResidence);
      expect(pending.canAccessPartnerApp).toBe(true);
    });

    it('téléphone vérifié débloque publication et payout legacy', () => {
      const caps = computeCapabilities({ role: 'partner', isPhoneVerified: true });
      expect(caps.canPublishResidence).toBe(true);
      expect(caps.canReceivePayout).toBe(true);
    });

    it('payout pending bloque l’argent, pas la création d’annonce', () => {
      const caps = computeCapabilities({
        role: 'partner',
        isPhoneVerified: true,
        verification: { payout: 'pending', identity: 'not_requested', property: 'not_required' },
      });
      expect(caps.canCreateResidence).toBe(true);
      expect(caps.canReceivePayout).toBe(false);
    });

    it('GET /api/partners/capabilities expose le calcul serveur', async () => {
      const res = await request(app)
        .get('/api/partners/capabilities')
        .set('Authorization', authHeader(users.partner));
      expect(res.status).toBe(200);
      expect(res.body.capabilities.canCreateResidence).toBe(true);
      expect(res.body.verification).toBeDefined();
    });
  });
});
