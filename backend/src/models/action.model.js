const mongoose = require('mongoose');

const actionSchema = new mongoose.Schema({
    type: {
        type: String,
        required: true,
        enum: ['residence_approval', 'client_verification', 'payment_confirmation', 'maintenance_request']
    },
    status: {
        type: String,
        required: true,
        enum: ['pending', 'completed', 'rejected'],
        default: 'pending'
    },
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    priority: {
        type: String,
        enum: ['low', 'medium', 'high'],
        default: 'medium'
    },
    assignedTo: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    createdBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    },
    dueDate: {
        type: Date,
        required: true
    },
    metadata: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    }
});

// Middleware pour mettre à jour updatedAt
actionSchema.pre('save', function(next) {
    this.updatedAt = new Date();
    next();
});

// Index pour optimiser les requêtes
actionSchema.index({ status: 1, dueDate: 1 });
actionSchema.index({ assignedTo: 1, status: 1 });

const Action = mongoose.model('Action', actionSchema);

module.exports = Action;
