const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/user.model');
const LoginAttempt = require('../src/models/loginAttempt.model');
const BlockedIP = require('../src/models/blockedIP.model');

describe('Security Tests', () => {
    const testUser = {
        email: 'test@example.com',
        password: 'Password123!',
        firstName: 'Test',
        lastName: 'User',
        role: 'client'
    };

    beforeEach(async () => {
        await User.deleteMany({});
        await LoginAttempt.deleteMany({});
        await BlockedIP.deleteMany({});
        await User.create(testUser);
    });

    describe('Rate Limiting', () => {
        it('should limit login attempts', async () => {
            const attempts = [];
            // Try to login 11 times (more than the limit)
            for (let i = 0; i < 11; i++) {
                attempts.push(
                    request(app)
                        .post('/api/auth/login')
                        .send({
                            email: testUser.email,
                            password: 'wrongpassword'
                        })
                );
            }

            const responses = await Promise.all(attempts);
            const lastResponse = responses[responses.length - 1];

            expect(lastResponse.status).toBe(429);
            expect(lastResponse.body.message).toContain('Trop de tentatives');
        });

        it('should block IP after multiple failed attempts', async () => {
            // Make multiple failed login attempts
            for (let i = 0; i < 5; i++) {
                await request(app)
                    .post('/api/auth/login')
                    .send({
                        email: testUser.email,
                        password: 'wrongpassword'
                    });
            }

            const attempts = await LoginAttempt.find({});
            expect(attempts.length).toBe(5);

            // Try one more time
            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: 'wrongpassword'
                });

            expect(res.status).toBe(403);
            expect(res.body.message).toContain('IP bloquée');
        });
    });

    describe('Login Security', () => {
        it('should track failed login attempts', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: 'wrongpassword'
                });

            expect(res.status).toBe(401);
            
            const attempts = await LoginAttempt.find({});
            expect(attempts.length).toBe(1);
            expect(attempts[0].email).toBe(testUser.email);
            expect(attempts[0].success).toBe(false);
        });

        it('should reset failed attempts after successful login', async () => {
            // First make a failed attempt
            await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: 'wrongpassword'
                });

            // Then login successfully
            const res = await request(app)
                .post('/api/auth/login')
                .send({
                    email: testUser.email,
                    password: testUser.password
                });

            expect(res.status).toBe(200);

            const attempts = await LoginAttempt.find({});
            expect(attempts.length).toBe(0);
        });
    });

    describe('Password Security', () => {
        it('should require strong passwords', async () => {
            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    ...testUser,
                    email: 'new@example.com',
                    password: 'weak'
                });

            expect(res.status).toBe(400);
            expect(res.body.message).toContain('mot de passe');
        });

        it('should hash passwords', async () => {
            const user = await User.findOne({ email: testUser.email });
            expect(user.password).not.toBe(testUser.password);
        });
    });
});
