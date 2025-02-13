const mongoose = require('mongoose');

const loginAttemptSchema = new mongoose.Schema({
    ip: {
        type: String,
        required: [true, 'IP address is required'],
        index: true
    },
    email: {
        type: String,
        required: [true, 'Email is required'],
        lowercase: true,
        index: true
    },
    success: {
        type: Boolean,
        default: false
    },
    blockedUntil: {
        type: Date,
        default: null
    },
    attempts: {
        type: Number,
        default: 1
    },
    lastAttempt: {
        type: Date,
        default: Date.now
    }
}, {
    timestamps: true
});

// Index composé pour les requêtes fréquentes
loginAttemptSchema.index({ ip: 1, email: 1, lastAttempt: -1 });

module.exports = mongoose.model('LoginAttempt', loginAttemptSchema);
