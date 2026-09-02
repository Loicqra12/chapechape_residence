const request = require('supertest');
const app = require('../src/app');
const Favorite = require('../src/models/favorite.model');
const {
  createClient,
  createPartner,
  createAdmin,
  authHeader,
  createResidence,
} = require('./helpers/factories');

describe('Favorite HTTP — contrat actuel', () => {
  async function seed() {
    const client = await createClient();
    const other = await createClient();
    const partner = await createPartner({ isPhoneVerified: true, phoneNumber: '0700000002' });
    const residence = await createResidence(partner);
    return { client, other, partner, residence };
  }

  it('POST sans auth → 401 ; userId body ignoré / non requis', async () => {
    const { residence } = await seed();
    const res = await request(app)
      .post('/api/favorites')
      .send({ residenceId: residence._id.toString(), userId: '507f1f77bcf86cd799439011' });
    expect(res.status).toBe(401);
  });

  it('ajoute au user courant uniquement', async () => {
    const { client, residence } = await seed();
    const res = await request(app)
      .post('/api/favorites')
      .set('Authorization', authHeader(client))
      .send({ residenceId: residence._id.toString() });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    const stored = await Favorite.findById(res.body.data._id);
    expect(String(stored.user)).toBe(String(client._id));
  });

  it('même résidence deux fois → 400', async () => {
    const { client, residence } = await seed();
    await request(app)
      .post('/api/favorites')
      .set('Authorization', authHeader(client))
      .send({ residenceId: residence._id.toString() });
    const res = await request(app)
      .post('/api/favorites')
      .set('Authorization', authHeader(client))
      .send({ residenceId: residence._id.toString() });
    expect(res.status).toBe(400);
  });

  it('GET ne liste pas les favoris d’un tiers', async () => {
    const { client, other, residence } = await seed();
    await request(app)
      .post('/api/favorites')
      .set('Authorization', authHeader(client))
      .send({ residenceId: residence._id.toString() });

    const mine = await request(app)
      .get('/api/favorites')
      .set('Authorization', authHeader(client));
    expect(mine.status).toBe(200);
    expect(mine.body.data.length).toBe(1);
    expect(mine.body.data[0].residence).toHaveProperty('title');

    const theirs = await request(app)
      .get('/api/favorites')
      .set('Authorization', authHeader(other));
    expect(theirs.status).toBe(200);
    expect(theirs.body.data.length).toBe(0);
  });

  it('GET /stats = admin only', async () => {
    const { client } = await seed();
    const asClient = await request(app)
      .get('/api/favorites/stats')
      .set('Authorization', authHeader(client));
    expect(asClient.status).toBe(403);

    const admin = await createAdmin();
    const asAdmin = await request(app)
      .get('/api/favorites/stats')
      .set('Authorization', authHeader(admin));
    expect(asAdmin.status).toBe(200);
    expect(asAdmin.body.data).toBeDefined();
  });

  it('DELETE sans auth → 401', async () => {
    const { residence } = await seed();
    const res = await request(app).delete(`/api/favorites/${residence._id}`);
    expect(res.status).toBe(401);
  });

  it('DELETE /favorites/:residenceId : owner OK ; tiers 404 ; favori disparu', async () => {
    const { client, other, residence } = await seed();
    const added = await request(app)
      .post('/api/favorites')
      .set('Authorization', authHeader(client))
      .send({ residenceId: residence._id.toString() });
    expect(added.status).toBe(201);

    const stolen = await request(app)
      .delete(`/api/favorites/${residence._id}`)
      .set('Authorization', authHeader(other));
    expect(stolen.status).toBe(404);
    expect(await Favorite.countDocuments({
      user: client._id,
      residence: residence._id,
    })).toBe(1);

    const removed = await request(app)
      .delete(`/api/favorites/${residence._id}`)
      .set('Authorization', authHeader(client));
    expect(removed.status).toBe(200);

    const again = await request(app)
      .get('/api/favorites')
      .set('Authorization', authHeader(client));
    expect(again.status).toBe(200);
    expect(again.body.data.length).toBe(0);
  });
});
