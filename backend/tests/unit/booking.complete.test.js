const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../../src/app.test');
const Booking = require('../../src/models/booking.model');
const Residence = require('../../src/models/residence.model');
const User = require('../../src/models/user.model');
const { BOOKING_STATUS } = require('../../src/utils/constants');

/**
 * Test complet du flux de réservation
 * - Création d'une réservation
 * - Confirmation d'une réservation
 * - Annulation d'une réservation
 * - Récupération des réservations d'un utilisateur
 * - Vérification des extensions sur les modèles
 */
describe('Système de réservation complet', () => {
    // Données pour les résidences et utilisateurs de test
    let clientId, partnerId, residenceId, adminId;
    let clientToken, partnerToken, adminToken;
    
    // Configuration avant tous les tests
    beforeAll(async () => {
        // Créer un utilisateur client
        const clientUser = await User.create({
            name: 'Client Test',
            email: 'client@test.com',
            password: 'Password123!',
            role: 'client'
        });
        clientId = clientUser._id;
        
        // Créer un utilisateur partenaire
        const partnerUser = await User.create({
            name: 'Partner Test',
            email: 'partner@test.com',
            password: 'Password123!',
            role: 'partner'
        });
        partnerId = partnerUser._id;
        
        // Créer un admin
        const adminUser = await User.create({
            name: 'Admin Test',
            email: 'admin@test.com',
            password: 'Password123!',
            role: 'admin'
        });
        adminId = adminUser._id;
        
        // Créer une résidence de test
        const residence = await Residence.create({
            name: 'Résidence de Test',
            description: 'Une belle résidence pour les tests',
            price: 100,
            images: ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
            location: {
                address: '123 Test Street',
                city: 'Test City',
                country: 'Test Country',
                formattedAddress: '123 Test Street, Test City, Test Country'
            },
            amenities: ['wifi', 'pool', 'parking'],
            owner: partnerId,
            isAvailable: true,
            category: 'apartment',
            bedrooms: 2,
            bathrooms: 1,
            maxGuests: 4,
            isVacationResidence: true
        });
        residenceId = residence._id;
        
        // Générer des tokens pour les différents utilisateurs
        const clientLogin = await request(app)
            .post('/api/auth/login')
            .set('X-CSRF-Token', global.csrfToken)
            .send({ email: 'client@test.com', password: 'Password123!' });
        clientToken = clientLogin.body.data.token;
        
        const partnerLogin = await request(app)
            .post('/api/auth/login')
            .set('X-CSRF-Token', global.csrfToken)
            .send({ email: 'partner@test.com', password: 'Password123!' });
        partnerToken = partnerLogin.body.data.token;
        
        const adminLogin = await request(app)
            .post('/api/auth/login')
            .set('X-CSRF-Token', global.csrfToken)
            .send({ email: 'admin@test.com', password: 'Password123!' });
        adminToken = adminLogin.body.data.token;
    });
    
    // Test du cycle de vie d'une réservation
    describe("Cycle de vie d'une réservation", () => {
        let bookingId;
        
        it('devrait créer une nouvelle réservation', async () => {
            const bookingData = {
                residence: residenceId,
                visitDate: new Date(Date.now() + 86400000).toISOString().split('T')[0], // Demain
                visitTime: '14:00',
                notes: 'Je voudrais visiter cette résidence',
                guestCount: 2
            };
            
            const res = await request(app)
                .post('/api/reservations')
                .set('Authorization', `Bearer ${clientToken}`)
                .set('X-CSRF-Token', global.csrfToken)
                .send(bookingData);
            
            expect(res.status).toBe(201);
            expect(res.body.success).toBe(true);
            expect(res.body.data).toHaveProperty('booking');
            expect(res.body.data.booking.status).toBe(BOOKING_STATUS.PENDING);
            
            // Stocker l'ID de la réservation pour les tests suivants
            bookingId = res.body.data.booking._id;
        });
        
        it("devrait récupérer les détails d'une réservation", async () => {
            const res = await request(app)
                .get(`/api/reservations/${bookingId}`)
                .set('Authorization', `Bearer ${clientToken}`);
            
            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data).toHaveProperty('booking');
            expect(res.body.data.booking._id).toBe(bookingId);
            
            // Vérifier que les extensions des modèles fonctionnent
            expect(res.body.data.booking.residence).toHaveProperty('title');
            expect(res.body.data.booking.residence).toHaveProperty('imageUrl');
            expect(res.body.data.booking.residence).toHaveProperty('status');
            expect(res.body.data.booking.residence.location).toHaveProperty('formattedAddress');
        });
        
        it('devrait permettre au partenaire de confirmer une réservation', async () => {
            const res = await request(app)
                .post(`/api/reservations/${bookingId}/confirm`)
                .set('Authorization', `Bearer ${partnerToken}`)
                .set('X-CSRF-Token', global.csrfToken);
            
            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.booking.status).toBe(BOOKING_STATUS.CONFIRMED);
        });
        
        it("devrait permettre au client d'annuler une réservation", async () => {
            const res = await request(app)
                .post(`/api/reservations/${bookingId}/cancel`)
                .set('Authorization', `Bearer ${clientToken}`)
                .set('X-CSRF-Token', global.csrfToken)
                .send({ reason: 'Changement de plans' });
            
            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.booking.status).toBe(BOOKING_STATUS.CANCELLED);
        });
        
        it('devrait créer une nouvelle réservation pour la compléter', async () => {
            const bookingData = {
                residence: residenceId,
                visitDate: new Date(Date.now() + 86400000).toISOString().split('T')[0], // Demain
                visitTime: '15:00',
                notes: 'Nouvelle visite pour test de complétion',
                guestCount: 3
            };
            
            const res = await request(app)
                .post('/api/reservations')
                .set('Authorization', `Bearer ${clientToken}`)
                .set('X-CSRF-Token', global.csrfToken)
                .send(bookingData);
            
            expect(res.status).toBe(201);
            bookingId = res.body.data.booking._id;
            
            // Confirmer la réservation
            await request(app)
                .post(`/api/reservations/${bookingId}/confirm`)
                .set('Authorization', `Bearer ${partnerToken}`)
                .set('X-CSRF-Token', global.csrfToken);
        });
        
        it('devrait permettre au partenaire de marquer une réservation comme complétée', async () => {
            const res = await request(app)
                .post(`/api/reservations/${bookingId}/complete`)
                .set('Authorization', `Bearer ${partnerToken}`)
                .set('X-CSRF-Token', global.csrfToken);
            
            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.booking.status).toBe(BOOKING_STATUS.COMPLETED);
        });
    });
    
    // Tests des fonctionnalités de liste de réservations
    describe('Listes de réservations', () => {
        let bookings = [];
        
        // Créer plusieurs réservations pour les tests de liste
        beforeAll(async () => {
            // Créer 5 réservations
            for (let i = 0; i < 5; i++) {
                const booking = await Booking.create({
                    residence: residenceId,
                    client: clientId,
                    partner: partnerId,
                    visitDate: new Date(Date.now() + (i + 1) * 86400000),
                    visitTime: '10:00',
                    notes: `Réservation de test ${i + 1}`,
                    status: i % 2 === 0 ? BOOKING_STATUS.PENDING : BOOKING_STATUS.CONFIRMED,
                    guestCount: 2
                });
                bookings.push(booking._id);
            }
        });
        
        it("devrait permettre à l'admin de récupérer toutes les réservations", async () => {
            const res = await request(app)
                .get('/api/reservations/all')
                .set('Authorization', `Bearer ${adminToken}`);
            
            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.bookings).toBeInstanceOf(Array);
            expect(res.body.data.bookings.length).toBeGreaterThanOrEqual(5);
        });
        
        it('devrait permettre au client de récupérer ses réservations', async () => {
            const res = await request(app)
                .get('/api/reservations/user')
                .set('Authorization', `Bearer ${clientToken}`);
            
            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.bookings).toBeInstanceOf(Array);
            expect(res.body.data.bookings.length).toBeGreaterThanOrEqual(5);
        });
        
        it('devrait permettre de filtrer les réservations par statut', async () => {
            const res = await request(app)
                .get(`/api/reservations/user?status=${BOOKING_STATUS.PENDING}`)
                .set('Authorization', `Bearer ${clientToken}`);
            
            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            
            // Vérifier que toutes les réservations ont le statut demandé
            res.body.data.bookings.forEach(booking => {
                expect(booking.status).toBe(BOOKING_STATUS.PENDING);
            });
        });
        
        it('devrait permettre au partenaire de voir les réservations pour ses résidences', async () => {
            const res = await request(app)
                .get('/api/reservations/partner')
                .set('Authorization', `Bearer ${partnerToken}`);
            
            expect(res.status).toBe(200);
            expect(res.body.success).toBe(true);
            expect(res.body.data.bookings).toBeInstanceOf(Array);
            expect(res.body.data.bookings.length).toBeGreaterThanOrEqual(5);
        });
    });
    
    // Tests des cas d'erreur
    describe('Gestion des erreurs de réservation', () => {
        it('ne devrait pas permettre de réserver une date dans le passé', async () => {
            const pastDate = new Date();
            pastDate.setDate(pastDate.getDate() - 1);
            
            const bookingData = {
                residence: residenceId,
                visitDate: pastDate.toISOString().split('T')[0],
                visitTime: '14:00',
                notes: 'Cette réservation devrait échouer',
                guestCount: 2
            };
            
            const res = await request(app)
                .post('/api/reservations')
                .set('Authorization', `Bearer ${clientToken}`)
                .set('X-CSRF-Token', global.csrfToken)
                .send(bookingData);
            
            expect(res.status).toBe(400);
            expect(res.body.success).toBe(false);
        });
        
        it('ne devrait pas permettre de confirmer une réservation déjà annulée', async () => {
            // Créer d'abord une réservation
            const booking = await Booking.create({
                residence: residenceId,
                client: clientId,
                partner: partnerId,
                visitDate: new Date(Date.now() + 86400000),
                visitTime: '10:00',
                notes: 'Réservation à annuler',
                status: BOOKING_STATUS.CANCELLED,
                guestCount: 2
            });
            
            const res = await request(app)
                .post(`/api/reservations/${booking._id}/confirm`)
                .set('Authorization', `Bearer ${partnerToken}`)
                .set('X-CSRF-Token', global.csrfToken);
            
            expect(res.status).toBe(400);
            expect(res.body.success).toBe(false);
        });
        
        it("ne devrait pas permettre à un utilisateur non autorisé d'accéder à une réservation", async () => {
            // Créer un utilisateur non autorisé
            const unauthorizedUser = await User.create({
                name: 'Unauthorized Test',
                email: 'unauthorized@test.com',
                password: 'Password123!',
                role: 'client'
            });
            
            // Obtenir un token pour cet utilisateur
            const loginRes = await request(app)
                .post('/api/auth/login')
                .set('X-CSRF-Token', global.csrfToken)
                .send({ email: 'unauthorized@test.com', password: 'Password123!' });
            
            const unauthorizedToken = loginRes.body.data.token;
            
            // Créer une réservation
            const booking = await Booking.create({
                residence: residenceId,
                client: clientId, // Client original, pas l'utilisateur non autorisé
                partner: partnerId,
                visitDate: new Date(Date.now() + 86400000),
                visitTime: '16:00',
                notes: 'Réservation test sécurité',
                status: BOOKING_STATUS.PENDING,
                guestCount: 2
            });
            
            // Essayer d'accéder à la réservation avec l'utilisateur non autorisé
            const res = await request(app)
                .get(`/api/reservations/${booking._id}`)
                .set('Authorization', `Bearer ${unauthorizedToken}`);
            
            expect(res.status).toBe(403);
            expect(res.body.success).toBe(false);
        });
    });
});
