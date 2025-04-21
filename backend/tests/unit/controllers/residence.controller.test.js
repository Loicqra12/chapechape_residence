const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../../src/app');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const { generateToken } = require('../../../src/utils/auth');

describe('Residence Controller Tests', () => {
    let testUser;
    let testOwner;
    let userToken;
    let ownerToken;
    let testResidence;

    beforeAll(async () => {
        // Create test users
        testOwner = await User.create({
            email: 'owner@example.com',
            password: 'Password123!',
            firstName: 'Test',
            lastName: 'Owner',
            role: 'owner'
        });

        testUser = await User.create({
            email: 'user@example.com',
            password: 'Password123!',
            firstName: 'Test',
            lastName: 'User',
            role: 'client'
        });

        ownerToken = generateToken(testOwner._id);
        userToken = generateToken(testUser._id);

        // Create test residence
        testResidence = await Residence.create({
            title: 'Test Residence',
            description: 'A beautiful test residence',
            owner: testOwner._id,
            location: {
                address: '123 Test St',
                city: 'Test City',
                country: 'Test Country',
                coordinates: {
                    latitude: 0,
                    longitude: 0
                }
            },
            price: {
                perNight: 100,
                cleaningFee: 50,
                serviceFee: 30
            },
            amenities: ['wifi', 'parking'],
            rules: ['no smoking', 'no pets'],
            status: 'available',
            images: ['test-image-1.jpg', 'test-image-2.jpg']
        });
    });

    afterAll(async () => {
        await User.deleteMany({});
        await Residence.deleteMany({});
    });

    describe('GET /api/residences', () => {
        it('should get all residences', async () => {
            const res = await request(app)
                .get('/api/residences');

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBeGreaterThan(0);
        });

        it('should filter residences by city', async () => {
            const res = await request(app)
                .get('/api/residences')
                .query({ city: 'Test City' });

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data[0].location.city).toBe('Test City');
        });
    });

    describe('POST /api/residences', () => {
        it('should create new residence when authenticated as owner', async () => {
            const residenceData = {
                title: 'New Test Residence',
                description: 'Another beautiful test residence',
                location: {
                    address: '456 Test St',
                    city: 'Test City',
                    country: 'Test Country',
                    coordinates: {
                        latitude: 1,
                        longitude: 1
                    }
                },
                price: {
                    perNight: 120,
                    cleaningFee: 60,
                    serviceFee: 35
                },
                amenities: ['wifi', 'pool'],
                rules: ['no parties'],
                images: ['new-test-image.jpg']
            };

            const res = await request(app)
                .post('/api/residences')
                .set('Authorization', `Bearer ${ownerToken}`)
                .send(residenceData);

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data.title).toBe(residenceData.title);
            expect(res.body.data.owner).toBe(testOwner._id.toString());
        });

        it('should not create residence when not authenticated', async () => {
            const residenceData = {
                title: 'New Test Residence',
                description: 'Test Description'
            };

            const res = await request(app)
                .post('/api/residences')
                .send(residenceData);

            expect(res.status).toBe(401);
            expect(res.body.success).toBe(false);
        });

        it('should not create residence when authenticated as regular user', async () => {
            const residenceData = {
                title: 'New Test Residence',
                description: 'Test Description'
            };

            const res = await request(app)
                .post('/api/residences')
                .set('Authorization', `Bearer ${userToken}`)
                .send(residenceData);

            expect(res.status).toBe(403);
            expect(res.body.success).toBe(false);
        });
    });

    describe('GET /api/residences/:id', () => {
        it('should get residence by id', async () => {
            const res = await request(app)
                .get(`/api/residences/${testResidence._id}`);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data._id).toBe(testResidence._id.toString());
        });

        it('should return 404 for non-existent residence', async () => {
            const fakeId = new mongoose.Types.ObjectId();
            const res = await request(app)
                .get(`/api/residences/${fakeId}`);

            expect(res.status).toBe(404);
            expect(res.body.success).toBe(false);
        });
    });

    describe('PUT /api/residences/:id', () => {
        it('should update residence when owner', async () => {
            const updateData = {
                title: 'Updated Test Residence',
                description: 'Updated test description'
            };

            const res = await request(app)
                .put(`/api/residences/${testResidence._id}`)
                .set('Authorization', `Bearer ${ownerToken}`)
                .send(updateData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.title).toBe(updateData.title);
            expect(res.body.data.description).toBe(updateData.description);
        });

        it('should not update residence when not owner', async () => {
            const updateData = {
                title: 'Updated Test Residence'
            };

            const res = await request(app)
                .put(`/api/residences/${testResidence._id}`)
                .set('Authorization', `Bearer ${userToken}`)
                .send(updateData);

            expect(res.status).toBe(403);
            expect(res.body.success).toBe(false);
        });
    });

    describe('DELETE /api/residences/:id', () => {
        it('should delete residence when owner', async () => {
            const res = await request(app)
                .delete(`/api/residences/${testResidence._id}`)
                .set('Authorization', `Bearer ${ownerToken}`);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
        });

        it('should not delete residence when not owner', async () => {
            const res = await request(app)
                .delete(`/api/residences/${testResidence._id}`)
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(403);
            expect(res.body.success).toBe(false);
        });
    });
});
