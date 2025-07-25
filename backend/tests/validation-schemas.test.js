/**
 * Tests unitaires des schémas de validation Joi
 * Utilisation de Jest pour rester compatible avec l'infrastructure de test existante
 */

/**
 * Import des schémas de validation à tester
 */
const { login, register } = require('../src/validations/auth.validation');
const { createResidence, uploadImages, deleteImage } = require('../src/validations/residence.validation');

// Extraire les schémas Joi du sous-objet body ou params selon le cas
const loginSchema = login.body;
const registerSchema = register.body;
const createResidenceSchema = createResidence.body;
const uploadImageSchema = uploadImages.params;
const deleteImageSchema = deleteImage.params;

describe('Validation des schémas Joi', () => {
  
  describe('Schémas d\'authentification', () => {
    
    describe('loginSchema', () => {
      const validData = { email: 'test@example.com', password: 'Password123!' };
      
      test('devrait valider les données correctes', () => {
        const { error } = loginSchema.validate(validData);
        expect(error).toBeUndefined();
      });
      
      test('devrait rejeter un email manquant', () => {
        const { error } = loginSchema.validate({ password: 'Password123!' });
        expect(error).toBeDefined();
      });
      
      test('devrait rejeter un email invalide', () => {
        const { error } = loginSchema.validate({ email: 'not-an-email', password: 'Password123!' });
        expect(error).toBeDefined();
      });
      
      test('devrait rejeter un mot de passe manquant', () => {
        const { error } = loginSchema.validate({ email: 'test@example.com' });
        expect(error).toBeDefined();
      });
      
      test('devrait rejeter un mot de passe trop court', () => {
        const { error } = loginSchema.validate({ email: 'test@example.com', password: 'short' });
        expect(error).toBeDefined();
      });
    });
    
    describe('registerSchema', () => {
      const validData = {
        name: 'John Doe',
        email: 'john@example.com',
        password: 'SecurePass123!',
        phoneNumber: '+33612345678'
      };
      
      test('devrait valider les données correctes', () => {
        const { error } = registerSchema.validate(validData);
        expect(error).toBeUndefined();
      });
      
      test('devrait rejeter un email invalide', () => {
        const invalidData = { ...validData, email: 'invalid-email' };
        const { error } = registerSchema.validate(invalidData);
        expect(error).toBeDefined();
      });
      
      test('devrait rejeter un mot de passe faible', () => {
        const invalidData = { ...validData, password: 'weak' };
        const { error } = registerSchema.validate(invalidData);
        expect(error).toBeDefined();
      });
    });
  });
  
  describe('Schémas de résidences', () => {
    
    describe('createResidenceSchema', () => {
      const validData = {
        title: 'Appartement avec vue mer',
        description: 'Magnifique appartement avec vue sur la mer',
        address: '123 Avenue de la Plage',
        city: 'Nice',
        country: 'France',
        postalCode: '06000',
        price: 100,
        capacity: 4,
        rooms: 2,
        bathrooms: 1,
        type: 'apartment',
        latitude: 43.7102,
        longitude: 7.2620
      };
      
      test('devrait valider les données correctes', () => {
        const { error } = createResidenceSchema.validate(validData);
        expect(error).toBeUndefined();
      });
      
      test('devrait rejeter un titre manquant', () => {
        const { title, ...invalidData } = validData;
        const { error } = createResidenceSchema.validate(invalidData);
        expect(error).toBeDefined();
      });
      
      test('devrait rejeter un prix négatif', () => {
        const invalidData = { ...validData, price: -10 };
        const { error } = createResidenceSchema.validate(invalidData);
        expect(error).toBeDefined();
      });
    });
    
    describe('uploadImageSchema', () => {
      const validData = {
        params: { id: '60d21b4667d0d8992e610c85' }
      };
      
      test('devrait valider les données correctes', () => {
        const { error } = uploadImageSchema.validate(validData);
        expect(error).toBeUndefined();
      });
      
      test('devrait rejeter un ID invalide', () => {
        const invalidData = { params: { id: 'invalid-id' } };
        const { error } = uploadImageSchema.validate(invalidData);
        expect(error).toBeDefined();
      });
    });
    
    describe('deleteImageSchema', () => {
      const validData = {
        params: {
          id: '60d21b4667d0d8992e610c85',
          imageId: '60d21b4667d0d8992e610c86'
        }
      };
      
      test('devrait valider les données correctes', () => {
        const { error } = deleteImageSchema.validate(validData);
        expect(error).toBeUndefined();
      });
      
      test('devrait rejeter des IDs invalides', () => {
        const invalidData = {
          params: { id: 'invalid-id', imageId: 'invalid-id' }
        };
        const { error } = deleteImageSchema.validate(invalidData);
        expect(error).toBeDefined();
      });
    });
  });
});
