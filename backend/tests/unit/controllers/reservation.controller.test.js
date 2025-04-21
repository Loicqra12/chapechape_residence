const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../../src/app');
const User = require('../../../src/models/user.model');
const Residence = require('../../../src/models/residence.model');
const Reservation = require('../../../src/models/reservation.model');
const { generateToken } = require('../../../src/utils/auth');

describe('Reservation Controller Tests', () => {
    let testUser;
    let testOwner;
    let userToken;
    let ownerToken;
    let testResidence;
    let testReservation;

    beforeAll(async () => {
        // Create test users
        testUser = await User.create({
            email: 'user@example.com',
            password: 'Password123!',
            firstName: 'Test',
            lastName: 'User',
            role: 'client'
        });

        testOwner = await User.create({
            email: 'owner@example.com',
            password: 'Password123!',
            firstName: 'Test',
            lastName: 'Owner',
            role: 'partner'
        });

        userToken = generateToken(testUser._id);
        ownerToken = generateToken(testOwner._id);

        // Create test residence
        testResidence = await Residence.create({
            title: 'Test Residence',
            description: 'A test residence',
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
            status: 'available'
        });

        // Create test reservation
        testReservation = await Reservation.create({
            user: testUser._id,
            residence: testResidence._id,
            startDate: new Date('2025-02-01'),
            endDate: new Date('2025-02-07'),
            status: 'pending',
            totalPrice: 780
        });
    });

    afterAll(async () => {
        await User.deleteMany({});
        await Residence.deleteMany({});
        await Reservation.deleteMany({});
    });

    describe('POST /api/reservations', () => {
        it('should create a new reservation when authenticated', async () => {
            const reservationData = {
                residenceId: testResidence._id,
                startDate: '2025-03-01',
                endDate: '2025-03-07'
            };

            const res = await request(app)
                .post('/api/reservations')
                .set('Authorization', `Bearer ${userToken}`)
                .send(reservationData);

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data.residence).toBe(testResidence._id.toString());
            expect(res.body.data.user).toBe(testUser._id.toString());
        });

        it('should not create reservation without authentication', async () => {
            const reservationData = {
                residenceId: testResidence._id,
                startDate: '2025-03-01',
                endDate: '2025-03-07'
            };

            const res = await request(app)
                .post('/api/reservations')
                .send(reservationData);

            expect(res.status).toBe(401);
            expect(res.body.success).toBe(false);
        });
    });

    describe('GET /api/reservations', () => {
        it('should get user reservations when authenticated', async () => {
            const res = await request(app)
                .get('/api/reservations')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBeGreaterThan(0);
        });

        it('should get owner reservations when authenticated as owner', async () => {
            const res = await request(app)
                .get('/api/reservations')
                .set('Authorization', `Bearer ${ownerToken}`);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
        });
    });

    describe('PATCH /api/reservations/:id', () => {
        it('should update reservation status when authorized', async () => {
            const updateData = {
                status: 'confirmed'
            };

            const res = await request(app)
                .patch(`/api/reservations/${testReservation._id}`)
                .set('Authorization', `Bearer ${ownerToken}`)
                .send(updateData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.status).toBe('confirmed');
        });

        it('should not update reservation without authorization', async () => {
            const updateData = {
                status: 'confirmed'
            };

            const res = await request(app)
                .patch(`/api/reservations/${testReservation._id}`)
                .send(updateData);

            expect(res.status).toBe(401);
            expect(res.body.success).toBe(false);
        });
    });

    describe('DELETE /api/reservations/:id', () => {
        it('should cancel reservation when authorized', async () => {
            const res = await request(app)
                .delete(`/api/reservations/${testReservation._id}`)
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.status).toBe('cancelled');
        });

        it('should not cancel reservation without authorization', async () => {
            const res = await request(app)
                .delete(`/api/reservations/${testReservation._id}`);

            expect(res.status).toBe(401);
            expect(res.body.success).toBe(false);
        });
    });
});
