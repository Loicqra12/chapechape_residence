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
        enum: [
            'pending',        // En attente paiement (statut métier canonique)
            'paid',           // ✅ HARMONISÉ - Paiement réussi (était 'completed')
            'failed',         // Échec du paiement
            'cancelled',      // Paiement annulé par l'utilisateur
            'refunded',       // Remboursement effectué
            'expired'         // Paiement expiré (timeout)
        ],
        default: 'pending'    // ✅ ALIGNÉ - Statut initial métier
    },
    
    // Sous-statuts techniques (provider-specific)
    providerStatus: {
        type: String,
        enum: [
            'created',        // Paiement créé mais pas encore initié
            'redirected',     // Client redirigé vers provider
            'processing',     // En cours de traitement provider
            'otp_required',   // OTP requis
            'validated'       // Validé côté provider
        ],
        default: 'created'
    },
    paymentMethod: {
        type: String,
        required: true,
        enum: ['card', 'orange_money', 'mtn_money', 'moov_money', 'wave', 'djamo', 'mobile_money', 'om', 'momo']
    },
    paymentProvider: {
        type: String,
        enum: ['stripe', 'orange', 'mtn', 'moov', 'wave', 'djamo', 'cinetpay'],
        required: true
    },
    transactionId: {
        type: String,
        sparse: true,
        unique: true,
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
    /**
     * Orchestration remboursement (P0-05).
     * Distinct de status=refunded (résultat financier final).
     */
    refundStatus: {
        type: String,
        enum: ['not_required', 'required', 'pending', 'succeeded', 'failed'],
        default: 'not_required',
        index: true,
    },
    refundAttempts: {
        type: Number,
        default: 0,
        min: 0,
    },
    refundLastError: {
        type: String,
    },
    refundProviderRef: {
        type: String,
    },
    refundOpsRequired: {
        type: Boolean,
        default: false,
        index: true,
    },
    refundLastAttemptAt: {
        type: Date,
    },
    refundOpsConfirmedAt: {
        type: Date,
    },
    refundOpsConfirmedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
    },
    refundOpsNote: {
        type: String,
    },
    refundOpsExternalRef: {
        type: String,
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
// transactionId : unique sparse via le champ schema (évite doublon d'index)

module.exports = mongoose.model('Payment', paymentSchema);
