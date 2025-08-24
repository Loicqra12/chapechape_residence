const mongoose = require('mongoose');

/**
 * Modèle Payout - Reversement aux Partners via CinetPay
 * Gère les transferts d'argent automatisés aux partenaires
 */
const payoutSchema = new mongoose.Schema({
    // Identifiants uniques
    payout_id: {
        type: String,
        required: true,
        unique: true,
        index: true
    },
    
    // Bénéficiaire du payout
    partner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Partner',
        required: true,
        index: true
    },
    
    // Transactions source du payout
    source_transactions: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Payment',
        required: true
    }],
    
    // Montants
    gross_amount: {
        type: Number,
        required: true,
        min: [0, 'Le montant brut ne peut pas être négatif']
    },
    commission_amount: {
        type: Number,
        required: true,
        min: [0, 'La commission ne peut pas être négative']
    },
    commission_rate: {
        type: Number,
        required: true,
        min: [0, 'Le taux de commission doit être positif'],
        max: [1, 'Le taux de commission ne peut pas dépasser 100%']
    },
    net_amount: {
        type: Number,
        required: true,
        min: [5, 'Le montant net minimum est de 5 XOF'] // Contrainte CinetPay
    },
    fees: {
        type: Number,
        default: 0,
        min: [0, 'Les frais ne peuvent pas être négatifs']
    },
    currency: {
        type: String,
        default: 'XOF',
        enum: ['XOF', 'EUR', 'USD']
    },
    
    // Informations de transfert
    channel: {
        type: String,
        required: true,
        enum: [
            'orange_money',     // Orange Money
            'mtn_money',        // MTN Money  
            'moov_money',       // Moov Money
            'wave',             // Wave (WAVECI/WAVESN)
            'bank_transfer',    // Virement bancaire
            'manual'            // Payout manuel
        ]
    },
    
    // Destinataire
    recipient_info: {
        phone_prefix: {
            type: String,
            required: function() { return this.channel !== 'bank_transfer'; }
        },
        phone_number: {
            type: String,
            required: function() { return this.channel !== 'bank_transfer'; },
            validate: {
                validator: function(v) {
                    return this.channel === 'bank_transfer' || /^[0-9]{8,10}$/.test(v);
                },
                message: 'Numéro de téléphone invalide (8-10 chiffres)'
            }
        },
        full_name: {
            type: String,
            required: true,
            trim: true
        },
        email: {
            type: String,
            required: function() { return this.channel !== 'manual'; },
            validate: {
                validator: function(v) {
                    return this.channel === 'manual' || /\S+@\S+\.\S+/.test(v);
                },
                message: 'Email invalide'
            }
        }
    },
    
    // Statut du payout
    status: {
        type: String,
        enum: [
            'scheduled',        // Programmé
            'pending',          // En attente de traitement
            'processing',       // En cours de traitement
            'completed',        // Terminé avec succès
            'failed',           // Échec du transfert
            'cancelled',        // Annulé manuellement
            'expired'           // Expiré (non traité dans les délais)
        ],
        default: 'scheduled',
        required: true,
        index: true
    },
    
    // Type de déclenchement du payout
    trigger_type: {
        type: String,
        enum: ['manual', 'automatic', 'scheduled'],
        default: 'manual',
        required: true
    },
    
    // Informations CinetPay
    provider: {
        type: String,
        default: 'cinetpay',
        enum: ['cinetpay', 'manual', 'direct_api']
    },
    cinetpay_info: {
        transaction_id: {
            type: String
            // Pas d'index automatique - index explicite défini plus bas
        },
        client_transaction_id: {
            type: String,
            unique: true,
            sparse: true
        },
        lot_id: String,
        treatment_status: {
            type: String,
            enum: ['NEW', 'PENDING', 'VAL', 'REJECT', 'CONFIRM'],
            default: 'NEW'
        },
        sending_status: {
            type: String,
            enum: ['PENDING', 'CONFIRM'],
            default: 'PENDING'
        },
        payment_method: {
            type: String,
            enum: ['WAVECI', 'WAVESN', 'OM', 'MTN', 'MOOV']
        }
    },
    
    // Scheduling & Retry
    scheduled_for: {
        type: Date,
        required: true,
        index: true
    },
    executed_at: Date,
    attempts: {
        type: Number,
        default: 0,
        max: [5, 'Maximum 5 tentatives autorisées']
    },
    next_retry_at: Date,
    
    // Gestion d'erreurs
    failure_reason: String,
    last_error: {
        code: String,
        message: String,
        timestamp: {
            type: Date,
            default: Date.now
        }
    },
    
    // Notifications
    notifications_sent: [{
        type: {
            type: String,
            enum: ['email', 'sms', 'push', 'webhook']
        },
        status: {
            type: String,
            enum: ['sent', 'failed', 'delivered']
        },
        sent_at: {
            type: Date,
            default: Date.now
        },
        details: String
    }],
    
    // URLs de callback
    notify_url: String,
    
    // Métadonnées
    metadata: {
        type: Map,
        of: String
    },
    
    // Audit trail
    history: [{
        status_from: String,
        status_to: String,
        timestamp: {
            type: Date,
            default: Date.now
        },
        reason: String,
        user_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: 'User'
        }
    }]
}, {
    timestamps: true
});

// ===============================
// INDEXES POUR PERFORMANCE
// ===============================
payoutSchema.index({ partner: 1, status: 1 });
payoutSchema.index({ scheduled_for: 1, status: 1 });
payoutSchema.index({ 'cinetpay_info.transaction_id': 1 }); // Index nécessaire (pas unique)
// cinetpay_info.client_transaction_id index créé automatiquement par unique: true
payoutSchema.index({ createdAt: -1 });

// ===============================
// MÉTHODES D'INSTANCE
// ===============================

/**
 * Générer un ID de transaction client unique
 */
payoutSchema.methods.generateClientTransactionId = function() {
    const timestamp = Date.now().toString();
    const random = Math.floor(Math.random() * 10000).toString().padStart(4, '0');
    return `PAYOUT${this.partner.toString().slice(-6)}${timestamp}${random}`;
};

/**
 * Valider le montant selon les contraintes CinetPay
 */
payoutSchema.methods.validateAmount = function() {
    // Montant minimum 5 XOF
    if (this.net_amount < 5) {
        return { valid: false, error: 'Montant minimum: 5 XOF' };
    }
    
    // Montant multiple de 5 (sauf USD)
    if (this.currency === 'XOF' && this.net_amount % 5 !== 0) {
        return { valid: false, error: 'Le montant doit être un multiple de 5 XOF' };
    }
    
    return { valid: true };
};

/**
 * Marquer comme réussi
 */
payoutSchema.methods.markAsSuccess = function(cinetPayResponse) {
    this.status = 'PAYOUT_SUCCESS';
    this.executed_at = new Date();
    this.cinetpay_info.treatment_status = 'VAL';
    this.cinetpay_info.sending_status = 'CONFIRM';
    
    if (cinetPayResponse) {
        this.cinetpay_info.transaction_id = cinetPayResponse.transaction_id;
        this.cinetpay_info.lot_id = cinetPayResponse.lot;
    }
    
    this.addHistoryEntry('PAYOUT_SUCCESS', 'Transfert réussi');
};

/**
 * Marquer comme échoué
 */
payoutSchema.methods.markAsFailed = function(reason, errorCode = null) {
    this.status = 'PAYOUT_FAILED';
    this.failure_reason = reason;
    this.attempts += 1;
    
    if (errorCode) {
        this.last_error = {
            code: errorCode,
            message: reason,
            timestamp: new Date()
        };
    }
    
    this.addHistoryEntry('PAYOUT_FAILED', reason);
};

/**
 * Programmer le prochain retry
 */
payoutSchema.methods.scheduleRetry = function(delayMinutes = 30) {
    if (this.attempts >= 5) {
        this.markAsFailed('Maximum de tentatives atteint');
        return false;
    }
    
    this.status = 'PAYOUT_SCHEDULED';
    this.next_retry_at = new Date(Date.now() + delayMinutes * 60 * 1000);
    this.addHistoryEntry('PAYOUT_SCHEDULED', `Retry programmé dans ${delayMinutes}min`);
    return true;
};

/**
 * Ajouter une entrée à l'historique
 */
payoutSchema.methods.addHistoryEntry = function(newStatus, reason = '', userId = null) {
    this.history.push({
        status_from: this.status,
        status_to: newStatus,
        reason: reason,
        user_id: userId,
        timestamp: new Date()
    });
};

// ===============================
// MÉTHODES STATIQUES
// ===============================

/**
 * Trouver les payouts à exécuter
 */
payoutSchema.statics.findReadyForExecution = function() {
    return this.find({
        status: 'PAYOUT_SCHEDULED',
        scheduled_for: { $lte: new Date() },
        attempts: { $lt: 5 }
    }).populate('partner source_transactions');
};

/**
 * Calculer les stats de payout pour un partner
 */
payoutSchema.statics.getPartnerStats = function(partnerId, startDate, endDate) {
    return this.aggregate([
        {
            $match: {
                partner: partnerId,
                createdAt: {
                    $gte: startDate || new Date(0),
                    $lte: endDate || new Date()
                }
            }
        },
        {
            $group: {
                _id: '$status',
                count: { $sum: 1 },
                total_amount: { $sum: '$net_amount' }
            }
        }
    ]);
};

// ===============================
// HOOKS
// ===============================

/**
 * Avant sauvegarde - Validation et calculs
 */
payoutSchema.pre('save', function(next) {
    // Générer payout_id si nouveau
    if (this.isNew && !this.payout_id) {
        this.payout_id = `PAYOUT_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    }
    
    // Générer client_transaction_id si nouveau
    if (this.isNew && !this.cinetpay_info.client_transaction_id) {
        this.cinetpay_info.client_transaction_id = this.generateClientTransactionId();
    }
    
    // Calcul du montant net si pas défini
    if (this.isModified(['gross_amount', 'commission_amount']) && !this.isModified('net_amount')) {
        this.net_amount = Math.floor((this.gross_amount - this.commission_amount - this.fees) / 5) * 5; // Arrondir à 5
    }
    
    // Validation montant
    const validation = this.validateAmount();
    if (!validation.valid) {
        return next(new Error(validation.error));
    }
    
    next();
});

/**
 * Après sauvegarde - Logging
 */
payoutSchema.post('save', function(doc) {
    console.log(`Payout ${doc.payout_id} sauvegardé avec statut ${doc.status}`);
});

module.exports = mongoose.model('Payout', payoutSchema);
