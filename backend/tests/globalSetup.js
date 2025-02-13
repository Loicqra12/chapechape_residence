const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

module.exports = async () => {
    const mongod = await MongoMemoryServer.create();
    const uri = mongod.getUri();
    
    global.__MONGOD__ = mongod;
    process.env.MONGODB_URI = uri;
    
    // Configuration additionnelle pour les tests
    process.env.JWT_SECRET = 'test-secret-key';
    process.env.NODE_ENV = 'test';
};
