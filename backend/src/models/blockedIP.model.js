const mongoose = require('mongoose');

const blockedIPSchema = new mongoose.Schema({
    ip: {
        type: String,
        required: true,
        unique: true,
        index: true
    },
    reason: {
        type: String,
        required: true
    },
    blockedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    attempts: {
        type: Number,
        default: 1
    },
    lastAttempt: {
        type: Date,
        default: Date.now
    },
    expiresAt: {
        type: Date,
        default: () => new Date(+new Date() + 24*60*60*1000) // Par défaut, bloque pour 24 heures
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Index pour l'expiration automatique (IP index déjà créé par unique: true)
blockedIPSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

module.exports = mongoose.model('BlockedIP', blockedIPSchema);
