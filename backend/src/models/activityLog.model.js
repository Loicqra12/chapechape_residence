const mongoose = require('mongoose');

const activityLogSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    action: {
        type: String,
        required: true,
        enum: [
            'login', 'logout', 'login_failed', 'password_change', 'email_change',
            'phone_change', 'profile_update', 'bank_account_change', 'payout_initiated',
            'payout_completed', 'payout_failed', 'residence_created', 'residence_updated',
            'residence_deleted', 'reservation_created', 'reservation_updated', 'reservation_cancelled',
            'payment_initiated', 'payment_completed', 'payment_failed', 'verification_sent',
            'verification_success', 'verification_failed', 'suspicious_activity', 'security_alert',
            'ops_checkin', 'ops_checkout', 'ops_cancel', 'ops_refund_confirm'
        ]
    },
    module: {
        type: String,
        required: true,
        enum: ['auth', 'profile', 'payment', 'residence', 'reservation', 'security', 'verification', 'ops']
    },
    description: {
        type: String,
        required: true
    },
    ipAddress: {
        type: String,
        required: true
    },
    userAgent: {
        type: String
    },
    location: {
        country: String,
        city: String,
        region: String
    },
    device: {
        type: { type: String, enum: ['mobile', 'desktop', 'tablet', 'unknown'], default: 'desktop' },
        os: { type: String, default: 'unknown' },
        browser: { type: String, default: 'unknown' }
    },
    metadata: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    status: {
        type: String,
        enum: ['success', 'failure', 'warning', 'suspicious'],
        default: 'success'
    },
    severity: {
        type: String,
        enum: ['low', 'medium', 'high', 'critical'],
        default: 'low'
    },
    responseTime: {
        type: Number,
        default: 0
    },
    riskScore: {
        type: Number,
        min: 0,
        max: 100,
        default: 0
    },
    isSuspicious: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Index pour améliorer les performances des requêtes
activityLogSchema.index({ createdAt: -1 });
activityLogSchema.index({ user: 1, createdAt: -1 });
activityLogSchema.index({ action: 1, module: 1 });

module.exports = mongoose.model('ActivityLog', activityLogSchema);
