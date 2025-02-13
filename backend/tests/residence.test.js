const request = require('supertest');
const app = require('../src/app');
const Residence = require('../src/models/residence.model');
const User = require('../src/models/user.model');
const mongoose = require('mongoose');

describe('Residence Routes', () => {
    let adminToken;
    let residenceId;

    const testAdmin = {
        email: 'admin@test.com',
        password: 'password123',
        firstName: 'Admin',
        lastName: 'User',
        role: 'admin'
    };

    const testResidence = {
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
            coordinates: {
                latitude: 0,
                longitude: 0
            }
        },
        images: [{
            url: 'test.jpg',
            isMain: true
        }],
        partner: new mongoose.Types.ObjectId(),
        availability: true
    };

    beforeAll(async () => {
        const admin = await User.create(testAdmin);
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

    describe('POST /api/residences', () => {
        it('should create a new residence when admin is authenticated', async () => {
            const res = await request(app)
                .post('/api/residences')
                .set('Authorization', `Bearer ${adminToken}`)
                .send(testResidence);

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data.title).toBe(testResidence.title);
        });

        it('should not create residence without authentication', async () => {
            const res = await request(app)
                .post('/api/residences')
                .send(testResidence);

            expect(res.status).toBe(401);
        });
    });

    describe('GET /api/residences', () => {
        beforeEach(async () => {
            await Residence.create(testResidence);
        });

        it('should get all residences', async () => {
            const res = await request(app)
                .get('/api/residences');

            expect(res.status).toBe(200);
            expect(Array.isArray(res.body.data)).toBeTruthy();
        });

        it('should filter residences by price range', async () => {
            const res = await request(app)
                .get('/api/residences')
                .query({ minPrice: 500, maxPrice: 1500 });

            expect(res.status).toBe(200);
            expect(Array.isArray(res.body.data)).toBeTruthy();
        });
    });

    describe('GET /api/residences/:id', () => {
        beforeEach(async () => {
            const residence = await Residence.create(testResidence);
            residenceId = residence._id;
        });

        it('should get a single residence by id', async () => {
            const res = await request(app)
                .get(`/api/residences/${residenceId}`);

            expect(res.status).toBe(200);
            expect(res.body.data._id.toString()).toBe(residenceId.toString());
        });

        it('should return 404 for non-existent residence', async () => {
            const fakeId = new mongoose.Types.ObjectId();
            const res = await request(app)
                .get(`/api/residences/${fakeId}`);

            expect(res.status).toBe(404);
        });
    });

    describe('PUT /api/residences/:id', () => {
        beforeEach(async () => {
            const residence = await Residence.create(testResidence);
            residenceId = residence._id;
        });

        it('should update residence when admin is authenticated', async () => {
            const updateData = { title: 'Updated Title' };
            const res = await request(app)
                .put(`/api/residences/${residenceId}`)
                .set('Authorization', `Bearer ${adminToken}`)
                .send(updateData);

            expect(res.status).toBe(200);
            expect(res.body.data.title).toBe(updateData.title);
        });

        it('should not update without authentication', async () => {
            const res = await request(app)
                .put(`/api/residences/${residenceId}`)
                .send({ title: 'Updated Title' });

            expect(res.status).toBe(401);
        });
    });

    describe('DELETE /api/residences/:id', () => {
        beforeEach(async () => {
            const residence = await Residence.create(testResidence);
            residenceId = residence._id;
        });

        it('should delete residence when admin is authenticated', async () => {
            const res = await request(app)
                .delete(`/api/residences/${residenceId}`)
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.status).toBe(200);
        });

        it('should not delete without authentication', async () => {
            const res = await request(app)
                .delete(`/api/residences/${residenceId}`);

            expect(res.status).toBe(401);
        });
    });
});
