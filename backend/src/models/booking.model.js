const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
    residence: {
        type: mongoose.Schema.ObjectId,
        ref: 'Residence',
        required: [true, 'Une résidence est requise pour la réservation']
    },
    user: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: [true, 'Un utilisateur est requis pour la réservation']
    },
    checkIn: {
        type: Date,
        required: [true, 'Une date d\'arrivée est requise']
    },
    checkOut: {
        type: Date,
        required: [true, 'Une date de départ est requise']
    },
    guests: {
        type: Number,
        required: [true, 'Le nombre de voyageurs est requis'],
        min: [1, 'Au moins un voyageur est requis']
    },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'cancelled', 'completed', 'refunded'],
        default: 'pending'
    },
    totalPrice: {
        type: Number,
        required: [true, 'Le prix total est requis']
    },
    paidAmount: {
        type: Number,
        default: 0
    },
    specialRequests: {
        type: String,
        maxlength: [500, 'Les demandes spéciales ne peuvent pas dépasser 500 caractères']
    },
    // Champs pour la gestion des annulations
    cancellationReason: {
        type: String,
        maxlength: [500, 'La raison d\'annulation ne peut pas dépasser 500 caractères']
    },
    cancelledBy: {
        type: mongoose.Schema.ObjectId,
        ref: 'User'
    },
    cancelledAt: Date,
    refundAmount: {
        type: Number,
        min: 0
    },
    // Champs pour la gestion des modifications
    modificationFee: {
        type: Number,
        min: 0,
        default: 0
    },
    modifiedAt: Date,
    previousDates: {
        checkIn: Date,
        checkOut: Date
    },
    // Champs pour le paiement
    paymentId: {
        type: mongoose.Schema.ObjectId,
        ref: 'Payment'
    },
    paymentMethod: {
        type: String,
        enum: ['card', 'bank_transfer', 'cash', 'mobile_money']
    },
    paymentStatus: {
        type: String,
        enum: ['pending', 'processing', 'completed', 'failed', 'refunded'],
        default: 'pending'
    },
    // Champs pour les avis
    review: {
        rating: {
            type: Number,
            min: 1,
            max: 5
        },
        comment: String,
        createdAt: Date
    },
    // Dates importantes
    completedAt: Date,
    // Pour les notifications et rappels
    reminders: [{
        type: {
            type: String,
            enum: ['email', 'sms', 'push'],
            required: true
        },
        scheduledFor: Date,
        sent: {
            type: Boolean,
            default: false
        },
        sentAt: Date
    }]
}, {
    timestamps: true,
    toJSON: { virtuals: true },
    toObject: { virtuals: true }
});

// Indexes
bookingSchema.index({ user: 1, createdAt: -1 });
bookingSchema.index({ residence: 1, checkIn: 1 });
bookingSchema.index({ status: 1 });

// Virtuals

// Durée en nuits
bookingSchema.virtual('nights').get(function() {
    return Math.ceil((this.checkOut - this.checkIn) / (1000 * 60 * 60 * 24));
});

// Prix par nuit
bookingSchema.virtual('pricePerNight').get(function() {
    const nights = this.nights;
    return nights > 0 ? this.totalPrice / nights : 0;
});

// Propriétés de la résidence (pour l'affichage)
bookingSchema.virtual('residenceProperties').get(function() {
    if (!this.residence) return null;
    
    return {
        imageUrl: this.residence.images?.[0] || '/placeholder.jpg',
        title: this.residence.name,
        address: this.residence.address,
        city: this.residence.location?.city || '',
        status: this.residence.isAvailable ? 'available' : 'unavailable',
        hasPool: this.residence.amenities?.includes('pool'),
        isVacationResidence: this.residence.type === 'vacation',
        isSpecialResidence: this.residence.type === 'special'
    };
});

// Infos de localisation formatées
bookingSchema.virtual('locationDisplay').get(function() {
    if (!this.residence || !this.residence.location) return '';
    
    const { address, city, country } = this.residence.location;
    return `${address}, ${city}, ${country || 'Côte d\'Ivoire'}`;
});

// MÉTHODES

// Méthode pour annuler une réservation
bookingSchema.methods.cancel = async function(userId, reason) {
    this.status = 'cancelled';
    this.cancellationReason = reason;
    this.cancelledBy = userId;
    this.cancelledAt = new Date();
    await this.save();
    return this;
};

// Méthode pour confirmer une réservation
bookingSchema.methods.confirm = async function() {
    this.status = 'confirmed';
    await this.save();
    return this;
};

// Méthode pour compléter une réservation
bookingSchema.methods.complete = async function() {
    this.status = 'completed';
    this.completedAt = new Date();
    await this.save();
    return this;
};

// Méthode pour ajouter un avis
bookingSchema.methods.addReview = async function(rating, comment) {
    this.review = {
        rating,
        comment,
        createdAt: new Date()
    };
    await this.save();
    return this;
};

// Méthode pour enregistrer un paiement
bookingSchema.methods.registerPayment = async function(paymentId, method, amount) {
    this.paymentId = paymentId;
    this.paymentMethod = method;
    this.paidAmount = amount;
    this.paymentStatus = 'completed';
    
    // Si le montant payé est égal ou supérieur au prix total, confirmer la réservation
    if (amount >= this.totalPrice) {
        this.status = 'confirmed';
    }
    
    await this.save();
    return this;
};

// Méthode pour planifier un rappel
bookingSchema.methods.scheduleReminder = async function(type, scheduledFor) {
    this.reminders.push({
        type,
        scheduledFor,
        sent: false
    });
    
    await this.save();
    return this;
};

// Méthode pour marquer un rappel comme envoyé
bookingSchema.methods.markReminderSent = async function(reminderId) {
    const reminder = this.reminders.id(reminderId);
    if (reminder) {
        reminder.sent = true;
        reminder.sentAt = new Date();
        await this.save();
    }
    return this;
};

// HOOKS

// Avant la sauvegarde, vérifier les dates
bookingSchema.pre('save', function(next) {
    if (this.checkIn && this.checkOut && this.checkIn >= this.checkOut) {
        const err = new Error('La date de départ doit être ultérieure à la date d\'arrivée');
        err.name = 'ValidationError';
        next(err);
    } else {
        next();
    }
});

const Booking = mongoose.model('Booking', bookingSchema);

module.exports = Booking;
