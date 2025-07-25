// Importer les validations correctement
const {
  createResidence,
  updateResidence,
  getResidence,
  uploadImages,
  deleteImage,
  updateFaqs,
  updatePaymentMethods,
  updateEnhancedAmenities,
  addPaymentMethod,
  deletePaymentMethod,
  addFaq
} = require('../../src/validations/residence.validation');
const { objectId } = require('../../src/validations/custom.validation');

// Extraire les schémas Joi du sous-objet body ou params selon le schéma
const createResidenceSchema = createResidence.body;
const updateResidenceSchema = updateResidence.body;
const getResidenceSchema = getResidence.params;
const uploadImageSchema = uploadImages.params;
const deleteImageSchema = deleteImage.params;
const updateFaqSchema = updateFaqs.body;
const updatePaymentMethodsSchema = updatePaymentMethods.body;
const updateEnhancedAmenitiesSchema = updateEnhancedAmenities.body;
const addPaymentMethodSchema = addPaymentMethod.body;
const deletePaymentMethodSchema = deletePaymentMethod.params;
const addFaqSchema = addFaq.body;

// Utiliser Jest au lieu de Chai

// Suppression de l'import du setup pour éviter les conflits

describe('Schémas de validation des résidences', () => {
  
  describe('createResidenceSchema', () => {
    const validData = {
      title: 'Appartement moderne au centre-ville',
      description: 'Superbe appartement avec vue imprenable',
      price: 95.50,
      location: {
        country: 'France',
        city: 'Paris',
        address: '15 Rue de la Paix',
        coordinates: [48.8566, 2.3522]
      },
      owner: '60d5ec9c1346f3244d8b9113', // ID MongoDB fictif
      amenities: ['wifi', 'tv', 'kitchen'],
      rooms: 2,
      bathrooms: 1,
      capacity: 4,
      type: 'apartment'
    };
    
    const invalidData = {
      'titre manquant': { ...validData, title: undefined },
      'prix négatif': { ...validData, price: -50 },
      'localisation incomplète': { 
        ...validData, 
        location: { country: 'France', city: 'Paris' } 
      },
      'owner ID invalide': { ...validData, owner: 'invalid-id' },
      'type invalide': { ...validData, type: 'invalid-type' }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = createResidenceSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = createResidenceSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });

  describe('uploadImageSchema', () => {
    const validData = {
      params: {
        id: '60d5ec9c1346f3244d8b9113' // ID MongoDB fictif
      }
    };
    
    const invalidData = {
      'ID manquant': { params: {} },
      'ID invalide': { params: { id: 'invalid-id' } }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = uploadImageSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = uploadImageSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });

  describe('deleteImageSchema', () => {
    const validData = {
      params: {
        id: '60d5ec9c1346f3244d8b9113', // ID résidence
        imageId: '60d5ec9c1346f3244d8b9114' // ID image
      }
    };
    
    const invalidData = {
      'ID résidence manquant': { params: { imageId: '60d5ec9c1346f3244d8b9114' } },
      'ID image manquant': { params: { id: '60d5ec9c1346f3244d8b9113' } },
      'IDs invalides': { params: { id: 'invalid-id', imageId: 'invalid-id' } }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = deleteImageSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = deleteImageSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });
  
  describe('updateFaqSchema', () => {
    const validData = {
      params: {
        id: '60d5ec9c1346f3244d8b9113'
      },
      body: {
        faqs: [
          { question: 'Heure d\'arrivée?', answer: 'À partir de 14h' },
          { question: 'Wi-Fi disponible?', answer: 'Oui, gratuit' }
        ]
      }
    };
    
    const invalidData = {
      'ID invalide': { 
        params: { id: 'invalid-id' },
        body: { faqs: [{ question: 'Question?', answer: 'Réponse' }] }
      },
      'FAQ mal formatée': { 
        params: { id: '60d5ec9c1346f3244d8b9113' },
        body: { faqs: [{ question: '' }] }
      },
      'FAQs non spécifiées': { 
        params: { id: '60d5ec9c1346f3244d8b9113' },
        body: {}
      }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = updateFaqSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = updateFaqSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });
});
