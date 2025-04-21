const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../../src/app');
const User = require('../../../src/models/user.model');
const LoginAttempt = require('../../../src/models/loginAttempt.model');

describe('Auth Controller Tests', () => {
    let testUser;

    beforeAll(async () => {
        // Create test user
        testUser = await User.create({
            email: 'test@example.com',
            password: 'Password123!',
            firstName: 'Test',
            lastName: 'User'
        });
    });

    afterAll(async () => {
        await User.deleteMany({});
        await LoginAttempt.deleteMany({});
    });

    describe('POST /api/auth/register', () => {
        it('should register a new user successfully', async () => {
            const userData = {
                email: 'newuser@example.com',
                password: 'Password123!',
                firstName: 'New',
                lastName: 'User'
            };

            const res = await request(app)
                .post('/api/auth/register')
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(userData);

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data.email).toBe(userData.email.toLowerCase());
        });

        it('should not register user with invalid email', async () => {
            const userData = {
                email: 'invalid-email',
                password: 'Password123!',
                firstName: 'New',
                lastName: 'User'
            };

            const res = await request(app)
                .post('/api/auth/register')
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(userData);

            expect(res.status).toBe(400);
            expect(res.body.success).toBe(false);
        });

        it('should not register user with weak password', async () => {
            const userData = {
                email: 'user@example.com',
                password: 'weak',
                firstName: 'New',
                lastName: 'User'
            };

            const res = await request(app)
                .post('/api/auth/register')
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(userData);

            expect(res.status).toBe(400);
            expect(res.body.success).toBe(false);
        });
    });

    describe('POST /api/auth/login', () => {
        it('should login successfully with correct credentials', async () => {
            const loginData = {
                email: 'test@example.com',
                password: 'Password123!'
            };

            const res = await request(app)
                .post('/api/auth/login')
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(loginData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.token).toBeDefined();
        });

        it('should not login with incorrect password', async () => {
            const loginData = {
                email: 'test@example.com',
                password: 'WrongPassword123!'
            };

            const res = await request(app)
                .post('/api/auth/login')
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(loginData);

            expect(res.status).toBe(401);
            expect(res.body.success).toBe(false);
        });

        it('should track failed login attempts', async () => {
            const loginData = {
                email: 'test@example.com',
                password: 'WrongPassword123!'
            };

            // Attempt multiple failed logins
            for (let i = 0; i < 3; i++) {
                await request(app)
                    .post('/api/auth/login')
                    .set('X-CSRF-Token', 'test-csrf-token')
                    .send(loginData);
            }

            const attempts = await LoginAttempt.findOne({ email: 'test@example.com' });
            expect(attempts).toBeDefined();
            expect(attempts.attempts).toBeGreaterThanOrEqual(3);
        });
    });

    describe('POST /api/auth/forgot-password', () => {
        it('should send reset password email for valid user', async () => {
            const res = await request(app)
                .post('/api/auth/forgot-password')
                .set('X-CSRF-Token', 'test-csrf-token')
                .send({ email: 'test@example.com' });

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
        });

        it('should handle non-existent email gracefully', async () => {
            const res = await request(app)
                .post('/api/auth/forgot-password')
                .set('X-CSRF-Token', 'test-csrf-token')
                .send({ email: 'nonexistent@example.com' });

            expect(res.status).toBe(404);
            expect(res.body.success).toBe(false);
        });
    });
});
