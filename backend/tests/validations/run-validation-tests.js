/**
 * Script autonome pour exécuter les tests de validation Joi
 * Ce script contourne les problèmes de configuration entre Jest et Mocha
 */

const Joi = require('joi');
const chai = require('chai');
const { expect } = chai;

// Import des schémas de validation
const authValidations = require('../../src/validations/auth.validation');
const residenceValidations = require('../../src/validations/residence.validation');

// Fonction utilitaire pour tester les schémas Joi
function testJoiSchema(schema, validData, invalidData, name) {
  console.log(`\n--------- Test du schéma: ${name} ---------`);
  
  // Test des données valides
  const validResult = schema.validate(validData);
  if (validResult.error) {
    console.error(`❌ ÉCHEC: Les données valides sont rejetées: ${validResult.error.message}`);
  } else {
    console.log(`✅ SUCCÈS: Les données valides sont acceptées`);
  }
  
  // Test des données invalides
  let allInvalidTestsPassed = true;
  Object.keys(invalidData).forEach(key => {
    const invalidResult = schema.validate(invalidData[key]);
    if (!invalidResult.error) {
      console.error(`❌ ÉCHEC: Les données invalides (${key}) sont acceptées à tort`);
      allInvalidTestsPassed = false;
    } else {
      console.log(`✅ SUCCÈS: Les données invalides (${key}) sont correctement rejetées`);
    }
  });
  
  if (allInvalidTestsPassed) {
    console.log(`✅ TOUS LES TESTS D'INVALIDITÉ ONT PASSÉ`);
  } else {
    console.log(`❌ CERTAINS TESTS D'INVALIDITÉ ONT ÉCHOUÉ`);
  }
  
  console.log(`----------------------------------------\n`);
  
  return !validResult.error && allInvalidTestsPassed;
}

// Données de test pour l'authentification
const authTests = {
  login: {
    schema: authValidations.loginSchema,
    valid: { email: 'user@example.com', password: 'Password123!' },
    invalid: {
      'email manquant': { password: 'Password123!' },
      'email invalide': { email: 'not-an-email', password: 'Password123!' },
      'mot de passe manquant': { email: 'user@example.com' },
      'mot de passe trop court': { email: 'user@example.com', password: 'Pass1!' }
    }
  },
  register: {
    schema: authValidations.registerSchema,
    valid: {
      name: 'John Doe',
      email: 'john@example.com',
      password: 'SecurePass123!',
      phoneNumber: '+33612345678',
      role: 'user'
    },
    invalid: {
      'email invalide': { 
        name: 'John Doe',
        email: 'invalid-email', 
        password: 'SecurePass123!', 
        phoneNumber: '+33612345678', 
        role: 'user' 
      },
      'mot de passe trop court': { 
        name: 'John Doe',
        email: 'john@example.com', 
        password: 'short', 
        phoneNumber: '+33612345678', 
        role: 'user' 
      }
    }
  }
};

// Données de test pour les résidences
const residenceTests = {
  createResidence: {
    schema: residenceValidations.createResidenceSchema,
    valid: {
      title: 'Résidence de luxe',
      description: 'Belle résidence avec vue sur mer',
      address: '123 Rue de la Plage',
      city: 'Nice',
      postalCode: '06000',
      country: 'France',
      price: 150,
      capacity: 4,
      rooms: 2,
      bathrooms: 1,
      latitude: 43.7102,
      longitude: 7.2620,
      type: 'apartment'
    },
    invalid: {
      'titre manquant': {
        description: 'Belle résidence avec vue sur mer',
        address: '123 Rue de la Plage',
        city: 'Nice',
        postalCode: '06000',
        country: 'France',
        price: 150,
        capacity: 4,
        rooms: 2,
        bathrooms: 1,
        latitude: 43.7102,
        longitude: 7.2620,
        type: 'apartment'
      },
      'prix négatif': {
        title: 'Résidence de luxe',
        description: 'Belle résidence avec vue sur mer',
        address: '123 Rue de la Plage',
        city: 'Nice',
        postalCode: '06000',
        country: 'France',
        price: -50,
        capacity: 4,
        rooms: 2,
        bathrooms: 1,
        latitude: 43.7102,
        longitude: 7.2620,
        type: 'apartment'
      }
    }
  }
};

// Exécution des tests
console.log(`\n==== TESTS DE VALIDATION JOI AUTONOMES ====\n`);

console.log(`\n=== TESTS D'AUTHENTIFICATION ===\n`);
let authTestsPassed = true;
Object.keys(authTests).forEach(testName => {
  const test = authTests[testName];
  const passed = testJoiSchema(test.schema, test.valid, test.invalid, testName);
  if (!passed) authTestsPassed = false;
});

console.log(`\n=== TESTS DE RÉSIDENCES ===\n`);
let residenceTestsPassed = true;
Object.keys(residenceTests).forEach(testName => {
  const test = residenceTests[testName];
  const passed = testJoiSchema(test.schema, test.valid, test.invalid, testName);
  if (!passed) residenceTestsPassed = false;
});

// Résumé final
console.log(`\n==== RÉSUMÉ DES TESTS ====\n`);
console.log(`Tests d'authentification: ${authTestsPassed ? '✅ SUCCÈS' : '❌ ÉCHEC'}`);
console.log(`Tests de résidences: ${residenceTestsPassed ? '✅ SUCCÈS' : '❌ ÉCHEC'}`);
console.log(`\n=========================\n`);

if (authTestsPassed && residenceTestsPassed) {
  console.log('✅ TOUS LES TESTS DE VALIDATION ONT PASSÉ AVEC SUCCÈS');
  process.exit(0);
} else {
  console.log('❌ CERTAINS TESTS DE VALIDATION ONT ÉCHOUÉ');
  process.exit(1);
}
