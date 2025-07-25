/**
 * Script autonome pour valider les schémas Joi
 * Aucune dépendance à Jest ou Mocha, s'exécute directement avec Node
 */

// Import des modules nécessaires
const path = require('path');

// Log colorisé
const log = {
  success: (msg) => console.log(`\x1b[32m✓ ${msg}\x1b[0m`),
  error: (msg) => console.log(`\x1b[31m✗ ${msg}\x1b[0m`), 
  info: (msg) => console.log(`\x1b[36mi ${msg}\x1b[0m`),
  title: (msg) => console.log(`\n\x1b[1m\x1b[36m${msg}\x1b[0m`)
};

// Import des schémas de validation
try {
  log.info('Chargement des schémas de validation...');
  const authValidation = require('../src/validations/auth.validation');
  const residenceValidation = require('../src/validations/residence.validation');

  // Teste un schéma avec des données valides et invalides
  function testSchema(name, schema, validData, invalidCases) {
    log.title(`Test du schéma: ${name}`);
    
    // Test des données valides
    const { error: validError } = schema.validate(validData);
    if (validError) {
      log.error(`Les données valides sont rejetées: ${validError.message}`);
    } else {
      log.success(`Les données valides sont acceptées`);
    }
    
    // Test des données invalides
    let invalidTests = 0;
    let invalidPassed = 0;
    
    Object.entries(invalidCases).forEach(([caseName, data]) => {
      invalidTests++;
      const { error } = schema.validate(data);
      if (error) {
        log.success(`Case "${caseName}": Correctement rejeté - ${error.message}`);
        invalidPassed++;
      } else {
        log.error(`Case "${caseName}": Incorrectement accepté!`);
      }
    });
    
    // Résumé
    console.log(`\nRésumé pour ${name}: ${invalidPassed}/${invalidTests} tests d'invalidité passés\n`);
    return validError === undefined && invalidPassed === invalidTests;
  }

  // ===== TESTS DE SCHÉMAS D'AUTHENTIFICATION =====
  
  // Test loginSchema
  const loginValid = { email: 'test@example.com', password: 'Password123!' };
  const loginInvalid = {
    'email manquant': { password: 'Password123!' },
    'email invalide': { email: 'not-an-email', password: 'Password123!' },
    'mot de passe manquant': { email: 'test@example.com' },
    'mot de passe court': { email: 'test@example.com', password: 'short' }
  };
  const loginResult = testSchema('loginSchema', authValidation.loginSchema, loginValid, loginInvalid);

  // Test registerSchema
  const registerValid = {
    name: 'John Doe',
    email: 'john@example.com',
    password: 'SecurePass123!',
    phoneNumber: '+33612345678'
  };
  const registerInvalid = {
    'email invalide': { 
      name: 'John Doe', 
      email: 'invalid-email',
      password: 'SecurePass123!',
      phoneNumber: '+33612345678'
    },
    'mot de passe faible': { 
      name: 'John Doe', 
      email: 'john@example.com',
      password: 'weak',
      phoneNumber: '+33612345678'
    }
  };
  const registerResult = testSchema('registerSchema', authValidation.registerSchema, registerValid, registerInvalid);

  // ===== TESTS DE SCHÉMAS DE RÉSIDENCE =====
  
  // Test createResidenceSchema
  const residenceValid = {
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
  
  const residenceInvalid = {
    'titre manquant': {
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
    },
    'prix négatif': {
      title: 'Appartement avec vue mer',
      description: 'Magnifique appartement avec vue sur la mer',
      address: '123 Avenue de la Plage',
      city: 'Nice',
      country: 'France',
      postalCode: '06000',
      price: -10,
      capacity: 4,
      rooms: 2,
      bathrooms: 1,
      type: 'apartment',
      latitude: 43.7102,
      longitude: 7.2620
    }
  };
  
  const residenceResult = testSchema('createResidenceSchema', residenceValidation.createResidenceSchema, residenceValid, residenceInvalid);

  // === Résumé final ===
  log.title('RÉSUMÉ DES VALIDATIONS');
  
  if (loginResult) log.success('loginSchema: VALIDÉ'); 
  else log.error('loginSchema: ÉCHEC');
  
  if (registerResult) log.success('registerSchema: VALIDÉ'); 
  else log.error('registerSchema: ÉCHEC');
  
  if (residenceResult) log.success('createResidenceSchema: VALIDÉ'); 
  else log.error('createResidenceSchema: ÉCHEC');

  const overallSuccess = loginResult && registerResult && residenceResult;
  
  if (overallSuccess) {
    log.title('TOUS LES SCHÉMAS DE VALIDATION SONT VALIDES ✅');
    process.exit(0);
  } else {
    log.title('CERTAINS SCHÉMAS DE VALIDATION ONT ÉCHOUÉ ❌');
    process.exit(1);
  }

} catch (err) {
  log.error(`ERREUR LORS DE L'EXÉCUTION DES TESTS DE VALIDATION:`);
  console.error(err);
  process.exit(1);
}
