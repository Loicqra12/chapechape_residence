const request = require('supertest');
const app = require('../src/app');
const Review = require('../src/models/review.model');
const User = require('../src/models/user.model');
const Residence = require('../src/models/residence.model');
const { generateToken } = require('../src/utils/jwt');

describe('Review Routes', () => {
    let userToken;
    let userId;
    let residenceId;
    let reviewId;

    const testUser = {
        firstName: 'Test',
        lastName: 'User',
        email: 'user@test.com',
        password: 'Test123!',
        role: 'client'  // Changed from 'user' to 'client'
    };

    const testResidence = {
        name: 'Test Residence',
        description: 'A beautiful test residence',
        price: 1000,
        rooms: 3
    };

    const testReview = {
        rating: 4,
        comment: 'Great place to stay!'
    };

    beforeEach(async () => {
        // Créer un utilisateur et une résidence
        const user = await User.create(testUser);
        userId = user._id;
        userToken = generateToken(userId);

        const residence = await Residence.create(testResidence);
        residenceId = residence._id;
    });

    describe('POST /api/reviews', () => {
        it('should create a new review when authenticated', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    ...testReview,
                    residenceId
                });

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data.rating).toBe(testReview.rating);
            expect(res.body.data.comment).toBe(testReview.comment);
        });

        it('should not create review without authentication', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .send({
                    ...testReview,
                    residenceId
                });

            expect(res.status).toBe(401);
        });

        it('should validate rating range (1-5)', async () => {
            const res = await request(app)
                .post('/api/reviews')
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    ...testReview,
                    rating: 6,
                    residenceId
                });

            expect(res.status).toBe(400);
        });
    });

    describe('GET /api/reviews/residence/:residenceId', () => {
        beforeEach(async () => {
            const review = await Review.create({
                user: userId,
                residence: residenceId,
                ...testReview
            });
            reviewId = review._id;
        });

        it('should get all reviews for a residence', async () => {
            const res = await request(app)
                .get(`/api/reviews/residence/${residenceId}`);

            expect(res.status).toBe(200);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBeGreaterThan(0);
        });

        it('should include user details in review', async () => {
            const res = await request(app)
                .get(`/api/reviews/residence/${residenceId}`);

            expect(res.body.data[0].user).toHaveProperty('firstName');
            expect(res.body.data[0].user).toHaveProperty('lastName');
        });
    });

    describe('PUT /api/reviews/:id', () => {
        beforeEach(async () => {
            const review = await Review.create({
                user: userId,
                residence: residenceId,
                ...testReview
            });
            reviewId = review._id;
        });

        it('should update own review when authenticated', async () => {
            const update = { rating: 5, comment: 'Updated comment' };
            const res = await request(app)
                .put(`/api/reviews/${reviewId}`)
                .set('Authorization', `Bearer ${userToken}`)
                .send(update);

            expect(res.status).toBe(200);
            expect(res.body.data.rating).toBe(update.rating);
            expect(res.body.data.comment).toBe(update.comment);
        });

        it('should not update review of another user', async () => {
            const anotherUser = await User.create({
                ...testUser,
                email: 'another@test.com'
            });
            const anotherToken = generateToken(anotherUser._id);

            const res = await request(app)
                .put(`/api/reviews/${reviewId}`)
                .set('Authorization', `Bearer ${anotherToken}`)
                .send({ rating: 1 });

            expect(res.status).toBe(403);
        });
    });

    describe('DELETE /api/reviews/:id', () => {
        beforeEach(async () => {
            const review = await Review.create({
                user: userId,
                residence: residenceId,
                ...testReview
            });
            reviewId = review._id;
        });

        it('should delete own review when authenticated', async () => {
            const res = await request(app)
                .delete(`/api/reviews/${reviewId}`)
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            
            const deletedReview = await Review.findById(reviewId);
            expect(deletedReview).toBeNull();
        });

        it('should not delete review of another user', async () => {
            const anotherUser = await User.create({
                ...testUser,
                email: 'another@test.com'
            });
            const anotherToken = generateToken(anotherUser._id);

            const res = await request(app)
                .delete(`/api/reviews/${reviewId}`)
                .set('Authorization', `Bearer ${anotherToken}`);

            expect(res.status).toBe(403);
        });
    });
});
