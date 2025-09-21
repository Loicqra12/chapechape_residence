const mongoose = require('mongoose');
const { NOTIFICATION_TYPES } = require('../utils/constants');
const { COMMON, PARTNER, CLIENT } = require('../utils/notification-types');

// Build a comprehensive enum list combining legacy constants and new granular types
const ALLOWED_NOTIFICATION_TYPES = [
  ...Object.values(NOTIFICATION_TYPES),
  ...Object.values(COMMON),
  ...Object.values(PARTNER),
  ...Object.values(CLIENT),
];

const notificationSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    type: {
        type: String,
        enum: ALLOWED_NOTIFICATION_TYPES,
        required: true
    },
    message: {
        type: String,
        required: true
    },
    data: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    read: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Index pour améliorer les performances des requêtes
notificationSchema.index({ user: 1, createdAt: -1 });
notificationSchema.index({ user: 1, read: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
