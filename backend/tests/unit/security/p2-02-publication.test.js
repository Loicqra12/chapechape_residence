process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci_at_least_32_chars_ok';

const request = require('supertest');
const express = require('express');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const { residenceAttrs } = require('../../helpers/residence.fixture');
const {
  requestPublication,
  isPubliclyListed,
  PUBLICATION,
} = require('../../../src/services/residence-publication.service');
const {
  canPublishResidence,
  canReceiveBookings,
  isLegacyPayoutEligible,
  computeCapabilities,
} = require('../../../src/security/partner-capabilities');
const { pickUserSafePatch } = require('../../../src/security/roles');
const { generateAccessToken } = require('../../../src/utils/jwt');
const { errorHandler } = require('../../../src/middlewares/error.middleware');
const residenceRoutes = require('../../../src/routes/residence.routes');

jest.setTimeout(120000);

function authHeader(user) {
  return `Bearer ${generateAccessToken(user._id.toString(), user.role)}`;
}

function createApp() {
  const app = express();
  app.use(express.json());
  app.use('/api/residences', residenceRoutes);
  app.use(errorHandler);
  return app;
}

const createPayload = {
  title: 'Studio Cocody test',
  description: 'Description test résidence assez longue',
  price: 1000,
  type: 'apartment',
  bedrooms: 1,
  bathrooms: 1,
  area: 40,
  maxOccupancy: 2,
  features: ['wifi'],
  location: {
    address: 'Rue Test 1',
    city: 'Abidjan',
    state: 'Lagunes',
    country: 'CI',
    coordinates: { latitude: 5.36, longitude: -4.01 },
  },
  publicationStatus: 'published',
  verified: true,
};

async function makeUser(role, extra = {}) {
  const stamp = `${Date.now()}-${Math.random().toString(16).slice(2)}`;
  return User.create({
    email: `${role}-${stamp}@test.com`,
    password: 'Test1234',
    firstName: role,
    lastName: 'User',
    role,
    isPhoneVerified: false,
    ...extra,
  });
}

describe('P2-02C publication capability', () => {
  it('canPublishResidence et canReceiveBookings restent deux concepts', () => {
    const unverified = { role: 'partner', isPhoneVerified: false };
    expect(canPublishResidence(unverified)).toBe(false);
    expect(canReceiveBookings(unverified)).toBe(false);
    const verified = { role: 'partner', isPhoneVerified: true };
    expect(canPublishResidence(verified)).toBe(true);
    expect(canReceiveBookings(verified)).toBe(true);
  });

  it('legacy payout : not_configured ≠ verified, exception explicite', () => {
    expect(isLegacyPayoutEligible({ payout: 'not_configured' })).toBe(true);
    expect(isLegacyPayoutEligible({ payout: 'verified' })).toBe(false);
    const caps = computeCapabilities({
      role: 'partner',
      isPhoneVerified: true,
      verification: { payout: 'not_configured', identity: 'not_requested', property: 'not_required' },
    });
    expect(caps.canReceivePayout).toBe(true);
  });

  it('création = draft, catalogue public ignore les drafts, legacy sans champ reste listé', async () => {
    const partner = await makeUser('partner');
    const draft = await Residence.create(residenceAttrs({
      partner: partner._id,
      publicationStatus: PUBLICATION.DRAFT,
    }));
    const legacy = await Residence.create(residenceAttrs({
      partner: partner._id,
      title: 'Legacy listed',
    }));
    expect(draft.publicationStatus).toBe('draft');
    expect(isPubliclyListed(draft)).toBe(false);
    expect(legacy.publicationStatus).toBeUndefined();
    expect(isPubliclyListed(legacy)).toBe(true);
  });

  it('Partner sans OTP : publication 403 CAPABILITY_REQUIRED', async () => {
    const partner = await makeUser('partner', { isPhoneVerified: false });
    const residence = await Residence.create(residenceAttrs({
      partner: partner._id,
      publicationStatus: PUBLICATION.DRAFT,
    }));
    await expect(requestPublication({ residenceId: residence._id, user: partner }))
      .rejects.toMatchObject({ statusCode: 403, errorCode: 'CAPABILITY_REQUIRED' });
    const fresh = await Residence.findById(residence._id);
    expect(fresh.publicationStatus).toBe('draft');
  });

  it('après téléphone vérifié : draft → pending_review', async () => {
    const partner = await makeUser('partner', { isPhoneVerified: true });
    const residence = await Residence.create(residenceAttrs({
      partner: partner._id,
      publicationStatus: PUBLICATION.DRAFT,
    }));
    const result = await requestPublication({ residenceId: residence._id, user: partner });
    expect(result.residence.publicationStatus).toBe('pending_review');
    expect(isPubliclyListed(result.residence)).toBe(false);
  });

  it('Client ne peut pas publier', async () => {
    const client = await makeUser('client', { isPhoneVerified: true });
    const partner = await makeUser('partner', { isPhoneVerified: true });
    const residence = await Residence.create(residenceAttrs({
      partner: partner._id,
      publicationStatus: PUBLICATION.DRAFT,
    }));
    await expect(requestPublication({ residenceId: residence._id, user: client }))
      .rejects.toMatchObject({ statusCode: 403 });
  });

  it('Partner A ne publie pas la résidence de Partner B', async () => {
    const a = await makeUser('partner', { isPhoneVerified: true });
    const b = await makeUser('partner', { isPhoneVerified: true });
    const residence = await Residence.create(residenceAttrs({
      partner: b._id,
      publicationStatus: PUBLICATION.DRAFT,
    }));
    await expect(requestPublication({ residenceId: residence._id, user: a }))
      .rejects.toMatchObject({ statusCode: 403, errorCode: 'RESIDENCE_UNAUTHORIZED_ACCESS' });
  });

  it('PUT profil : isPhoneVerified et capabilities dans le body sont ignorés', () => {
    const patch = pickUserSafePatch({
      firstName: 'Ada',
      isPhoneVerified: true,
      capabilities: { canPublishResidence: true },
      role: 'admin',
    });
    expect(patch.firstName).toBe('Ada');
    expect(patch.isPhoneVerified).toBeUndefined();
    expect(patch.capabilities).toBeUndefined();
    expect(patch.role).toBeUndefined();
  });

  it('HTTP : create 201 en draft sans téléphone ; publication 403 CAPABILITY_REQUIRED', async () => {
    const app = createApp();
    const partner = await makeUser('partner', { isPhoneVerified: false });
    const created = await request(app)
      .post('/api/residences')
      .set('Authorization', authHeader(partner))
      .send(createPayload);
    expect(created.status).toBe(201);
    expect(created.body.data.publicationStatus).toBe('draft');
    expect(created.body.data.verified).toBe(false);

    const listed = await request(app).get('/api/residences');
    expect(listed.status).toBe(200);
    const ids = (listed.body.data || []).map((r) => String(r._id));
    expect(ids).not.toContain(String(created.body.data._id));

    const publish = await request(app)
      .post(`/api/residences/${created.body.data._id}/publish`)
      .set('Authorization', authHeader(partner))
      .send({});
    expect(publish.status).toBe(403);
    expect(publish.body.errorCode).toBe('CAPABILITY_REQUIRED');
    expect(publish.body.code).toBe('CAPABILITY_REQUIRED');
    expect(publish.body.details).toMatchObject({
      capability: 'canPublishResidence',
      verification: 'phone',
    });
  });

  it('HTTP : OTP puis publication → pending_review', async () => {
    const app = createApp();
    const partner = await makeUser('partner', { isPhoneVerified: true });
    const created = await request(app)
      .post('/api/residences')
      .set('Authorization', authHeader(partner))
      .send(createPayload);
    expect(created.status).toBe(201);

    const publish = await request(app)
      .post(`/api/residences/${created.body.data._id}/publish`)
      .set('Authorization', authHeader(partner))
      .send({});
    expect(publish.status).toBe(200);
    expect(publish.body.data.publicationStatus).toBe('pending_review');
  });

  it('HTTP : client 403 ; Partner A ne publie pas la résidence de B', async () => {
    const app = createApp();
    const client = await makeUser('client', { isPhoneVerified: true });
    const a = await makeUser('partner', { isPhoneVerified: true });
    const b = await makeUser('partner', { isPhoneVerified: true });
    const residence = await Residence.create(residenceAttrs({
      partner: b._id,
      publicationStatus: PUBLICATION.DRAFT,
    }));

    const asClient = await request(app)
      .post(`/api/residences/${residence._id}/publish`)
      .set('Authorization', authHeader(client))
      .send({});
    expect(asClient.status).toBe(403);

    const asA = await request(app)
      .post(`/api/residences/${residence._id}/publish`)
      .set('Authorization', authHeader(a))
      .send({});
    expect(asA.status).toBe(403);
    expect(asA.body.errorCode).toBe('RESIDENCE_UNAUTHORIZED_ACCESS');
  });

  it('HTTP : Partner sans OTP peut modifier sa résidence (pas de gate publication)', async () => {
    const app = createApp();
    const partner = await makeUser('partner', { isPhoneVerified: false });
    const created = await request(app)
      .post('/api/residences')
      .set('Authorization', authHeader(partner))
      .send(createPayload);
    const id = created.body.data._id;

    const updated = await request(app)
      .put(`/api/residences/${id}`)
      .set('Authorization', authHeader(partner))
      .send({ title: 'Studio modifié sans OTP', description: 'Description test résidence assez longue' });
    expect(updated.status).toBe(200);
    expect(updated.body.data.title).toBe('Studio modifié sans OTP');
    expect(updated.body.data.publicationStatus).toBe('draft');
  });

  it('HTTP : update générique ne peut pas forcer pending_review / published', async () => {
    const app = createApp();
    const partner = await makeUser('partner', { isPhoneVerified: false });
    const created = await request(app)
      .post('/api/residences')
      .set('Authorization', authHeader(partner))
      .send(createPayload);
    const id = created.body.data._id;

    const bypass = await request(app)
      .put(`/api/residences/${id}`)
      .set('Authorization', authHeader(partner))
      .send({
        title: 'Tentative bypass',
        publicationStatus: 'pending_review',
        verified: true,
        status: 'pending_review',
      });
    expect(bypass.status).toBe(400);

    const stripOnly = await request(app)
      .put(`/api/residences/${id}`)
      .set('Authorization', authHeader(partner))
      .send({
        title: 'Toujours draft',
        publicationStatus: 'published',
        verified: true,
      });
    expect(stripOnly.status).toBe(200);
    expect(stripOnly.body.data.publicationStatus).toBe('draft');
    expect(stripOnly.body.data.verified).toBe(false);
  });

  it('partner_pending legacy + téléphone vérifié : même capability publication', async () => {
    const pending = await makeUser('partner_pending', { isPhoneVerified: true });
    const residence = await Residence.create(residenceAttrs({
      partner: pending._id,
      publicationStatus: PUBLICATION.DRAFT,
    }));
    const result = await requestPublication({ residenceId: residence._id, user: pending });
    expect(result.residence.publicationStatus).toBe('pending_review');
  });

  it('P2-02C ne dépublie pas un listing legacy sans publicationStatus', async () => {
    const partner = await makeUser('partner', { isPhoneVerified: false });
    const legacy = await Residence.create(residenceAttrs({
      partner: partner._id,
      title: 'Ancienne résidence en ligne',
    }));
    expect(isPubliclyListed(legacy)).toBe(true);
    const app = createApp();
    const listed = await request(app).get('/api/residences');
    const ids = (listed.body.data || []).map((r) => String(r._id));
    expect(ids).toContain(String(legacy._id));
  });
});
