/**
 * Configuration globale pour les tests Jest
 * Ce fichier est automatiquement chargé par Jest avant l'exécution des tests
 */

const mongoose = require('mongoose');
const { MongoMemoryReplSet } = require('mongodb-memory-server');
let mongoServer;

process.env.JWT_SECRET = process.env.JWT_SECRET || 'test_secret_for_ci_at_least_32_chars_ok';
process.env.JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'test_refresh_secret_at_least_32_ok';
process.env.COOKIE_SECRET = process.env.COOKIE_SECRET || 'test-cookie-secret-not-for-production';
process.env.RATE_LIMIT_USE_MEMORY = 'true';
process.env.TRUST_PROXY = process.env.TRUST_PROXY || '0';
// P2-08B — race timeout in isUserOnline is not cleared when fetchSockets wins first;
// keep test window below Jest's 1s post-run exit check (production default unchanged).
process.env.SOCKET_PRESENCE_TIMEOUT_MS = process.env.SOCKET_PRESENCE_TIMEOUT_MS || '100';

// Exporter la fonction generateToken pour qu'elle soit disponible dans tous les tests
const { generateToken } = require('./helpers/auth.helper');
global.generateToken = generateToken;

// Définir un CSRF token fictif pour les tests
global.csrfToken = 'test-csrf-token-for-testing';

// Setup avant tous les tests — replica set requis pour les transactions Mongo (createReservation)
beforeAll(async () => {
  mongoServer = await MongoMemoryReplSet.create({
    instanceOpts: [{ launchTimeout: 120000, storageEngine: 'wiredTiger' }],
    replSet: { count: 1 },
  });
  const uri = mongoServer.getUri();

  await mongoose.connect(uri);

  console.log('Connexion établie à MongoMemoryReplSet (transactions activées)');
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
jest.setTimeout(120000);

// Éviter les warnings pour les promesses non gérées
process.on('unhandledRejection', (reason, promise) => {
  console.error('Promesse non gérée dans les tests:', reason);
});
