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
    }
}, {
    timestamps: true
});

// Middleware pour vérifier que checkOut est après checkIn
reservationSchema.pre('save', function(next) {
    if (this.checkOut <= this.checkIn) {
        next(new Error('La date de départ doit être après la date d\'arrivée'));
    }
    next();
});

module.exports = mongoose.model('Reservation', reservationSchema);
