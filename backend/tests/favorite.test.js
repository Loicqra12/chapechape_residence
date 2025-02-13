const request = require('supertest');
const app = require('../src/app');
const Favorite = require('../src/models/favorite.model');
const User = require('../src/models/user.model');
const Residence = require('../src/models/residence.model');
const mongoose = require('mongoose');

describe('Favorite Routes', () => {
    let userToken;
    let userId;
    let residenceId;

    const testUser = {
        email: 'test@example.com',
        password: 'password123',
        firstName: 'Test',
        lastName: 'User',
        role: 'client'
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
        // Create test user and get token
        const user = await User.create(testUser);
        userId = user._id;
        const loginRes = await request(app)
            .post('/api/auth/login')
            .send({
                email: testUser.email,
                password: testUser.password
            });
        userToken = loginRes.body.data.token;

        // Create test residence
        const residence = await Residence.create(testResidence);
        residenceId = residence._id;
    });

    afterAll(async () => {
        await User.deleteMany({});
        await Favorite.deleteMany({});
        await Residence.deleteMany({});
    });

    describe('POST /api/favorites', () => {
        it('should add residence to favorites when authenticated', async () => {
            const res = await request(app)
                .post('/api/favorites')
                .set('Authorization', `Bearer ${userToken}`)
                .send({ residenceId });

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
        });

        it('should not add to favorites without authentication', async () => {
            const res = await request(app)
                .post('/api/favorites')
                .send({ residenceId });

            expect(res.status).toBe(401);
        });

        it('should not add same residence twice', async () => {
            await Favorite.create({
                user: userId,
                residence: residenceId
            });

            const res = await request(app)
                .post('/api/favorites')
                .set('Authorization', `Bearer ${userToken}`)
                .send({ residenceId });

            expect(res.status).toBe(400);
        });
    });

    describe('GET /api/favorites', () => {
        beforeEach(async () => {
            await Favorite.create({
                user: userId,
                residence: residenceId
            });
        });

        it('should get user favorites when authenticated', async () => {
            const res = await request(app)
                .get('/api/favorites')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(Array.isArray(res.body.data)).toBeTruthy();
        });

        it('should include residence details in favorites', async () => {
            const res = await request(app)
                .get('/api/favorites')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(res.body.data[0].residence).toHaveProperty('title');
        });

        it('should not get favorites without authentication', async () => {
            const res = await request(app)
                .get('/api/favorites');

            expect(res.status).toBe(401);
        });
    });

    describe('DELETE /api/favorites/:residenceId', () => {
        beforeEach(async () => {
            await Favorite.create({
                user: userId,
                residence: residenceId
            });
        });

        it('should remove residence from favorites when authenticated', async () => {
            const res = await request(app)
                .delete(`/api/favorites/${residenceId}`)
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            const favorite = await Favorite.findOne({
                user: userId,
                residence: residenceId
            });
            expect(favorite).toBeNull();
        });

        it('should not remove from favorites without authentication', async () => {
            const res = await request(app)
                .delete(`/api/favorites/${residenceId}`);

            expect(res.status).toBe(401);
        });
    });

    describe('GET /api/favorites/stats', () => {
        beforeEach(async () => {
            await Favorite.create({
                user: userId,
                residence: residenceId
            });
        });

        it('should get favorite statistics when authenticated', async () => {
            const res = await request(app)
                .get('/api/favorites/stats')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(res.body.data).toHaveProperty('totalFavorites');
            expect(res.body.data).toHaveProperty('mostFavorited');
        });
    });
});
