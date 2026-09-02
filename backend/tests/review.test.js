const request = require('supertest');
const app = require('../src/app');
const Review = require('../src/models/review.model');
const CancellationPolicy = require('../src/models/cancellationPolicy.model');
const {
  createClient,
  createPartner,
  authHeader,
  createResidence,
  createReservation,
} = require('./helpers/factories');

async function seedStay(status = 'completed') {
  const client = await createClient();
  const other = await createClient();
  const partner = await createPartner({ isPhoneVerified: true, phoneNumber: '0700000001' });
  const policy = await CancellationPolicy.create({
    name: `pol-${Date.now()}`,
    description: 'Politique test reviews',
    isDefault: false,
    createdBy: partner._id,
    rules: [{ timeBeforeCheckIn: 0, refundPercentage: 100, description: 'full' }],
  });
  const residence = await createResidence(partner, { cancellationPolicy: policy._id });
  const reservation = await createReservation(client, residence, {
    partner: partner._id,
    numberOfGuests: 1,
    totalPrice: 10000,
    cancellationPolicy: policy._id,
    status,
  });
  return { client, other, partner, residence, reservation };
}

describe('Review HTTP — contrat actuel', () => {
  it('401 sans authentification', async () => {
    const res = await request(app)
      .post('/api/reviews')
      .send({ residenceId: '507f1f77bcf86cd799439011', rating: 5, comment: 'x'.repeat(12) });
    expect(res.status).toBe(401);
  });

  it('séjour completed du client propriétaire → 201', async () => {
    const { client, residence, reservation } = await seedStay('completed');
    const res = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(client))
      .send({
        residenceId: residence._id.toString(),
        reservationId: reservation._id.toString(),
        rating: 5,
        comment: 'Séjour terminé, très bien',
      });
    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.rating.overall).toBe(5);
  });

  it('reservationId requis ; séjour non completed refusé', async () => {
    const { client, residence, reservation } = await seedStay('pending');
    const missing = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(client))
      .send({
        residenceId: residence._id.toString(),
        rating: 5,
        comment: 'Commentaire assez long',
      });
    expect(missing.status).toBe(400);

    const pending = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(client))
      .send({
        residenceId: residence._id.toString(),
        reservationId: reservation._id.toString(),
        rating: 5,
        comment: 'Commentaire assez long',
      });
    expect(pending.status).toBe(403);
  });

  it('Client B / Partner ne notent pas le séjour de A', async () => {
    const { client, other, partner, residence, reservation } = await seedStay('completed');
    const payload = {
      residenceId: residence._id.toString(),
      reservationId: reservation._id.toString(),
      rating: 5,
      comment: 'Commentaire assez long',
    };
    expect((await request(app).post('/api/reviews').set('Authorization', authHeader(other)).send(payload)).status).toBe(403);
    expect((await request(app).post('/api/reviews').set('Authorization', authHeader(partner)).send(payload)).status).toBe(403);
    expect((await request(app).post('/api/reviews').set('Authorization', authHeader(client)).send(payload)).status).toBe(201);
  });

  it('une review par user+résidence (409)', async () => {
    const { client, residence, reservation } = await seedStay('completed');
    const payload = {
      residenceId: residence._id.toString(),
      reservationId: reservation._id.toString(),
      rating: 5,
      comment: 'Premier avis séjour',
    };
    expect((await request(app).post('/api/reviews').set('Authorization', authHeader(client)).send(payload)).status).toBe(201);
    const second = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(client))
      .send({ ...payload, comment: 'Deuxième avis interdit' });
    expect(second.status).toBe(409);
  });

  it('GET public : reviews[] + user firstName', async () => {
    const { client, residence, reservation } = await seedStay('completed');
    await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(client))
      .send({
        residenceId: residence._id.toString(),
        reservationId: reservation._id.toString(),
        rating: 4,
        comment: 'Liste publique des avis',
      });
    const res = await request(app).get(`/api/reviews/residence/${residence._id}`);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data.reviews)).toBe(true);
    expect(res.body.data.reviews[0].user).toHaveProperty('firstName');
  });

  it('update/delete : owner OK, tiers 403', async () => {
    const { client, other, residence, reservation } = await seedStay('completed');
    const created = await request(app)
      .post('/api/reviews')
      .set('Authorization', authHeader(client))
      .send({
        residenceId: residence._id.toString(),
        reservationId: reservation._id.toString(),
        rating: 4,
        comment: 'Avis à modifier ensuite',
      });
    const id = created.body.data._id;
    const stolen = await request(app)
      .put(`/api/reviews/${id}`)
      .set('Authorization', authHeader(other))
      .send({ rating: 1, comment: 'Hijack commentaire' });
    expect(stolen.status).toBe(403);

    const updated = await request(app)
      .put(`/api/reviews/${id}`)
      .set('Authorization', authHeader(client))
      .send({ rating: 5, comment: 'Avis mis à jour ici' });
    expect(updated.status).toBe(200);
    expect(updated.body.data.rating.overall).toBe(5);

    expect((await request(app).delete(`/api/reviews/${id}`).set('Authorization', authHeader(other))).status).toBe(403);
    expect((await request(app).delete(`/api/reviews/${id}`).set('Authorization', authHeader(client))).status).toBe(200);
    expect(await Review.findById(id)).toBeNull();
  });
});
