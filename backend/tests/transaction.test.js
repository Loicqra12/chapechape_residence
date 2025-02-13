const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/user.model');
const Payment = require('../src/models/payment.model');
const Transaction = require('../src/models/transaction.model');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

jest.mock('stripe');

describe('Transaction Tests', () => {
    let userToken;
    let userId;
    
    const testUser = {
        email: 'test@example.com',
        password: 'Password123!',
        firstName: 'Test',
        lastName: 'User',
        role: 'client'
    };

    const testPayment = {
        amount: 1000,
        currency: 'USD',
        description: 'Test payment'
    };

    beforeAll(async () => {
        const user = await User.create(testUser);
        userId = user._id;
        const loginRes = await request(app)
            .post('/api/auth/login')
            .send({
                email: testUser.email,
                password: testUser.password
            });
        userToken = loginRes.body.data.token;
    });

    afterAll(async () => {
        await User.deleteMany({});
        await Payment.deleteMany({});
        await Transaction.deleteMany({});
    });

    describe('Payment Processing', () => {
        it('should create a payment intent', async () => {
            stripe.paymentIntents.create.mockResolvedValue({
                id: 'pi_test',
                client_secret: 'secret_test'
            });

            const res = await request(app)
                .post('/api/payments/intent')
                .set('Authorization', `Bearer ${userToken}`)
                .send(testPayment);

            expect(res.status).toBe(200);
            expect(res.body.data).toHaveProperty('clientSecret');
        });

        it('should handle failed payment intent creation', async () => {
            stripe.paymentIntents.create.mockRejectedValue(
                new Error('Stripe error')
            );

            const res = await request(app)
                .post('/api/payments/intent')
                .set('Authorization', `Bearer ${userToken}`)
                .send(testPayment);

            expect(res.status).toBe(500);
            expect(res.body.message).toContain('paiement');
        });
    });

    describe('Payment Confirmation', () => {
        it('should confirm successful payment', async () => {
            const payment = await Payment.create({
                user: userId,
                amount: testPayment.amount,
                currency: testPayment.currency,
                status: 'pending',
                stripePaymentIntentId: 'pi_test'
            });

            stripe.paymentIntents.retrieve.mockResolvedValue({
                id: 'pi_test',
                status: 'succeeded'
            });

            const res = await request(app)
                .post(`/api/payments/${payment._id}/confirm`)
                .set('Authorization', `Bearer ${userToken}`)
                .send({ paymentIntentId: 'pi_test' });

            expect(res.status).toBe(200);
            expect(res.body.data.status).toBe('completed');
        });

        it('should handle failed payment confirmation', async () => {
            const payment = await Payment.create({
                user: userId,
                amount: testPayment.amount,
                currency: testPayment.currency,
                status: 'pending',
                stripePaymentIntentId: 'pi_test'
            });

            stripe.paymentIntents.retrieve.mockResolvedValue({
                id: 'pi_test',
                status: 'failed'
            });

            const res = await request(app)
                .post(`/api/payments/${payment._id}/confirm`)
                .set('Authorization', `Bearer ${userToken}`)
                .send({ paymentIntentId: 'pi_test' });

            expect(res.status).toBe(400);
            expect(res.body.message).toContain('échoué');
        });
    });

    describe('Refunds', () => {
        it('should process refund request', async () => {
            const payment = await Payment.create({
                user: userId,
                amount: testPayment.amount,
                currency: testPayment.currency,
                status: 'completed',
                stripePaymentIntentId: 'pi_test'
            });

            stripe.refunds.create.mockResolvedValue({
                id: 're_test',
                status: 'succeeded'
            });

            const res = await request(app)
                .post(`/api/payments/${payment._id}/refund`)
                .set('Authorization', `Bearer ${userToken}`)
                .send({ reason: 'customer_request' });

            expect(res.status).toBe(200);
            expect(res.body.data.status).toBe('refunded');
        });

        it('should handle failed refund request', async () => {
            const payment = await Payment.create({
                user: userId,
                amount: testPayment.amount,
                currency: testPayment.currency,
                status: 'completed',
                stripePaymentIntentId: 'pi_test'
            });

            stripe.refunds.create.mockRejectedValue(
                new Error('Refund error')
            );

            const res = await request(app)
                .post(`/api/payments/${payment._id}/refund`)
                .set('Authorization', `Bearer ${userToken}`)
                .send({ reason: 'customer_request' });

            expect(res.status).toBe(500);
            expect(res.body.message).toContain('remboursement');
        });
    });

    describe('Transaction History', () => {
        it('should track all payment transactions', async () => {
            const payment = await Payment.create({
                user: userId,
                amount: testPayment.amount,
                currency: testPayment.currency,
                status: 'completed',
                stripePaymentIntentId: 'pi_test'
            });

            const transaction = await Transaction.create({
                payment: payment._id,
                type: 'payment',
                status: 'success',
                amount: testPayment.amount
            });

            const res = await request(app)
                .get('/api/payments/history')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(Array.isArray(res.body.data)).toBeTruthy();
            expect(res.body.data[0].type).toBe('payment');
        });

        it('should provide transaction details', async () => {
            const payment = await Payment.create({
                user: userId,
                amount: testPayment.amount,
                currency: testPayment.currency,
                status: 'completed',
                stripePaymentIntentId: 'pi_test'
            });

            const transaction = await Transaction.create({
                payment: payment._id,
                type: 'payment',
                status: 'success',
                amount: testPayment.amount
            });

            const res = await request(app)
                .get(`/api/payments/transactions/${transaction._id}`)
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(res.body.data).toHaveProperty('type');
            expect(res.body.data).toHaveProperty('status');
            expect(res.body.data).toHaveProperty('amount');
        });
    });
});
