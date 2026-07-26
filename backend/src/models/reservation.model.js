const mongoose = require('mongoose');

const reservationSchema = new mongoose.Schema({
    residence: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Residence',
        required: true
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    partner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User', // Partner = User.role partner (pas le discriminator __t)
        required: true
    },
    checkIn: {
        type: Date,
        required: true
    },
    checkOut: {
        type: Date,
        required: true
    },
    // ✅ AJOUT : Champs pour check-in/out réels
    actualCheckIn: {
        type: Date,
        default: null
    },
    actualCheckOut: {
        type: Date,
        default: null
    },
    // ✅ PHASE 0 : Snapshot du mode de réservation (lecture seule après création)
    reservationModeSnapshot: {
        type: String,
        enum: ['instant', 'approval_required'],
        required: true,
        immutable: true // Empêche la modification après création
    },
    // ✅ PHASE 0 : Snapshot des TTLs au moment de la création (lecture seule)
    ttlSnapshot: {
        paymentTTLMinutes: {
            type: Number,
            required: true,
            immutable: true
        },
        hostAcceptTTLMinutes: {
            type: Number,
            immutable: true // Requis uniquement si approval_required
        }
    },
    numberOfGuests: {
        type: Number,
        required: true,
        min: 1
    },
    totalPrice: {
        type: Number,
        required: true
    },
    // ✅ INTÉGRATION TARIFICATION DYNAMIQUE : Prix de base avant frais service
    basePrice: {
        type: Number
        // Optionnel pour compatibilité avec réservations existantes
    },
    // ✅ INTÉGRATION TARIFICATION DYNAMIQUE : Méthodes de paiement
    paymentMethod: {
        type: String,
        enum: ['mtn_money', 'orange_money', 'wave', 'moov_money', 'card'],
        default: 'mtn_money' // Méthode optimisée par défaut
    },
    payoutMethod: {
        type: String,
        enum: ['mtn_money', 'orange_money', 'wave', 'moov_money', 'card'],
        default: 'mtn_money' // Méthode optimisée par défaut
    },
    // ✅ AJOUT : Support pour la réservation flexible
    bookingType: {
        type: String,
        enum: ['hour', 'day', 'week', 'month'],
        default: 'day'
    },
    duration: {
        hours: { type: Number, default: 0 },
        days: { type: Number, default: 0 },
        weeks: { type: Number, default: 0 },
        months: { type: Number, default: 0 }
    },
    pricingDetails: {
        rateType: String,              // 'oneHour', 'halfDay', etc.
        rateValue: Number,             // Valeur du tarif utilisé
        calculationMethod: String,     // 'hourly', 'daily', etc.
        basePeriod: String,           // Période de base du tarif
        multiplier: Number,           // Multiplicateur appliqué
        breakdown: {                  // Détail du calcul
            baseRate: Number,
            additionalCharges: Number,
            discounts: Number,
            finalAmount: Number
        }
    },
    // ✅ NOUVEAU : Tarification dynamique optimisée CinetPay (OPTIONNEL pour compatibilité)
    dynamicPricing: {
        basePrice: {
            type: Number
            // ✅ CORRECTION: Pas required pour compatibilité réservations existantes
        },
        paymentMethod: {
            type: String,
            enum: ['mtn_money', 'orange_money', 'wave', 'moov_money', 'card']
            // ✅ CORRECTION: Pas required pour compatibilité réservations existantes
        },
        payoutMethod: {
            type: String,
            enum: ['mtn_money', 'orange_money', 'wave', 'moov_money', 'card'],
            default: 'mtn_money' // Optimal par défaut
        },
        serviceAmount: {
            type: Number
            // ✅ CORRECTION: Pas required pour compatibilité réservations existantes
        },
        totalClientPrice: {
            type: Number
            // ✅ CORRECTION: Pas required pour compatibilité réservations existantes
        },
        partnerNetAmount: {
            type: Number
            // ✅ CORRECTION: Pas required pour compatibilité réservations existantes
        },
        chapeChapeRevenue: {
            type: Number
            // ✅ CORRECTION: Pas required pour compatibilité réservations existantes
        },
        fees: {
            cinetpayPayinFee: Number,
            cinetpayPayoutFee: Number,
            totalFees: Number,
            partnerCommissionAmount: Number
        },
        optimization: {
            serviceFeeRate: Number,
            savingsVsExpensive: Number,
            isOptimized: Boolean,
            chapeChapeMarginRate: Number,
            totalFeesRate: Number
        },
        calculatedAt: {
            type: Date,
            default: Date.now
        }
    },
    status: {
        type: String,
        enum: [
            'pending',           // État initial (compatible)
            'awaiting_approval', // Nouveau: Mode "demande à valider" 
            'payment_pending',   // Nouveau: En attente paiement avec timer
            'confirmed',         // Réservation confirmée (compatible)
            'in_stay',           // ✅ PHASE 1: Séjour en cours après check-in
            'expired',           // Nouveau: Délai paiement expiré
            'cancelled',         // Annulée (compatible)
            'completed',         // Séjour terminé (compatible)
            'refunded'           // Remboursée (compatible)
        ],
        default: 'pending'
    },
    paymentStatus: {
        type: String,
        enum: [
            'pending',           // En attente paiement (statut métier canonique)
            'paid',              // Payé (statut métier canonique)
            'failed',            // Échec paiement (statut métier canonique)
            'refunded'           // Remboursé (statut métier canonique)
            // ✅ NETTOYÉ: 'processing', 'expired', 'partial' → statuts techniques/réservation
        ],
        default: 'pending'
    },
    messagingEnabled: {
        type: Boolean,
        default: false
    },
    specialRequests: {
        type: String
    },
    // Notes internes partenaire (affichées côté Partner app)
    notes: {
        type: String,
        maxlength: 5000,
        default: ''
    },
    cancellationPolicy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'CancellationPolicy',
        required: true
    },
    cancellationDetails: {
        cancelledAt: Date,
        cancelledBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        reason: String,
        // true si rejet partenaire (status backend reste 'cancelled')
        rejectedByHost: {
            type: Boolean,
            default: false
        },
        refundAmount: Number,
        refundStatus: {
            type: String,
            enum: ['pending', 'processing', 'completed', 'failed'],
            default: 'pending'
        }
    },
    modifications: [{
        modifiedAt: {
            type: Date,
            default: Date.now
        },
        modifiedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User',
            required: true
        },
        changes: {
            type: Map,
            of: mongoose.Schema.Types.Mixed
        },
        fee: {
            type: Number,
            default: 0
        },
        status: {
            type: String,
            enum: ['pending', 'approved', 'rejected'],
            default: 'pending'
        }
    }],
    
    // ✅ NOUVEAUX CHAMPS - Système de Paiement Avancé
    reservationMode: {
        type: String,
        enum: ['instant', 'approval_required'],
        default: 'instant'
    },
    
    // Timer de paiement
    paymentDeadline: {
        type: Date,
        index: true // Pour les requêtes d'expiration
    },
    paymentTimerDuration: {
        type: Number,
        default: 30 // minutes par défaut
    },
    
    // QR Code pour check-in/check-out
    qrCode: {
        checkInCode: String,
        checkOutCode: String,
        generatedAt: Date
    },
    
    // Notifications envoyées
    notificationsSent: [{
        type: {
            type: String,
            enum: ['payment_reminder', 'payment_deadline', 'confirmation', 'check_in_reminder']
        },
        sentAt: {
            type: Date,
            default: Date.now
        },
        channel: {
            type: String,
            enum: ['sms', 'push', 'email']
        },
        status: {
            type: String,
            enum: ['sent', 'delivered', 'failed']
        }
    }],
    
    // Historique des changements de statut
    statusHistory: [{
        status: String,
        paymentStatus: String,
        changedAt: {
            type: Date,
            default: Date.now
        },
        changedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        },
        reason: String
    }]
}, {
    timestamps: true
});

reservationSchema.pre('save', function(next) {
    if (this.checkOut <= this.checkIn) {
        return next(new Error('La date de départ doit être après la date d\'arrivée'));
    }
    next();
});

reservationSchema.methods.getDurationInDays = function() {
    return Math.ceil((this.checkOut - this.checkIn) / (1000 * 60 * 60 * 24));
};

reservationSchema.methods.canBeCancelled = async function() {
    if (!this.populated('cancellationPolicy') && this.cancellationPolicy) {
        await this.populate('cancellationPolicy');
    }
    const policy = this.cancellationPolicy;
    const now = new Date();
    const hoursBeforeCheckIn = (this.checkIn - now) / (1000 * 60 * 60);
    
    if (['cancelled', 'completed', 'refunded'].includes(this.status)) {
        return false;
    }
    
    if (!policy || !policy.rules || !Array.isArray(policy.rules)) {
        return true;
    }
    
    return policy.rules.some(rule => rule.timeBeforeCheckIn <= hoursBeforeCheckIn);
};

reservationSchema.methods.canBeModified = async function() {
    if (!this.populated('cancellationPolicy') && this.cancellationPolicy) {
        await this.populate('cancellationPolicy');
    }
    const policy = this.cancellationPolicy;
    const now = new Date();
    const hoursBeforeCheckIn = (this.checkIn - now) / (1000 * 60 * 60);
    
    if (['cancelled', 'completed', 'refunded'].includes(this.status)) {
        return false;
    }
    
    if (!policy || typeof policy.isModificationAllowed !== 'function') {
        return true;
    }
    
    return policy.isModificationAllowed(hoursBeforeCheckIn);
};

// ✅ PHASE 1 : Règle dure - jamais confirmed si paymentStatus ≠ paid
reservationSchema.pre('save', function(next) {
    // Validation critique : statut confirmed require paymentStatus = paid
    if (this.status === 'confirmed' && this.paymentStatus !== 'paid') {
        const error = new Error('Règle métier violée : une réservation ne peut être confirmée sans paiement complet (paymentStatus = paid requis)');
        error.name = 'ValidationError';
        return next(error);
    }
    
    // Validation : statut in_stay require paymentStatus = paid
    if (this.status === 'in_stay' && this.paymentStatus !== 'paid') {
        const error = new Error('Règle métier violée : un séjour ne peut débuter sans paiement complet (paymentStatus = paid requis)');
        error.name = 'ValidationError';
        return next(error);
    }
    
    next();
});

// ✅ Garde métier : confirmed / in_stay exigent paymentStatus=paid
// Couvre findOneAndUpdate ET updateOne ; lit status dans $set (pas seulement update.status)
function enforcePaidOnStatusUpdate(next) {
    this.setOptions({ runValidators: true, context: 'query' });

    const update = this.getUpdate() || {};
    const filter = this.getFilter() || {};
    const newStatus = update.status ?? update.$set?.status;
    const newPaymentStatus = update.paymentStatus ?? update.$set?.paymentStatus;

    if (newStatus === 'confirmed' || newStatus === 'in_stay') {
        const setsPaidInSameUpdate = newPaymentStatus === 'paid';
        const filterRequiresPaid = filter.paymentStatus === 'paid';

        if (!setsPaidInSameUpdate && !filterRequiresPaid) {
            const error = new Error(
                `Transition vers ${newStatus} requiert paymentStatus='paid' (dans $set ou dans le filtre)`
            );
            error.name = 'ValidationError';
            return next(error);
        }
    }

    next();
}

reservationSchema.pre('findOneAndUpdate', enforcePaidOnStatusUpdate);
reservationSchema.pre('updateOne', enforcePaidOnStatusUpdate);

module.exports = mongoose.model('Reservation', reservationSchema);
