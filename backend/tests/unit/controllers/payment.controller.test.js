const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../../src/app');
const User = require('../../../src/models/user.model');
const Payment = require('../../../src/models/payment.model');
const Reservation = require('../../../src/models/reservation.model');
const Residence = require('../../../src/models/residence.model');
const { generateToken } = require('../../../src/utils/auth');

jest.mock('stripe', () => {
    return jest.fn(() => ({
        paymentIntents: {
            create: jest.fn().mockResolvedValue({
                id: 'pi_test123',
                client_secret: 'test_secret'
            }),
            confirm: jest.fn().mockResolvedValue({
                id: 'pi_test123',
                status: 'succeeded'
            }),
            cancel: jest.fn().mockResolvedValue({
                id: 'pi_test123',
                status: 'canceled'
            })
        },
        refunds: {
            create: jest.fn().mockResolvedValue({
                id: 're_test123',
                status: 'succeeded'
            })
        },
        webhooks: {
            constructEvent: jest.fn().mockReturnValue({
                type: 'payment_intent.succeeded',
                data: {
                    object: {
                        id: 'pi_test123',
                        status: 'succeeded'
                    }
                }
            })
        }
    }));
});

jest.mock('../../../src/services/payment.service', () => ({
    initiatePayment: jest.fn().mockImplementation(async (paymentData) => {
        if (paymentData.paymentProvider === 'stripe') {
            return {
                transactionId: 'pi_test123',
                status: 'pending',
                clientSecret: 'test_client_secret'
            };
        } else if (paymentData.paymentProvider === 'orange') {
            return {
                transactionId: 'om_test123',
                status: 'processing',
                reference: 'test_reference',
                providerResponse: {}
            };
        }
        throw new Error('Méthode de paiement non supportée');
    }),
    checkPaymentStatus: jest.fn().mockImplementation(async (transactionId) => {
        return {
            status: 'completed',
            transactionId
        };
    })
}));

describe('Payment Controller Tests', () => {
    let testUser;
    let userToken;
    let testPayment;
    let testReservation;
    let testResidence;
    let anotherUser;
    let anotherUserToken;

    beforeAll(async () => {
        // Mock Stripe
        process.env.STRIPE_SECRET_KEY = 'sk_test_123';
        
        // Create test user
        testUser = await User.create({
            email: 'user@example.com',
            password: 'Password123!',
            firstName: 'Test',
            lastName: 'User',
            role: 'user'
        });

        // Create another user for unauthorized tests
        anotherUser = await User.create({
            email: 'another@example.com',
            password: 'Password123!',
            firstName: 'Another',
            lastName: 'User',
            role: 'user'
        });

        userToken = generateToken(testUser._id);
        anotherUserToken = generateToken(anotherUser._id);
    });

    beforeEach(async () => {
        // Create test residence
        testResidence = await Residence.create({
            title: 'Test Residence',
            description: 'Test Description',
            price: 1000,
            location: {
                address: 'Test Address',
                city: 'Test City',
                coordinates: {
                    type: 'Point',
                    coordinates: [0, 0]
                }
            },
            features: {
                bedrooms: 2,
                bathrooms: 1,
                area: 100,
                furnished: true
            },
            type: 'apartment',
            status: 'available',
            partner: testUser._id,
            verified: true
        });

        // Create test reservation before each test
        testReservation = await Reservation.create({
            residence: testResidence._id,
            user: testUser._id,
            checkIn: new Date(),
            checkOut: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
            numberOfGuests: 2,
            totalPrice: 1000,
            status: 'pending',
            paymentStatus: 'pending'
        });

        // Create test payment
        testPayment = await Payment.create({
            reservation: testReservation._id,
            amount: testReservation.totalPrice,
            paymentMethod: 'card',
            paymentProvider: 'stripe',
            status: 'pending',
            transactionId: 'test_transaction_id',
            paymentDetails: {
                reference: 'test_reference',
                providerResponse: {}
            }
        });
    });

    afterEach(async () => {
        // Nettoyer la base de données après chaque test
        await User.deleteMany({});
        await Payment.deleteMany({});
        await Reservation.deleteMany({});
        await Residence.deleteMany({});
    });

    describe('POST /api/payments/create-payment-intent', () => {
        it('should create payment intent when authenticated', async () => {
            const paymentData = {
                amount: 100,
                currency: 'XAF',
                reservationId: testReservation._id,
                paymentMethod: 'orange_money',
                paymentProvider: 'orange',
                phoneNumber: '+237600000000'
            };

            const res = await request(app)
                .post('/api/payments/create-payment-intent')
                .set('Authorization', `Bearer ${userToken}`)
                .send(paymentData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.clientSecret).toBeDefined();
        });

        it('should not create payment intent for non-existent reservation', async () => {
            const paymentData = {
                amount: 100,
                currency: 'XAF',
                reservationId: new mongoose.Types.ObjectId(),
                paymentMethod: 'card',
                paymentProvider: 'stripe'
            };

            const res = await request(app)
                .post('/api/payments/create-payment-intent')
                .set('Authorization', `Bearer ${userToken}`)
                .send(paymentData);

            expect(res.status).toBe(404);
            expect(res.body.success).toBe(false);
        });

        it('should handle Orange Money payment method', async () => {
            const paymentData = {
                amount: 100,
                currency: 'XAF',
                reservationId: testReservation._id,
                paymentMethod: 'orange_money',
                paymentProvider: 'orange',
                phoneNumber: '+237600000000'
            };

            const res = await request(app)
                .post('/api/payments/create-payment-intent')
                .set('Authorization', `Bearer ${userToken}`)
                .send(paymentData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.status).toBe('processing');
        });
    });

    describe('POST /api/payments/:paymentId/confirm', () => {
        it('should confirm payment when valid', async () => {
            const payment = new Payment({
                amount: 100,
                currency: 'XAF',
                paymentProvider: 'orange',
                paymentMethod: 'orange_money',
                status: 'pending',
                transactionId: 'test_123',
                reservation: new mongoose.Types.ObjectId(),
                user: testUser._id,
                phoneNumber: '+237600000000'
            });
            await payment.save();

            const confirmData = {
                otp: '123456'
            };

            const res = await request(app)
                .post(`/api/payments/${payment._id}/confirm`)
                .set('Authorization', `Bearer ${userToken}`)
                .send(confirmData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.status).toBe('completed');
        });

        it('should handle invalid payment intent', async () => {
            const confirmData = {
                paymentIntentId: 'invalid_id'
            };

            const res = await request(app)
                .post(`/api/payments/${testPayment._id}/confirm`)
                .set('Authorization', `Bearer ${userToken}`)
                .send(confirmData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
        });
    });

    describe('POST /api/payments/:paymentId/refund', () => {
        it('should process refund when authorized', async () => {
            const refundData = {
                reason: 'customer_requested'
            };

            const res = await request(app)
                .post(`/api/payments/${testPayment._id}/refund`)
                .set('Authorization', `Bearer ${userToken}`)
                .send(refundData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.status).toBe('refunded');
        });

        it('should not process refund for unauthorized user', async () => {
            const refundData = {
                reason: 'customer_requested'
            };

            const res = await request(app)
                .post(`/api/payments/${testPayment._id}/refund`)
                .set('Authorization', `Bearer ${anotherUserToken}`)
                .send(refundData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
        });
    });

    describe('GET /api/payments/my-payments', () => {
        it('should get payment history when authenticated', async () => {
            // Créer quelques paiements pour l'utilisateur
            const payment1 = new Payment({
                amount: 100,
                currency: 'XAF',
                paymentProvider: 'orange',
                paymentMethod: 'orange_money',
                status: 'completed',
                transactionId: 'test_123',
                reservation: new mongoose.Types.ObjectId(),
                user: testUser._id,
                phoneNumber: '+237600000000'
            });
            await payment1.save();

            const payment2 = new Payment({
                amount: 200,
                currency: 'XAF',
                paymentProvider: 'stripe',
                paymentMethod: 'card',
                status: 'completed',
                transactionId: 'test_456',
                reservation: new mongoose.Types.ObjectId(),
                user: testUser._id
            });
            await payment2.save();

            const res = await request(app)
                .get('/api/payments/my-payments')
                .set('Authorization', `Bearer ${userToken}`);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBeGreaterThan(0);
        });

        it('should return empty array when user has no payments', async () => {
            const res = await request(app)
                .get('/api/payments/my-payments')
                .set('Authorization', `Bearer ${anotherUserToken}`);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBe(0);
        });
    });

    describe('POST /api/payments/webhook', () => {
        it('should handle Stripe webhook events', async () => {
            const res = await request(app)
                .post('/api/payments/webhook')
                .set('stripe-signature', 'test_signature')
                .send({
                    type: 'payment_intent.succeeded',
                    data: {
                        object: {
                            id: 'pi_test123',
                            status: 'succeeded'
                        }
                    }
                });

            expect(res.status).toBe(200);
        });

        it('should handle invalid webhook signature', async () => {
            const res = await request(app)
                .post('/api/payments/webhook')
                .set('stripe-signature', 'invalid_signature')
                .send({});

            expect(res.status).toBe(200);
        });
    });
});
