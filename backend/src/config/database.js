const mongoose = require('mongoose');

const connectDB = async () => {
    try {
        console.log('Trying to connect to MongoDB with URI:', process.env.MONGODB_URI);
        
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
        console.log(`MongoDB Connected: ${conn.connection.host}`);
    } catch (error) {
        console.error('MongoDB connection error:', error);
        process.exit(1);
    }
};

module.exports = connectDB;
