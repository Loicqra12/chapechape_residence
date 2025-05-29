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
        ref: 'Partner',
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
    numberOfGuests: {
        type: Number,
        required: true,
        min: 1
    },
    totalPrice: {
        type: Number,
        required: true
    },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'cancelled', 'completed', 'refunded'],
        default: 'pending'
    },
    paymentStatus: {
        type: String,
        enum: ['pending', 'paid', 'failed', 'refunded'],
        default: 'pending'
    },
    messagingEnabled: {
        type: Boolean,
        default: false
    },
    specialRequests: {
        type: String
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
    }]
}, {
    timestamps: true
});

reservationSchema.pre('save', function(next) {
    if (this.checkOut <= this.checkIn) {
        next(new Error('La date de départ doit être après la date d\'arrivée'));
    }
    next();
});

reservationSchema.methods.getDurationInDays = function() {
    return Math.ceil((this.checkOut - this.checkIn) / (1000 * 60 * 60 * 24));
};

reservationSchema.methods.canBeCancelled = async function() {
    const policy = await this.populate('cancellationPolicy');
    const now = new Date();
    const hoursBeforeCheckIn = (this.checkIn - now) / (1000 * 60 * 60);
    
    if (['cancelled', 'completed', 'refunded'].includes(this.status)) {
        return false;
    }
    
    // Vérifier que policy et policy.rules sont définis avant d'utiliser .some()
    if (!policy || !policy.rules || !Array.isArray(policy.rules)) {
        // Si pas de règles définies, par défaut permettre l'annulation
        return true;
    }
    
    return policy.rules.some(rule => rule.timeBeforeCheckIn <= hoursBeforeCheckIn);
};

reservationSchema.methods.canBeModified = async function() {
    const policy = await this.populate('cancellationPolicy');
    const now = new Date();
    const hoursBeforeCheckIn = (this.checkIn - now) / (1000 * 60 * 60);
    
    if (['cancelled', 'completed', 'refunded'].includes(this.status)) {
        return false;
    }
    
    // Vérifier que policy et policy.rules sont définis avant d'utiliser .some()
    if (!policy || !policy.rules || !Array.isArray(policy.rules)) {
        // Si pas de règles définies, par défaut permettre la modification
        return true;
    }
    
    return policy.isModificationAllowed(hoursBeforeCheckIn);
};

module.exports = mongoose.model('Reservation', reservationSchema);
