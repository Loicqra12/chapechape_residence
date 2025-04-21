const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../../src/app');
const User = require('../../../src/models/user.model');
const Payment = require('../../../src/models/payment.model');
const Reservation = require('../../../src/models/reservation.model');
const Residence = require('../../../src/models/residence.model');
const CancellationPolicy = require('../../../src/models/cancellationPolicy.model');
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
    let testCancellationPolicy;
    let adminUser;

    beforeAll(async () => {
        // Mock Stripe
        process.env.STRIPE_SECRET_KEY = 'sk_test_123';
        
        // Create admin user for cancellation policy
        adminUser = await User.create({
            email: 'admin@example.com',
            password: 'Password123!',
            firstName: 'Admin',
            lastName: 'User',
            phoneNumber: '111222333',
            role: 'admin'
        });
        
        // Create test user
        testUser = await User.create({
            email: 'user@example.com',
            password: 'Password123!',
            firstName: 'Test',
            lastName: 'User',
            phoneNumber: '123456789',
            role: 'client'
        });

        // Create another user for unauthorized tests
        anotherUser = await User.create({
            email: 'another@example.com',
            password: 'Password123!',
            firstName: 'Another',
            lastName: 'User',
            phoneNumber: '987654321',
            role: 'client'
        });

        // Create test cancellation policy
        testCancellationPolicy = await CancellationPolicy.create({
            name: 'Politique standard',
            description: 'Politique standard de remboursement',
            rules: [
                {
                    timeBeforeCheckIn: 48,
                    refundPercentage: 50,
                    description: 'Remboursement de 50% si annulation 48h avant'
                }
            ],
            createdBy: adminUser._id  // Ajout du champ createdBy
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
            address: 'Test Address',
            city: 'Test City',
            latitude: 0,
            longitude: 0,
            bedrooms: 2,
            bathrooms: 1,
            area: 100,
            isFurnished: true,
            type: 'apartment',
            status: 'available',
            partner: testUser._id
        });

        // Create test reservation before each test
        testReservation = await Reservation.create({
            residence: testResidence._id,
            user: testUser._id,
            partner: testUser._id,  
            checkIn: new Date(),
            checkOut: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
            numberOfGuests: 2,
            totalPrice: 1000,
            status: 'pending',
            paymentStatus: 'pending',
            cancellationPolicy: testCancellationPolicy._id  
        });

        // Create test payment
        testPayment = await Payment.create({
            reservation: testReservation._id,
            amount: testReservation.totalPrice,
            paymentMethod: 'card',
            paymentProvider: 'stripe',
            status: 'pending',
            transactionId: 'test_transaction_id',
            firstName: 'Test',
            lastName: 'User',
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
        await CancellationPolicy.deleteMany({});
    });

    afterAll(async () => {
        await User.deleteMany({});
        await Payment.deleteMany({});
        await Reservation.deleteMany({});
        await Residence.deleteMany({});
        await CancellationPolicy.deleteMany({});
        mongoose.connection.close();
    });

    describe('POST /api/payments/create-payment-intent', () => {
        it('should create payment intent when authenticated', async () => {
            const paymentData = {
                reservationId: testReservation._id,
                paymentMethod: 'card',
                paymentProvider: 'stripe',
                firstName: 'Test',
                lastName: 'User'
            };

            const res = await request(app)
                .post('/api/payments/create-payment-intent')
                .set('Authorization', `Bearer ${userToken}`)
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(paymentData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.clientSecret).toBeDefined();
        });

        it('should not create payment intent for non-existent reservation', async () => {
            const paymentData = {
                reservationId: new mongoose.Types.ObjectId(), // Un ID qui n'existe pas
                paymentMethod: 'card',
                paymentProvider: 'stripe',
                firstName: 'Test',
                lastName: 'User'
            };

            const res = await request(app)
                .post('/api/payments/create-payment-intent')
                .set('Authorization', `Bearer ${userToken}`)
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(paymentData);

            expect(res.status).toBe(404);
            expect(res.body.success).toBe(false);
        });

        it('should handle Orange Money payment method', async () => {
            const paymentData = {
                reservationId: testReservation._id,
                paymentMethod: 'orange_money',
                paymentProvider: 'orange',
                phoneNumber: '6789012345',
                firstName: 'Test',
                lastName: 'User'
            };

            const res = await request(app)
                .post('/api/payments/create-payment-intent')
                .set('Authorization', `Bearer ${userToken}`)
                .set('X-CSRF-Token', 'test-csrf-token')
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
                paymentMethod: 'orange_money',
                paymentProvider: 'orange',
                status: 'pending',
                transactionId: 'test_123',
                reservation: testReservation._id,
                user: testUser._id,
                phoneNumber: '6789012345',
                firstName: 'Test',
                lastName: 'User'
            });
            await payment.save();

            const confirmData = {
                otp: '123456'
            };

            const res = await request(app)
                .post(`/api/payments/${payment._id}/confirm`)
                .set('Authorization', `Bearer ${userToken}`)
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(confirmData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
        });

        it('should handle invalid payment intent', async () => {
            const paymentData = {
                intentId: 'invalid_id',
                reservation: testReservation._id.toString(),
                amount: 100
            };

            const res = await request(app)
                .post('/api/payments/invalid_id/confirm')
                .set('Authorization', `Bearer ${userToken}`)
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(paymentData);

            expect(res.status).toBe(404);
            expect(res.body.success).toBe(false);
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
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(refundData);

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.status).toBe('refunded');
        });

        it('should not process refund for unauthorized user', async () => {
            const refundData = {
                reason: 'Customer request'
            };

            const res = await request(app)
                .post(`/api/payments/${testPayment._id}/refund`)
                .set('Authorization', `Bearer ${anotherUserToken}`)
                .set('X-CSRF-Token', 'test-csrf-token')
                .send(refundData);

            expect(res.status).toBe(403);
            expect(res.body.success).toBe(false);
        });
    });

    describe('GET /api/payments/my-payments', () => {
        it('should get payment history when authenticated', async () => {
            // Créer quelques paiements pour l'utilisateur
            const payment1 = new Payment({
                amount: 100,
                currency: 'XAF',
                paymentMethod: 'orange_money',
                paymentProvider: 'orange',
                status: 'completed',
                transactionId: 'test_123',
                reservation: new mongoose.Types.ObjectId(),
                user: testUser._id,
                phoneNumber: '6789012345'
            });
            await payment1.save();

            const payment2 = new Payment({
                amount: 200,
                currency: 'XAF',
                paymentMethod: 'card',
                paymentProvider: 'stripe',
                status: 'completed',
                transactionId: 'test_456',
                reservation: new mongoose.Types.ObjectId(),
                user: testUser._id
            });
            await payment2.save();

            const res = await request(app)
                .get('/api/payments/my-payments')
                .set('Authorization', `Bearer ${userToken}`)
                .set('X-CSRF-Token', 'test-csrf-token');

            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBeGreaterThan(0);
        });

        it('should return empty array when user has no payments', async () => {
            const res = await request(app)
                .get('/api/payments/my-payments')
                .set('Authorization', `Bearer ${anotherUserToken}`)
                .set('X-CSRF-Token', 'test-csrf-token');

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
                .set('X-CSRF-Token', 'test-csrf-token')
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
                .set('X-CSRF-Token', 'test-csrf-token')
                .send({});

            expect(res.status).toBe(400);
            expect(res.body.success).toBe(false);
        });
    });
});
