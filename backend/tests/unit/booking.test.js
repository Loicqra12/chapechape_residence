const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../../src/app');
const User = require('../../src/models/user.model');
const Booking = require('../../src/models/booking.model');
const Residence = require('../../src/models/residence.model');

let mongoServer;
let token;
let userId;
let residenceId;

beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());

    // Créer un utilisateur test
    const user = await User.create({
        email: 'test@example.com',
        password: 'Password123!',
        firstName: 'John',
        lastName: 'Doe',
        isVerified: true
    });
    userId = user._id;
    token = user.getSignedJwtToken();

    // Créer une résidence test
    const residence = await Residence.create({
        name: 'Test Residence',
        description: 'A test residence',
        address: '123 Test St',
        price: 100,
        owner: userId
    });
    residenceId = residence._id;
});

afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
});

beforeEach(async () => {
    await Booking.deleteMany({});
});

describe('Booking Controller', () => {
    describe('POST /api/bookings', () => {
        it('should create a new booking successfully', async () => {
            const bookingData = {
                residenceId: residenceId,
                checkIn: '2025-02-01',
                checkOut: '2025-02-05',
                guests: 2
            };

            const res = await request(app)
                .post('/api/bookings')
                .set('Authorization', `Bearer ${token}`)
                .send(bookingData);

            expect(res.statusCode).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data.residence.toString()).toBe(residenceId.toString());
            expect(res.body.data.user.toString()).toBe(userId.toString());
        });

        it('should not create booking with invalid dates', async () => {
            const bookingData = {
                residenceId: residenceId,
                checkIn: '2025-02-05',
                checkOut: '2025-02-01', // Date de départ avant la date d'arrivée
                guests: 2
            };

            const res = await request(app)
                .post('/api/bookings')
                .set('Authorization', `Bearer ${token}`)
                .send(bookingData);

            expect(res.statusCode).toBe(400);
            expect(res.body.success).toBe(false);
        });
    });

    describe('GET /api/bookings/me', () => {
        beforeEach(async () => {
            await Booking.create({
                residence: residenceId,
                user: userId,
                checkIn: '2025-02-01',
                checkOut: '2025-02-05',
                guests: 2,
                status: 'confirmed'
            });
        });

        it('should get user bookings', async () => {
            const res = await request(app)
                .get('/api/bookings/me')
                .set('Authorization', `Bearer ${token}`);

            expect(res.statusCode).toBe(200);
            expect(res.body.success).toBe(true);
            expect(Array.isArray(res.body.data)).toBe(true);
            expect(res.body.data.length).toBe(1);
        });

        it('should not get bookings without authentication', async () => {
            const res = await request(app)
                .get('/api/bookings/me');

            expect(res.statusCode).toBe(401);
            expect(res.body.success).toBe(false);
        });
    });

    describe('GET /api/bookings/:id', () => {
        let bookingId;

        beforeEach(async () => {
            const booking = await Booking.create({
                residence: residenceId,
                user: userId,
                checkIn: '2025-02-01',
                checkOut: '2025-02-05',
                guests: 2,
                status: 'confirmed'
            });
            bookingId = booking._id;
        });

        it('should get a specific booking', async () => {
            const res = await request(app)
                .get(`/api/bookings/${bookingId}`)
                .set('Authorization', `Bearer ${token}`);

            expect(res.statusCode).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data._id.toString()).toBe(bookingId.toString());
        });

        it('should not get non-existent booking', async () => {
            const fakeId = new mongoose.Types.ObjectId();
            const res = await request(app)
                .get(`/api/bookings/${fakeId}`)
                .set('Authorization', `Bearer ${token}`);

            expect(res.statusCode).toBe(404);
            expect(res.body.success).toBe(false);
        });
    });

    describe('DELETE /api/bookings/:id', () => {
        let bookingId;

        beforeEach(async () => {
            const booking = await Booking.create({
                residence: residenceId,
                user: userId,
                checkIn: '2025-02-01',
                checkOut: '2025-02-05',
                guests: 2,
                status: 'confirmed'
            });
            bookingId = booking._id;
        });

        it('should cancel a booking', async () => {
            const res = await request(app)
                .delete(`/api/bookings/${bookingId}`)
                .set('Authorization', `Bearer ${token}`);

            expect(res.statusCode).toBe(200);
            expect(res.body.success).toBe(true);

            const updatedBooking = await Booking.findById(bookingId);
            expect(updatedBooking.status).toBe('cancelled');
        });

        it('should not cancel non-existent booking', async () => {
            const fakeId = new mongoose.Types.ObjectId();
            const res = await request(app)
                .delete(`/api/bookings/${fakeId}`)
                .set('Authorization', `Bearer ${token}`);

            expect(res.statusCode).toBe(404);
            expect(res.body.success).toBe(false);
        });
    });
});
