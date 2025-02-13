const request = require('supertest');
const app = require('../src/app');
const Reservation = require('../src/models/reservation.model');
const User = require('../src/models/user.model');
const Residence = require('../src/models/residence.model');
const { generateToken } = require('../src/utils/jwt');

describe('Reservation Routes', () => {
    let userToken;
    let userId;
    let residenceId;

    const testUser = {
        firstName: 'Test',
        lastName: 'User',
        email: 'user@test.com',
        password: 'Test123!',
        role: 'user'
    };

    const testResidence = {
        name: 'Test Residence',
        description: 'A beautiful test residence',
        price: 1000,
        rooms: 3
    };

    beforeEach(async () => {
        // Créer un utilisateur et une résidence pour les tests
        const user = await User.create(testUser);
        userId = user._id;
        userToken = generateToken(userId);

        const residence = await Residence.create(testResidence);
        residenceId = residence._id;
    });

    describe('POST /api/reservations', () => {
        const reservationData = {
            checkIn: new Date('2024-02-01'),
            checkOut: new Date('2024-02-05')
        };

        it('should create a new reservation when authenticated', async () => {
            const res = await request(app)
                .post('/api/reservations')
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    ...reservationData,
                    residenceId
                });

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data.residence).toBe(residenceId.toString());
            expect(res.body.data.user).toBe(userId.toString());
        });

        it('should not create reservation without authentication', async () => {
            const res = await request(app)
                .post('/api/reservations')
                .send({
                    ...reservationData,
                    residenceId
                });

            expect(res.status).toBe(401);
        });
    });

    describe('GET /api/reservations', () => {
        beforeEach(async () => {
            await Reservation.create({
                residence: residenceId,
                user: userId,
                checkIn: new Date('2024-02-01'),
                checkOut: new Date('2024-02-05'),
                status: 'pending'
            });
        });

        it('should get user reservations when authenticated', async () => {
            const res = await request(app)
                .get('/api/reservations')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBeGreaterThan(0);
        });

        it('should not get reservations without authentication', async () => {
            const res = await request(app)
                .get('/api/reservations');

            expect(res.status).toBe(401);
        });
    });

    describe('PATCH /api/reservations/:id/confirm', () => {
        let reservationId;

        beforeEach(async () => {
            const reservation = await Reservation.create({
                residence: residenceId,
                user: userId,
                checkIn: new Date('2024-02-01'),
                checkOut: new Date('2024-02-05'),
                status: 'pending'
            });
            reservationId = reservation._id;
        });

        it('should confirm reservation when authenticated', async () => {
            const res = await request(app)
                .patch(`/api/reservations/${reservationId}/confirm`)
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(res.body.data.status).toBe('confirmed');
        });
    });

    describe('PATCH /api/reservations/:id/cancel', () => {
        let reservationId;

        beforeEach(async () => {
            const reservation = await Reservation.create({
                residence: residenceId,
                user: userId,
                checkIn: new Date('2024-02-01'),
                checkOut: new Date('2024-02-05'),
                status: 'confirmed'
            });
            reservationId = reservation._id;
        });

        it('should cancel reservation when authenticated', async () => {
            const res = await request(app)
                .patch(`/api/reservations/${reservationId}/cancel`)
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(res.body.data.status).toBe('cancelled');
        });
    });
});
