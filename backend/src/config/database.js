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
            w: 'majority',
            autoIndex: false,
        };
        
        const conn = await mongoose.connect(process.env.MONGODB_URI, options);
        logger.info(`MongoDB Connected: ${conn.connection.host}`);

        if (process.env.SYNC_INVENTORY_LOCK_INDEXES === 'true') {
            try {
                const InventoryLock = require('../models/inventory-lock.model');
                await InventoryLock.syncIndexes();
                logger.info('InventoryLock indexes synchronisés (SYNC_INVENTORY_LOCK_INDEXES=true)');
            } catch (indexErr) {
                logger.error('Échec syncIndexes InventoryLock', { err: indexErr.message });
            }
        } else {
            logger.info('InventoryLock syncIndexes ignoré — vérifier fingerprint prod avant SYNC_INVENTORY_LOCK_INDEXES=true');
        }

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
