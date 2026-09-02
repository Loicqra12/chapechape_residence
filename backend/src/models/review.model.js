const mongoose = require('mongoose');

const reviewSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    residence: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Residence',
        required: true
    },
    reservation: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Reservation',
        required: false
    },
    rating: {
        overall: { type: Number, required: true, min: 0, max: 5 },
        cleanliness: { type: Number, min: 0, max: 5, default: 0 },
        comfort: { type: Number, min: 0, max: 5, default: 0 },
        facilities: { type: Number, min: 0, max: 5, default: 0 },
        value: { type: Number, min: 0, max: 5, default: 0 },
        location: { type: Number, min: 0, max: 5, default: 0 }
    },
    comment: {
        type: String,
        required: true,
        minlength: 1,
        maxlength: 1000
    },
    photos: [{
        type: String,
        validate: {
            validator: function(v) {
                // Validation basique d'URL
                return /^https?:\/\/.+/.test(v);
            },
            message: 'URL de photo invalide'
        }
    }],
    ownerResponse: {
        comment: {
            type: String,
            maxlength: 1000
        },
        createdAt: {
            type: Date,
            default: null
        }
    }
}, {
    timestamps: true
});

// Index pour améliorer les performances des requêtes
reviewSchema.index({ residence: 1, createdAt: -1 });
reviewSchema.index({ user: 1, residence: 1 }, { unique: true });
reviewSchema.index({ reservation: 1 }, { unique: true, sparse: true });

// Middleware pour vérifier que l'utilisateur a bien séjourné dans la résidence (optionnel)
reviewSchema.pre('save', async function(next) {
    if (this.isNew && this.reservation) {
        const Reservation = mongoose.model('Reservation');
        const reservation = await Reservation.findOne({
            _id: this.reservation,
            user: this.user,
            residence: this.residence,
            status: { $in: ['completed', 'confirmed', 'refunded'] }
        });

        if (!reservation) {
            return next(new Error('Réservation invalide pour cette résidence'));
        }
    }
    next();
});

// Méthode statique pour calculer la moyenne des notes d'une résidence
reviewSchema.statics.getResidenceStats = async function(residenceId) {
    const stats = await this.aggregate([
        { $match: { residence: new mongoose.Types.ObjectId(residenceId) } },
        { 
            $group: {
                _id: '$residence',
                averageOverallRating: { $avg: '$rating.overall' },
                averageCleanlinessRating: { $avg: '$rating.cleanliness' },
                averageComfortRating: { $avg: '$rating.comfort' },
                averageFacilitiesRating: { $avg: '$rating.facilities' },
                averageValueRating: { $avg: '$rating.value' },
                averageLocationRating: { $avg: '$rating.location' },
                numberOfReviews: { $sum: 1 },
                ratings: {
                    $push: '$rating'
                }
            }
        },
        {
            $addFields: {
                ratingDistribution: {
                    overall: {
                        5: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.overall', 5] } } } },
                        4: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.overall', 4] } } } },
                        3: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.overall', 3] } } } },
                        2: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.overall', 2] } } } },
                        1: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.overall', 1] } } } }
                    },
                    cleanliness: {
                        5: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.cleanliness', 5] } } } },
                        4: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.cleanliness', 4] } } } },
                        3: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.cleanliness', 3] } } } },
                        2: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.cleanliness', 2] } } } },
                        1: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.cleanliness', 1] } } } }
                    },
                    comfort: {
                        5: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.comfort', 5] } } } },
                        4: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.comfort', 4] } } } },
                        3: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.comfort', 3] } } } },
                        2: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.comfort', 2] } } } },
                        1: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.comfort', 1] } } } }
                    },
                    facilities: {
                        5: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.facilities', 5] } } } },
                        4: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.facilities', 4] } } } },
                        3: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.facilities', 3] } } } },
                        2: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.facilities', 2] } } } },
                        1: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.facilities', 1] } } } }
                    },
                    value: {
                        5: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.value', 5] } } } },
                        4: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.value', 4] } } } },
                        3: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.value', 3] } } } },
                        2: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.value', 2] } } } },
                        1: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.value', 1] } } } }
                    },
                    location: {
                        5: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.location', 5] } } } },
                        4: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.location', 4] } } } },
                        3: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.location', 3] } } } },
                        2: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.location', 2] } } } },
                        1: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r.location', 1] } } } }
                    }
                }
            }
        }
    ]);

    return stats[0] || {
        averageOverallRating: 0,
        averageCleanlinessRating: 0,
        averageComfortRating: 0,
        averageFacilitiesRating: 0,
        averageValueRating: 0,
        averageLocationRating: 0,
        numberOfReviews: 0,
        ratingDistribution: {
            overall: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
            cleanliness: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
            comfort: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
            facilities: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
            value: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
            location: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }
        }
    };
};

module.exports = mongoose.model('Review', reviewSchema);
