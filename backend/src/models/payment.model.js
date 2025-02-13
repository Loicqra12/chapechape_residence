const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
    reservation: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reservation',
        required: true
    },
    amount: {
        type: Number,
        required: true
    },
    currency: {
        type: String,
        default: 'XOF'
    },
    status: {
        type: String,
        enum: ['pending', 'processing', 'completed', 'failed', 'refunded'],
        default: 'pending'
    },
    paymentMethod: {
        type: String,
        required: true,
        enum: ['card', 'orange_money', 'mtn_money', 'moov_money', 'wave', 'djamo']
    },
    paymentProvider: {
        type: String,
        enum: ['stripe', 'orange', 'mtn', 'moov', 'wave', 'djamo'],
        required: true
    },
    transactionId: {
        type: String
    },
    phoneNumber: {
        type: String,
        // Requis pour les paiements mobile money
        validate: {
            validator: function(v) {
                return this.paymentMethod !== 'card' ? /^[0-9]{10}$/.test(v) : true;
            },
            message: 'Numéro de téléphone invalide'
        }
    },
    refundAmount: {
        type: Number
    },
    refundReason: {
        type: String
    },
    metadata: {
        type: Map,
        of: String
    },
    paymentDetails: {
        // Pour stocker les détails spécifiques à chaque méthode de paiement
        otp: String,
        reference: String,
        providerResponse: Object
    }
}, {
    timestamps: true
});

// Index pour améliorer les performances des requêtes
paymentSchema.index({ reservation: 1 });
paymentSchema.index({ status: 1 });
paymentSchema.index({ createdAt: -1 });
paymentSchema.index({ phoneNumber: 1 });
paymentSchema.index({ transactionId: 1 });

module.exports = mongoose.model('Payment', paymentSchema);
