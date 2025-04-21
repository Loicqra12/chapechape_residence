const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
const request = require('supertest');
// Import de l'application de test au lieu de l'application standard
const app = require('../src/app.test');
require('dotenv').config({ path: '.env.test' });

let mongod;
// Token CSRF pour les tests
global.csrfToken = 'test-csrf-token';
// Variable pour stocker un token d'authentification généré pour les tests
global.authToken = null;

// Configuration globale pour les tests
beforeAll(async () => {
    // Silence les logs pendant les tests
    console.log = jest.fn();
    console.info = jest.fn();
    console.warn = jest.fn();
    // Garder console.error pour le débogage

    // Initialiser la base de données de test
    mongod = await MongoMemoryServer.create();
    const uri = mongod.getUri();
    await mongoose.connect(uri);
    
    // Génération d'un token d'authentification pour les tests qui en ont besoin
    try {
        // Créer un utilisateur de test et récupérer un token
        const userResponse = await request(app)
            .post('/api/auth/register')
            .set('X-CSRF-Token', global.csrfToken)
            .send({
                name: 'Test User',
                email: 'testuser@example.com',
                password: 'Password123!',
                role: 'client' // Correction de 'user' à 'client' pour respecter l'enum du modèle
            });
            
        if (userResponse.body && userResponse.body.data && userResponse.body.data.token) {
            global.authToken = userResponse.body.data.token;
            console.error('Token d\'authentification généré pour les tests');
        }
    } catch (error) {
        console.error('Erreur lors de la génération du token:', error);
    }
});

// Nettoyer la base de données après chaque test
afterEach(async () => {
    const collections = mongoose.connection.collections;
    for (const key in collections) {
        await collections[key].deleteMany();
    }
    jest.clearAllMocks();
});

// Fermer la connexion après tous les tests
afterAll(async () => {
    if (mongoose.connection.readyState !== 0) {
        await mongoose.connection.dropDatabase();
        await mongoose.connection.close();
    }
    if (mongod) {
        await mongod.stop();
    }
});

// Configuration des matchers personnalisés
expect.extend({
  toBeWithinRange(received, floor, ceiling) {
    const pass = received >= floor && received <= ceiling;
    if (pass) {
      return {
        message: () =>
          `expected ${received} not to be within range ${floor} - ${ceiling}`,
        pass: true,
      };
    } else {
      return {
        message: () =>
          `expected ${received} to be within range ${floor} - ${ceiling}`,
        pass: false,
      };
    }
  },
});
