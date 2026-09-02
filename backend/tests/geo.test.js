const request = require('supertest');
const app = require('../src/app');
const { createPartner, createResidence } = require('./helpers/factories');

/**
 * Nearby = filtre Mongo local (maps.controller). Pas Google.
 * POST /api/maps/geocode n’est pas testé ici (axios Google).
 */
describe('Geo HTTP — nearby local', () => {
  it('GET /api/maps/nearby sans lat/lng → 400', async () => {
    const res = await request(app).get('/api/maps/nearby');
    expect(res.status).toBe(400);
  });

  it('trouve une résidence du catalogue dans un rayon local, triée par distance', async () => {
    const partner = await createPartner({ isPhoneVerified: true, phoneNumber: '0700000003' });
    await createResidence(partner, {
      title: 'Cocody near',
      locationData: {
        address: 'Rue Test 1',
        city: 'Abidjan',
        country: 'CI',
        coordinates: { latitude: 5.36, longitude: -4.01 },
      },
    });
    await createResidence(partner, {
      title: 'Far away',
      locationData: {
        address: 'Rue Loin',
        city: 'Bouake',
        country: 'CI',
        coordinates: { latitude: 7.69, longitude: -5.03 },
      },
    });

    const res = await request(app)
      .get('/api/maps/nearby')
      .query({ lat: 5.36, lng: -4.01, radius: 20, limit: 20 });

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThan(0);
    const distances = res.body.data.map((r) => r.distance);
    const sorted = [...distances].sort((a, b) => a - b);
    expect(distances).toEqual(sorted);
    expect(res.body.data[0].title).toBe('Cocody near');
  });
});
