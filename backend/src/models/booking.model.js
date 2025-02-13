const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
    residence: {
        type: mongoose.Schema.ObjectId,
        ref: 'Residence',
        required: [true, 'Une résidence est requise pour la réservation']
    },
    client: {
        type: mongoose.Schema.ObjectId,
        ref: 'User',
        required: [true, 'Un client est requis pour la réservation']
    },
    partner: {
        type: mongoose.Schema.ObjectId,
        ref: 'Partner',
        required: [true, 'Un partenaire est requis pour la réservation']
    },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'cancelled', 'completed'],
        default: 'pending'
    },
    visitDate: {
        type: Date,
        required: [true, 'Une date de visite est requise']
    },
    visitTime: {
        type: String,
        required: [true, 'Une heure de visite est requise']
    },
    notes: {
        type: String,
        maxlength: [500, 'Les notes ne peuvent pas dépasser 500 caractères']
    },
    cancellationReason: {
        type: String,
        maxlength: [500, 'La raison d\'annulation ne peut pas dépasser 500 caractères']
    },
    cancelledBy: {
        type: mongoose.Schema.ObjectId,
        ref: 'User'
    },
    cancelledAt: Date,
    feedback: {
        rating: {
            type: Number,
            min: 1,
            max: 5
        },
        comment: String,
        createdAt: Date
    },
    reminders: [{
        type: {
            type: String,
            enum: ['email', 'sms'],
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
    timestamps: true
});

// Indexes
bookingSchema.index({ residence: 1, visitDate: 1 });
bookingSchema.index({ client: 1, status: 1 });
bookingSchema.index({ partner: 1, status: 1 });
bookingSchema.index({ visitDate: 1 });

// Middleware pour vérifier les chevauchements de réservations
bookingSchema.pre('save', async function(next) {
    if (this.isModified('visitDate') || this.isModified('visitTime')) {
        const existingBooking = await this.constructor.findOne({
            residence: this.residence,
            visitDate: this.visitDate,
            visitTime: this.visitTime,
            status: { $in: ['pending', 'confirmed'] },
            _id: { $ne: this._id }
        });

        if (existingBooking) {
            throw new Error('Cette plage horaire est déjà réservée');
        }
    }
    next();
});

// Méthode pour annuler une réservation
bookingSchema.methods.cancel = async function(userId, reason) {
    this.status = 'cancelled';
    this.cancellationReason = reason;
    this.cancelledBy = userId;
    this.cancelledAt = Date.now();
    await this.save();
};

// Méthode pour confirmer une réservation
bookingSchema.methods.confirm = async function() {
    this.status = 'confirmed';
    await this.save();
};

// Méthode pour compléter une réservation
bookingSchema.methods.complete = async function(rating, comment) {
    this.status = 'completed';
    if (rating) {
        this.feedback = {
            rating,
            comment,
            createdAt: Date.now()
        };
    }
    await this.save();
};

const Booking = mongoose.model('Booking', bookingSchema);

module.exports = Booking;
