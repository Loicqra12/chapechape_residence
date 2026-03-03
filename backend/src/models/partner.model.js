const mongoose = require('mongoose');
const User = require('./user.model');

const partnerSchema = new mongoose.Schema({
    company: {
        name: {
            type: String,
            required: [true, 'Nom de l\'entreprise est obligatoire']
        },
        registrationNumber: {
            type: String,
            required: [true, 'Numéro d\'enregistrement est obligatoire']
        },
        address: {
            street: String,
            city: String,
            postalCode: String,
            country: String
        }
    },
    partnerType: {
        type: String,
        enum: ['owner', 'agent'],
        required: true
    },
    verificationStatus: {
        type: String,
        enum: ['pending', 'verified', 'rejected'],
        default: 'pending'
    },
    documents: [{
        type: {
            type: String,
            enum: ['identity', 'address', 'professional', 'business', 'other'],
            required: true
        },
        url: {
            type: String,
            required: true
        },
        verified: {
            type: Boolean,
            default: false
        },
        uploadedAt: {
            type: Date,
            default: Date.now
        }
    }],
    specializations: [{
        type: String,
        enum: ['residential', 'commercial', 'luxury', 'rental']
    }],
    rating: {
        average: {
            type: Number,
            default: 0,
            min: 0,
            max: 5
        },
        count: {
            type: Number,
            default: 0
        }
    },
    subscription: {
        plan: {
            type: String,
            enum: ['free', 'premium', 'enterprise'],
            default: 'free'
        },
        startDate: Date,
        endDate: Date,
        status: {
            type: String,
            enum: ['active', 'expired', 'cancelled'],
            default: 'active'
        }
    },
    bankInfo: {
        accountHolder: String,
        bankName: String,
        accountNumber: String,
        iban: String,
        swift: String
    }
}, {
    timestamps: true
});

// Indexes
partnerSchema.index({ 'company.name': 1 });
partnerSchema.index({ partnerType: 1 });
partnerSchema.index({ verificationStatus: 1 });
partnerSchema.index({ 'rating.average': -1 });

const Partner = User.discriminator('Partner', partnerSchema);

module.exports = Partner;
