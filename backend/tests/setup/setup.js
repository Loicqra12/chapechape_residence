const chai = require('chai');
const sinon = require('sinon');

// Uniquement pour des tests de validation Joi (pas besoin de chai-http)
// NOTE: La partie chai-http a été désactivée car elle provoque une erreur avec ESM

// Export des outils de test pour une utilisation globale
global.chai = chai;
global.expect = chai.expect;
global.assert = chai.assert;
global.sinon = sinon;

// Fonction utilitaire pour tester les schémas Joi
global.testJoiSchema = (schema, validData, invalidData) => {
  describe('Validation', () => {
    it('devrait valider les données correctes', () => {
      const { error } = schema.validate(validData);
      expect(error).to.be.undefined;
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = schema.validate(invalidData[key]);
        expect(error).to.not.be.undefined;
      });
    });
  });
};

// Environnement de test
process.env.NODE_ENV = 'test';

// Fonction pour nettoyer après les tests
global.cleanDatabase = async (models) => {
  if (!models || !Array.isArray(models)) return;
  
  for (const model of models) {
    try {
      await model.deleteMany({});
    } catch (error) {
      console.error(`Erreur lors de la suppression des données de ${model.modelName}:`, error);
    }
  }
};

console.log('Configuration des tests chargée avec succès');
