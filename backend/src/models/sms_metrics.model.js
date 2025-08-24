const mongoose = require('mongoose');

/**
 * Modèle SMSMetrics - Métriques d'envoi SMS
 * Utilisé pour tracker les performances des envois SMS
 */
const smsMetricsSchema = new mongoose.Schema({
    // Informations de base
    phoneNumber: {
        type: String,
        required: true,
        trim: true
    },
    message: {
        type: String,
        required: true
    },
    status: {
        type: String,
        enum: ['sent', 'delivered', 'failed', 'pending'],
        default: 'pending'
    },
    
    // Métadonnées
    provider: {
        type: String,
        enum: ['twilio', 'other'],
        default: 'twilio'
    },
    messageId: {
        type: String,
        sparse: true
    },
    cost: {
        type: Number,
        default: 0
    },
    
    // Contexte métier
    relatedModel: {
        type: String,
        enum: ['booking', 'payout', 'notification', 'other']
    },
    relatedId: {
        type: mongoose.Schema.Types.ObjectId,
        sparse: true
    },
    
    // Timestamps
    sentAt: {
        type: Date,
        default: Date.now
    },
    deliveredAt: Date,
    failedAt: Date
}, {
    timestamps: true
});

// Index pour performance
smsMetricsSchema.index({ phoneNumber: 1, status: 1 });
smsMetricsSchema.index({ createdAt: -1 });
smsMetricsSchema.index({ relatedModel: 1, relatedId: 1 });

module.exports = mongoose.model('SMSMetrics', smsMetricsSchema);
