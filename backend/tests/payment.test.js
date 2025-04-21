const request = require('supertest');
const app = require('../src/app');
const Payment = require('../src/models/payment.model');
const User = require('../src/models/user.model');
const Reservation = require('../src/models/reservation.model');
const { generateToken } = require('../src/utils/jwt');

describe('Payment Routes', () => {
    let userToken;
    let userId;
    let reservationId;

    const testUser = {
        firstName: 'Payment',
        lastName: 'Test',
        email: 'payment@test.com',
        password: 'Test123!',
        role: 'client'
    };

    beforeEach(async () => {
        // Créer un utilisateur et une réservation pour les tests
        const user = await User.create(testUser);
        userId = user._id;
        userToken = generateToken(userId);

        const reservation = await Reservation.create({
            user: userId,
            residence: '507f1f77bcf86cd799439011', // ID factice
            checkIn: new Date('2024-02-01'),
            checkOut: new Date('2024-02-05'),
            status: 'pending',
            totalAmount: 1000
        });
        reservationId = reservation._id;
    });

    describe('POST /api/payments', () => {
        const paymentData = {
            amount: 1000,
            method: 'orange_money',
            phoneNumber: '+22501234567'
        };

        it('should initiate payment when authenticated', async () => {
            const res = await request(app)
                .post('/api/payments')
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    ...paymentData,
                    reservationId
                });

            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data.amount).toBe(paymentData.amount);
            expect(res.body.data.method).toBe(paymentData.method);
        });

        it('should not initiate payment without authentication', async () => {
            const res = await request(app)
                .post('/api/payments')
                .send({
                    ...paymentData,
                    reservationId
                });

            expect(res.status).toBe(401);
        });
    });

    describe('GET /api/payments', () => {
        beforeEach(async () => {
            await Payment.create({
                user: userId,
                reservation: reservationId,
                amount: 1000,
                method: 'orange_money',
                status: 'pending'
            });
        });

        it('should get user payments when authenticated', async () => {
            const res = await request(app)
                .get('/api/payments')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBeGreaterThan(0);
        });

        it('should not get payments without authentication', async () => {
            const res = await request(app)
                .get('/api/payments');

            expect(res.status).toBe(401);
        });
    });

    describe('POST /api/payments/:id/confirm', () => {
        let paymentId;

        beforeEach(async () => {
            const payment = await Payment.create({
                user: userId,
                reservation: reservationId,
                amount: 1000,
                method: 'orange_money',
                status: 'pending'
            });
            paymentId = payment._id;
        });

        it('should confirm payment when valid', async () => {
            const res = await request(app)
                .post(`/api/payments/${paymentId}/confirm`)
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    transactionId: 'test_transaction_123'
                });

            expect(res.status).toBe(200);
            expect(res.body.data.status).toBe('completed');
        });
    });

    describe('POST /api/payments/:id/refund', () => {
        let paymentId;

        beforeEach(async () => {
            const payment = await Payment.create({
                user: userId,
                reservation: reservationId,
                amount: 1000,
                method: 'orange_money',
                status: 'completed'
            });
            paymentId = payment._id;
        });

        it('should request refund when authenticated', async () => {
            const res = await request(app)
                .post(`/api/payments/${paymentId}/refund`)
                .set('Authorization', `Bearer ${userToken}`)
                .send({
                    reason: 'Reservation cancelled'
                });

            expect(res.status).toBe(200);
            expect(res.body.data.status).toBe('refund_pending');
        });
    });
});
