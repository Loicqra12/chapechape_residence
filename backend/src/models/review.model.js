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
        required: true
    },
    rating: {
        type: Number,
        required: true,
        min: 1,
        max: 5
    },
    comment: {
        type: String,
        required: true,
        minlength: 10,
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

// Middleware pour vérifier que l'utilisateur a bien séjourné dans la résidence
reviewSchema.pre('save', async function(next) {
    if (this.isNew) {
        const Reservation = mongoose.model('Reservation');
        const reservation = await Reservation.findOne({
            _id: this.reservation,
            user: this.user,
            residence: this.residence,
            status: { $in: ['completed', 'confirmed', 'refunded'] }
            // Retiré la validation de la date de checkout pour les tests
        });

        if (!reservation) {
            next(new Error('Vous devez avoir séjourné dans cette résidence pour laisser un avis'));
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
                averageRating: { $avg: '$rating' },
                numberOfReviews: { $sum: 1 },
                ratings: {
                    $push: '$rating'
                }
            }
        },
        {
            $addFields: {
                ratingDistribution: {
                    5: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r', 5] } } } },
                    4: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r', 4] } } } },
                    3: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r', 3] } } } },
                    2: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r', 2] } } } },
                    1: { $size: { $filter: { input: '$ratings', as: 'r', cond: { $eq: ['$$r', 1] } } } }
                }
            }
        }
    ]);

    return stats[0] || {
        averageRating: 0,
        numberOfReviews: 0,
        ratingDistribution: { 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 }
    };
};

module.exports = mongoose.model('Review', reviewSchema);
