const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/user.model');
const Residence = require('../src/models/residence.model');

describe('Geographic Data Tests', () => {
    let adminToken;
    
    const testAdmin = {
        email: 'admin@example.com',
        password: 'Password123!',
        firstName: 'Admin',
        lastName: 'User',
        role: 'admin'
    };

    const validResidence = {
        title: 'Test Residence',
        description: 'A test residence',
        price: 1000,
        type: 'apartment',
        features: {
            bedrooms: 2,
            bathrooms: 1,
            area: 100
        },
        location: {
            address: '123 Test St',
            city: 'Test City',
            state: 'Test State',
            country: 'Test Country',
            postalCode: '12345',
            coordinates: {
                latitude: 45.5017,
                longitude: -73.5673
            }
        },
        images: [{
            url: 'test.jpg',
            isMain: true
        }],
        availability: true
    };

    beforeAll(async () => {
        await User.create(testAdmin);
        const loginRes = await request(app)
            .post('/api/auth/login')
            .send({
                email: testAdmin.email,
                password: testAdmin.password
            });
        adminToken = loginRes.body.data.token;
    });

    afterAll(async () => {
        await User.deleteMany({});
        await Residence.deleteMany({});
    });

    describe('Location Validation', () => {
        it('should validate latitude range', async () => {
            const invalidResidence = {
                ...validResidence,
                location: {
                    ...validResidence.location,
                    coordinates: {
                        latitude: 91, // Invalid latitude (>90)
                        longitude: -73.5673
                    }
                }
            };

            const res = await request(app)
                .post('/api/residences')
                .set('Authorization', `Bearer ${adminToken}`)
                .send(invalidResidence);

            expect(res.status).toBe(400);
            expect(res.body.message).toContain('latitude');
        });

        it('should validate longitude range', async () => {
            const invalidResidence = {
                ...validResidence,
                location: {
                    ...validResidence.location,
                    coordinates: {
                        latitude: 45.5017,
                        longitude: -181 // Invalid longitude (<-180)
                    }
                }
            };

            const res = await request(app)
                .post('/api/residences')
                .set('Authorization', `Bearer ${adminToken}`)
                .send(invalidResidence);

            expect(res.status).toBe(400);
            expect(res.body.message).toContain('longitude');
        });

        it('should require both latitude and longitude', async () => {
            const invalidResidence = {
                ...validResidence,
                location: {
                    ...validResidence.location,
                    coordinates: {
                        latitude: 45.5017
                        // Missing longitude
                    }
                }
            };

            const res = await request(app)
                .post('/api/residences')
                .set('Authorization', `Bearer ${adminToken}`)
                .send(invalidResidence);

            expect(res.status).toBe(400);
            expect(res.body.message).toContain('coordinates');
        });
    });

    describe('Address Validation', () => {
        it('should require valid postal code format', async () => {
            const invalidResidence = {
                ...validResidence,
                location: {
                    ...validResidence.location,
                    postalCode: 'invalid'
                }
            };

            const res = await request(app)
                .post('/api/residences')
                .set('Authorization', `Bearer ${adminToken}`)
                .send(invalidResidence);

            expect(res.status).toBe(400);
            expect(res.body.message).toContain('code postal');
        });

        it('should require all address fields', async () => {
            const invalidResidence = {
                ...validResidence,
                location: {
                    coordinates: validResidence.location.coordinates
                    // Missing address fields
                }
            };

            const res = await request(app)
                .post('/api/residences')
                .set('Authorization', `Bearer ${adminToken}`)
                .send(invalidResidence);

            expect(res.status).toBe(400);
            expect(res.body.message).toContain('adresse');
        });
    });

    describe('Geographic Queries', () => {
        beforeEach(async () => {
            await Residence.create(validResidence);
        });

        it('should find residences within radius', async () => {
            const res = await request(app)
                .get('/api/residences/nearby')
                .query({
                    latitude: 45.5017,
                    longitude: -73.5673,
                    radius: 10 // 10km radius
                });

            expect(res.status).toBe(200);
            expect(Array.isArray(res.body.data)).toBeTruthy();
            expect(res.body.data.length).toBeGreaterThan(0);
        });

        it('should sort residences by distance', async () => {
            const res = await request(app)
                .get('/api/residences/nearby')
                .query({
                    latitude: 45.5017,
                    longitude: -73.5673,
                    sort: 'distance'
                });

            expect(res.status).toBe(200);
            expect(Array.isArray(res.body.data)).toBeTruthy();
            
            // Verify distances are sorted
            const distances = res.body.data.map(r => r.distance);
            const sortedDistances = [...distances].sort((a, b) => a - b);
            expect(distances).toEqual(sortedDistances);
        });
    });
});
