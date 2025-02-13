const { MongoMemoryServer } = require('mongodb-memory-server');
const mongoose = require('mongoose');
require('dotenv').config({ path: '.env.test' });

let mongod;

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
