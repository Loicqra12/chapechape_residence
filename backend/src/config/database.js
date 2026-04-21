const mongoose = require('mongoose');
const logger = require('../utils/logger');

const maskMongoUri = (uri = '') => uri.replace(/:\/\/([^:]+):([^@]+)@/, '://$1:****@');

const connectDB = async () => {
    try {
        logger.info(`Trying to connect to MongoDB: ${maskMongoUri(process.env.MONGODB_URI || '')}`);
        
        // Options modernes pour MongoDB driver v4+
        const options = {
            ssl: true,
            tls: true,
            maxPoolSize: 10,
            serverSelectionTimeoutMS: 30000,
            socketTimeoutMS: 45000,
            retryWrites: true,
            w: 'majority'
        };
        
        const conn = await mongoose.connect(process.env.MONGODB_URI, options);
        logger.info(`MongoDB Connected: ${conn.connection.host}`);

        mongoose.connection.on('disconnected', () => {
            logger.error('MongoDB disconnected');
        });

        mongoose.connection.on('reconnected', () => {
            logger.info('MongoDB reconnected');
        });
    } catch (error) {
        logger.error('MongoDB connection error:', error);
        throw error;
    }
};

module.exports = connectDB;
