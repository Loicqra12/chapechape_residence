const {
  createResidence,
  updateResidence,
  uploadImages,
  deleteImage,
  updateFaqs,
} = require('../../src/validations/residence.validation');

const createBody = createResidence.body;
const updateBody = updateResidence.body;
const uploadParams = uploadImages.params;
const deleteParams = deleteImage.params;
const faqBody = updateFaqs.body;

const validCreate = {
  title: 'Studio Cocody test',
  description: 'Description test résidence assez longue',
  price: 1000,
  type: 'apartment',
  bedrooms: 1,
  bathrooms: 1,
  area: 40,
  maxOccupancy: 2,
  features: ['wifi'],
  amenities: ['wifi'],
  location: {
    address: 'Rue Test 1',
    city: 'Abidjan',
    state: 'Lagunes',
    country: 'CI',
    coordinates: { latitude: 5.36, longitude: -4.01 },
  },
};

describe('Residence Joi (contrats actuels)', () => {
  describe('createResidence', () => {
    it('CURRENT : payload canonique (title, location objet, bedrooms, maxOccupancy)', () => {
      const { error, value } = createBody.validate(validCreate);
      expect(error).toBeUndefined();
      expect(value.title).toBe(validCreate.title);
      expect(value.location.city).toBe('Abidjan');
    });

    it('CURRENT : prix négatif rejeté', () => {
      expect(createBody.validate({ ...validCreate, price: -1 }).error).toBeDefined();
    });

    it('CURRENT : titre manquant rejeté', () => {
      const { title, ...rest } = validCreate;
      expect(createBody.validate(rest).error).toBeDefined();
    });

    it('CURRENT : type hors enum rejeté', () => {
      expect(createBody.validate({ ...validCreate, type: 'spaceship' }).error).toBeDefined();
    });

    it('OBSOLETE : imageUrl / owner / rooms / coordinates-array ne sont pas le contrat', () => {
      expect(createBody.validate({ ...validCreate, imageUrl: 'http://x/y.jpg' }).error).toBeDefined();
      expect(createBody.validate({
        ...validCreate,
        location: { ...validCreate.location, coordinates: [5.36, -4.01] },
      }).error).toBeDefined();
    });

    it('SERVER-DERIVED : publicationStatus et verified sont strip, jamais persistés via create', () => {
      const { error, value } = createBody.validate({
        ...validCreate,
        publicationStatus: 'published',
        verified: true,
        verifiedBy: '507f1f77bcf86cd799439011',
      });
      expect(error).toBeUndefined();
      expect(value.publicationStatus).toBeUndefined();
      expect(value.verified).toBeUndefined();
      expect(value.verifiedBy).toBeUndefined();
    });
  });

  describe('updateResidence + P2-02C', () => {
    it('CURRENT : PATCH titre/prix autorisé', () => {
      expect(updateBody.validate({ title: 'Nouveau titre ok', price: 2000 }).error).toBeUndefined();
    });

    it('publicationStatus ne peut pas être mass-assigné (strip + min 1)', () => {
      const onlyStatus = updateBody.validate({ publicationStatus: 'published' });
      expect(onlyStatus.error).toBeDefined();

      const { error, value } = updateBody.validate({
        title: 'Titre toujours valide ici',
        publicationStatus: 'published',
        verified: true,
      });
      expect(error).toBeUndefined();
      expect(value.publicationStatus).toBeUndefined();
      expect(value.verified).toBeUndefined();
      expect(value.title).toBe('Titre toujours valide ici');
    });
  });

  describe('images / faqs', () => {
    it('uploadImages : ObjectId résidence requis (pas un wrapper params)', () => {
      expect(uploadParams.validate({ id: '60d21b4667d0d8992e610c85' }).error).toBeUndefined();
      expect(uploadParams.validate({ id: 'bad' }).error).toBeDefined();
    });

    it('deleteImage : id + imageIndex (index, pas imageId legacy)', () => {
      expect(deleteParams.validate({ id: '60d21b4667d0d8992e610c85', imageIndex: 0 }).error).toBeUndefined();
      expect(deleteParams.validate({ id: '60d21b4667d0d8992e610c85', imageId: '60d21b4667d0d8992e610c86' }).error).toBeDefined();
    });

    it('updateFaqs : question/réponse min 5', () => {
      expect(faqBody.validate({
        faqs: [{ question: 'Heure d arrivée?', answer: 'A partir de 14h' }],
      }).error).toBeUndefined();
      expect(faqBody.validate({ faqs: [{ question: '?', answer: 'x' }] }).error).toBeDefined();
    });
  });
});
