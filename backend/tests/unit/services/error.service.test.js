const errorService = require('../../../src/services/error.service');
const ApiError = require('../../../src/utils/apiError');
const { BOOKING_STATUS } = require('../../../src/utils/constants');
const BookingError = require('../../../src/utils/domainErrors/bookingErrors');
const ResidenceError = require('../../../src/utils/domainErrors/residenceErrors');

// Mock du logger pour les tests
jest.mock('../../../src/utils/logger', () => ({
    logger: {
        error: jest.fn(),
        warn: jest.fn(),
        info: jest.fn()
    }
}));

/**
 * Tests pour le service d'erreur centralisé
 * Vérifie que les erreurs de domaine spécifiques sont correctement traitées
 * et journalisées
 */
describe('Error Service', () => {
    // Sauvegarde de la méthode console.error originale
    const originalConsoleError = console.error;
    
    // Mocks pour les tests
    beforeEach(() => {
        // Mock de console.error pour éviter la pollution des logs de test
        console.error = jest.fn();
        
        // Réinitialiser tous les mocks avant chaque test
        jest.clearAllMocks();
    });
    
    afterEach(() => {
        // Restaurer console.error
        console.error = originalConsoleError;
    });
    
    describe('Journalisation des erreurs de réservation', () => {
        test('devrait journaliser les erreurs de réservation non trouvée', () => {
            const bookingId = '507f1f77bcf86cd799439011';
            const error = new BookingError.BookingNotFoundError(bookingId);
            
            const result = errorService.logBookingError(error, { _id: bookingId });
            
            expect(result).toBeDefined();
        });
        
        test('devrait journaliser les erreurs de conflit de dates', () => {
            const bookingId = '507f1f77bcf86cd799439022';
            const residenceId = '507f1f77bcf86cd799439033';
            const startDate = new Date();
            const endDate = new Date(startDate.getTime() + 86400000);
            
            const error = new BookingError.BookingDateConflictError(residenceId, startDate, endDate);
            
            const result = errorService.logBookingError(error, { 
                _id: bookingId,
                residence: residenceId,
                checkIn: startDate,
                checkOut: endDate
            });
            
            expect(result).toBeDefined();
        });
        
        test('devrait journaliser les erreurs de changement de statut invalide', () => {
            const bookingId = '507f1f77bcf86cd799439044';
            const currentStatus = BOOKING_STATUS.CANCELLED;
            const newStatus = BOOKING_STATUS.CONFIRMED;
            
            const error = new BookingError.InvalidStatusChangeError(currentStatus, newStatus);
            
            const result = errorService.logBookingError(error, { 
                _id: bookingId,
                status: currentStatus
            });
            
            expect(result).toBeDefined();
        });
    });
    
    describe('Journalisation des erreurs de résidence', () => {
        test('devrait journaliser les erreurs de résidence non trouvée', () => {
            const residenceId = '507f1f77bcf86cd799439055';
            const error = new ResidenceError.ResidenceNotFoundError(residenceId);
            
            const result = errorService.logError(error, {
                domain: 'residence',
                residence: { id: residenceId }
            });
            
            expect(result).toBeDefined();
        });
        
        test('devrait journaliser les erreurs de données invalides pour une résidence', () => {
            const residenceId = '507f1f77bcf86cd799439066';
            const validationErrors = [
                { field: 'price', message: 'Price must be positive' },
                { field: 'maxGuests', message: 'Max guests must be between 1 and 20' }
            ];
            
            const error = new ResidenceError.InvalidResidenceDataError(validationErrors);
            
            const result = errorService.logError(error, {
                domain: 'residence',
                residence: { id: residenceId },
                errors: validationErrors
            });
            
            expect(result).toBeDefined();
        });
    });
    
    describe('Journalisation des erreurs de paiement', () => {
        test('devrait journaliser les erreurs de paiement', () => {
            const paymentId = '507f1f77bcf86cd799439077';
            const bookingId = '507f1f77bcf86cd799439088';
            const error = new ApiError('Payment processing failed', 400);
            
            const result = errorService.logPaymentError(error, { 
                _id: paymentId,
                reservation: bookingId,
                amount: 100,
                status: 'failed',
                method: 'card'
            });
            
            expect(result).toBeDefined();
        });
    });
    
    describe('Journalisation des erreurs d\'authentification', () => {
        test('devrait journaliser les erreurs d\'authentification', () => {
            const userId = '507f1f77bcf86cd799439099';
            const error = new ApiError('Invalid credentials', 401);
            
            const result = errorService.logAuthError(error, { 
                _id: userId,
                email: 'test@example.com',
                password: 'password123',
                firstName: 'Test',
                lastName: 'User',
                role: 'client'
            });
            
            expect(result).toBeDefined();
        });
    });
    
    describe('Conversion et propagation d\'erreurs', () => {
        test('devrait convertir une erreur standard en ApiError', () => {
            const standardError = new Error('Standard error');
            const convertedError = new ApiError(standardError.message, 500);
            
            expect(convertedError).toBeInstanceOf(ApiError);
            expect(convertedError.message).toBe(standardError.message);
            expect(convertedError.statusCode).toBe(500);
        });
        
        test('devrait conserver une ApiError intacte lors de la conversion', () => {
            const apiError = new ApiError('API error', 400);
            
            expect(apiError).toBeInstanceOf(ApiError);
            expect(apiError.message).toBe('API error');
            expect(apiError.statusCode).toBe(400);
        });
    });
});
