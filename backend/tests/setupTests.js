/**
 * Configuration globale pour les tests Jest
 * Ce fichier est automatiquement chargé par Jest avant l'exécution des tests
 */

const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
let mongoServer;

// Exporter la fonction generateToken pour qu'elle soit disponible dans tous les tests
const { generateToken } = require('./helpers/auth.helper');
global.generateToken = generateToken;

// Définir un CSRF token fictif pour les tests
global.csrfToken = 'test-csrf-token-for-testing';

// Setup avant tous les tests
beforeAll(async () => {
  // Créer une instance MongoDB en mémoire pour les tests
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  
  // Configurer mongoose
  await mongoose.connect(uri, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });
  
  console.log('Connexion établie à la base de test MongoDB en mémoire');
});

// Nettoyage après chaque test
afterEach(async () => {
  // Vider les collections
  if (mongoose.connection.readyState === 1) {
    const collections = mongoose.connection.collections;
    for (const key in collections) {
      await collections[key].deleteMany({});
    }
  }
});

// Nettoyage après tous les tests
afterAll(async () => {
  // Fermer la connexion mongoose
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
  }
  
  // Arrêter le serveur MongoDB
  if (mongoServer) {
    await mongoServer.stop();
  }
  
  console.log('Connexion fermée à la base de test MongoDB');
});

// Augmenter le timeout des tests
jest.setTimeout(30000);

// Éviter les warnings pour les promesses non gérées
process.on('unhandledRejection', (reason, promise) => {
  console.error('Promesse non gérée dans les tests:', reason);
});
