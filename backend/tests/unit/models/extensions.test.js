const mongoose = require('mongoose');
const Residence = require('../../../src/models/residence.model');
const Booking = require('../../../src/models/booking.model');
const User = require('../../../src/models/user.model');
const { BOOKING_STATUS } = require('../../../src/utils/constants');

/**
 * Tests pour les extensions de modèles spécifiques à ChapeChape
 * 
 * Teste les extensions suivantes :
 * - ResidenceProperties (imageUrl, title, status, hasPool, isVacationResidence, isSpecialResidence)
 * - LocationExtension (displayAddress)
 */
describe('Extensions de modèles ChapeChape', () => {
    // Données de test
    let residenceId, partnerId;
    
    // Configuration pour les tests
    beforeAll(async () => {
        // Créer un partenaire
        const partner = await User.create({
            name: 'Partner Test',
            email: 'extension-partner@test.com',
            password: 'Password123!',
            role: 'partner'
        });
        partnerId = partner._id;
        
        // Créer une résidence complète
        const residence = await Residence.create({
            name: 'Résidence Extension Test',
            description: 'Une résidence pour tester les extensions',
            price: 150,
            images: ['https://example.com/test1.jpg', 'https://example.com/test2.jpg'],
            location: {
                address: '123 Test Boulevard',
                city: 'Extension City',
                country: 'Test Country',
                formattedAddress: '123 Test Boulevard, Extension City, Test Country',
                coordinates: [4.5678, 3.4567],
                postalCode: '12345'
            },
            amenities: ['wifi', 'pool', 'parking', 'garden', 'bbq'],
            owner: partnerId,
            isAvailable: true,
            category: 'villa',
            bedrooms: 3,
            bathrooms: 2,
            maxGuests: 6,
            isVacationResidence: true,
            isSpecialResidence: true
        });
        residenceId = residence._id;
    });
    
    describe('Extension ResidenceProperties', () => {
        it('devrait calculer correctement imageUrl (première image)', async () => {
            const residence = await Residence.findById(residenceId);
            
            // Vérifier que l'extension imageUrl fonctionne
            expect(residence).toHaveProperty('imageUrl');
            expect(residence.imageUrl).toBe('https://example.com/test1.jpg');
        });
        
        it('devrait retourner une image par défaut si aucune image n\'est disponible', async () => {
            // Créer une résidence sans images
            const noImageResidence = await Residence.create({
                name: 'Résidence Sans Image',
                description: 'Une résidence pour tester l\'extension imageUrl sans images',
                price: 120,
                location: {
                    address: '456 No Image Street',
                    city: 'No Image City',
                    country: 'Test Country',
                    formattedAddress: '456 No Image Street, No Image City, Test Country'
                },
                owner: partnerId,
                isAvailable: true,
                category: 'house',
                bedrooms: 2,
                bathrooms: 1,
                maxGuests: 4
            });
            
            // Vérifier que l'extension imageUrl retourne une valeur par défaut
            expect(noImageResidence).toHaveProperty('imageUrl');
            expect(noImageResidence.imageUrl).toContain('default');
        });
        
        it('devrait calculer correctement title (alias pour le nom)', async () => {
            const residence = await Residence.findById(residenceId);
            
            // Vérifier que l'extension title fonctionne
            expect(residence).toHaveProperty('title');
            expect(residence.title).toBe('Résidence Extension Test');
        });
        
        it('devrait calculer correctement status (basé sur isAvailable)', async () => {
            const availableResidence = await Residence.findById(residenceId);
            
            // Vérifier que l'extension status fonctionne pour une résidence disponible
            expect(availableResidence).toHaveProperty('status');
            expect(availableResidence.status).toBe('available');
            
            // Créer une résidence non disponible
            const unavailableResidence = await Residence.create({
                name: 'Résidence Non Disponible',
                description: 'Une résidence pour tester l\'extension status indisponible',
                price: 180,
                location: {
                    address: '789 Unavailable Street',
                    city: 'Status City',
                    country: 'Test Country',
                    formattedAddress: '789 Unavailable Street, Status City, Test Country'
                },
                owner: partnerId,
                isAvailable: false,
                category: 'apartment',
                bedrooms: 1,
                bathrooms: 1,
                maxGuests: 2
            });
            
            // Vérifier que l'extension status fonctionne pour une résidence non disponible
            expect(unavailableResidence).toHaveProperty('status');
            expect(unavailableResidence.status).toBe('unavailable');
        });
        
        it('devrait calculer correctement hasPool (basé sur les amenities)', async () => {
            const residenceWithPool = await Residence.findById(residenceId);
            
            // Vérifier que l'extension hasPool fonctionne pour une résidence avec piscine
            expect(residenceWithPool).toHaveProperty('hasPool');
            expect(residenceWithPool.hasPool).toBe(true);
            
            // Créer une résidence sans piscine
            const residenceWithoutPool = await Residence.create({
                name: 'Résidence Sans Piscine',
                description: 'Une résidence pour tester l\'extension hasPool sans piscine',
                price: 130,
                location: {
                    address: '101 No Pool Avenue',
                    city: 'Pool City',
                    country: 'Test Country',
                    formattedAddress: '101 No Pool Avenue, Pool City, Test Country'
                },
                amenities: ['wifi', 'parking', 'garden'],
                owner: partnerId,
                isAvailable: true,
                category: 'apartment',
                bedrooms: 2,
                bathrooms: 1,
                maxGuests: 3
            });
            
            // Vérifier que l'extension hasPool fonctionne pour une résidence sans piscine
            expect(residenceWithoutPool).toHaveProperty('hasPool');
            expect(residenceWithoutPool.hasPool).toBe(false);
        });
        
        it('devrait calculer correctement isVacationResidence', async () => {
            const vacationResidence = await Residence.findById(residenceId);
            
            // Vérifier que l'extension isVacationResidence fonctionne
            expect(vacationResidence).toHaveProperty('isVacationResidence');
            expect(vacationResidence.isVacationResidence).toBe(true);
        });
        
        it('devrait calculer correctement isSpecialResidence', async () => {
            const specialResidence = await Residence.findById(residenceId);
            
            // Vérifier que l'extension isSpecialResidence fonctionne
            expect(specialResidence).toHaveProperty('isSpecialResidence');
            expect(specialResidence.isSpecialResidence).toBe(true);
        });
    });
    
    describe('Extension LocationExtension', () => {
        it('devrait extraire correctement l\'adresse formatée du dictionnaire de localisation', async () => {
            const residence = await Residence.findById(residenceId);
            
            // Vérifier que l'extension LocationExtension fonctionne
            expect(residence.location).toHaveProperty('formattedAddress');
            expect(residence.location.formattedAddress).toBe('123 Test Boulevard, Extension City, Test Country');
        });
        
        it('devrait fonctionner avec les données de réservation', async () => {
            // Créer un client pour la réservation
            const client = await User.create({
                name: 'Client Test',
                email: 'extension-client@test.com',
                password: 'Password123!',
                role: 'client'
            });
            
            // Créer une réservation
            const booking = await Booking.create({
                residence: residenceId,
                client: client._id,
                partner: partnerId,
                visitDate: new Date(Date.now() + 86400000),
                visitTime: '14:00',
                notes: 'Test des extensions avec réservation',
                status: BOOKING_STATUS.PENDING,
                guestCount: 2
            });
            
            // Récupérer la réservation avec les données de la résidence
            const populatedBooking = await Booking.findById(booking._id)
                .populate('residence')
                .populate('client')
                .populate('partner');
            
            // Vérifier que les extensions fonctionnent sur la résidence liée à la réservation
            expect(populatedBooking.residence).toHaveProperty('imageUrl');
            expect(populatedBooking.residence).toHaveProperty('title');
            expect(populatedBooking.residence).toHaveProperty('status');
            expect(populatedBooking.residence).toHaveProperty('hasPool');
            expect(populatedBooking.residence.location).toHaveProperty('formattedAddress');
        });
    });
});
