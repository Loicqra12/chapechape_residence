const request = require('supertest');
const app = require('../src/app.test');
const User = require('../src/models/user.model');
const mongoose = require('mongoose');

describe('Auth Routes', () => {
    beforeEach(async () => {
        await User.deleteMany({});
    });

    // Données de test
    const userPayload = {
        email: 'test@example.com',
        password: 'password123',
        firstName: 'Test',
        lastName: 'User',
        role: 'client'
    };

    const userCredentials = {
        email: 'test@example.com',
        password: 'password123'
    };

    describe('POST /api/auth/register', () => {
        it('should register a new user successfully', async () => {
            const res = await request(app)
                .post('/api/auth/register')
                .set('X-CSRF-Token', global.csrfToken)
                .send(userPayload);

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data).toHaveProperty('token');
            expect(res.body.data.user.email).toBe(userPayload.email);
        });

        it('should not register user with existing email', async () => {
            await User.create(userPayload);

            const res = await request(app)
                .post('/api/auth/register')
                .set('X-CSRF-Token', global.csrfToken)
                .send(userPayload);

            expect(res.status).toBe(400);
            expect(res.body.success).toBe(false);
        });
    });

    describe('POST /api/auth/login', () => {
        beforeEach(async () => {
            await User.create({
                ...userCredentials,
                firstName: 'Test',
                lastName: 'User',
                role: 'client'
            });
        });

        it('should login successfully with correct credentials', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .set('X-CSRF-Token', global.csrfToken)
                .send(userCredentials);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data).toHaveProperty('token');
        });

        it('should not login with incorrect password', async () => {
            const res = await request(app)
                .post('/api/auth/login')
                .set('X-CSRF-Token', global.csrfToken)
                .send({
                    email: userCredentials.email,
                    password: 'wrongpassword'
                });

            expect(res.status).toBe(401);
            expect(res.body.success).toBe(false);
        });
    });
});
