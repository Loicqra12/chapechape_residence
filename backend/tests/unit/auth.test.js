const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../../src/app');
const User = require('../../src/models/user.model');

let mongoServer;

beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());
});

afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
});

beforeEach(async () => {
    await User.deleteMany({});
});

describe('Auth Controller', () => {
    describe('POST /api/auth/register', () => {
        it('should register a new user successfully', async () => {
            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    email: 'test@example.com',
                    password: 'Password123!',
                    firstName: 'John',
                    lastName: 'Doe',
                    phoneNumber: '1234567890'
                });

            expect(res.statusCode).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.token).toBeDefined();
            expect(res.body.data.email).toBe('test@example.com');
        });

        it('should not register a user with existing email', async () => {
            await User.create({
                email: 'test@example.com',
                password: 'Password123!',
                firstName: 'John',
                lastName: 'Doe'
            });

            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    email: 'test@example.com',
                    password: 'Password123!',
                    firstName: 'Jane',
                    lastName: 'Doe'
                });

            expect(res.statusCode).toBe(400);
            expect(res.body.success).toBe(false);
        });
    });

    describe('POST /api/auth/login', () => {
        beforeEach(async () => {
            await User.create({
                email: 'test@example.com',
                password: 'Password123!',
                firstName: 'John',
                lastName: 'Doe',
                isVerified: true
            });
        });

        it('should login successfully with correct credentials', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'test@example.com',
                    password: 'Password123!'
                });

            expect(res.statusCode).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.token).toBeDefined();
        });

        it('should not login with incorrect password', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'test@example.com',
                    password: 'wrongpassword'
                });

            expect(res.statusCode).toBe(401);
            expect(res.body.success).toBe(false);
        });

        it('should not login with non-existent email', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    email: 'nonexistent@example.com',
                    password: 'Password123!'
                });

            expect(res.statusCode).toBe(401);
            expect(res.body.success).toBe(false);
        });
    });

    describe('GET /api/auth/me', () => {
        let token;

        beforeEach(async () => {
            const user = await User.create({
                email: 'test@example.com',
                password: 'Password123!',
                firstName: 'John',
                lastName: 'Doe',
                isVerified: true
            });

            token = user.getSignedJwtToken();
        });

        it('should get current user profile', async () => {
            const res = await request(app)
                .get('/api/auth/me')
                .set('Authorization', `Bearer ${token}`);

            expect(res.statusCode).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.email).toBe('test@example.com');
        });

        it('should not get profile without token', async () => {
            const res = await request(app)
                .get('/api/auth/me');

            expect(res.statusCode).toBe(401);
            expect(res.body.success).toBe(false);
        });
    });

    describe('POST /api/auth/forgot-password', () => {
        beforeEach(async () => {
            await User.create({
                email: 'test@example.com',
                password: 'Password123!',
                firstName: 'John',
                lastName: 'Doe'
            });
        });

        it('should send reset password token', async () => {
            const res = await request(app)
                .post('/api/auth/forgot-password')
                .send({
                    email: 'test@example.com'
                });

            expect(res.statusCode).toBe(200);
            expect(res.body.success).toBe(true);
        });

        it('should not send token for non-existent email', async () => {
            const res = await request(app)
                .post('/api/auth/forgot-password')
                .send({
                    email: 'nonexistent@example.com'
                });

            expect(res.statusCode).toBe(404);
            expect(res.body.success).toBe(false);
        });
    });
});
