const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema({
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
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Index pour améliorer les performances et assurer l'unicité
favoriteSchema.index({ user: 1, residence: 1 }, { unique: true });

// Index pour les requêtes fréquentes
favoriteSchema.index({ user: 1, createdAt: -1 });

// Méthodes statiques
favoriteSchema.statics.getFavorites = async function(userId) {
    return this.find({ user: userId })
        .populate('residence', 'name description images pricePerNight location')
        .sort('-createdAt');
};

favoriteSchema.statics.toggleFavorite = async function(userId, residenceId) {
    const favorite = await this.findOne({ user: userId, residence: residenceId });
    
    if (favorite) {
        await favorite.remove();
        return { isFavorite: false };
    } else {
        await this.create({ user: userId, residence: residenceId });
        return { isFavorite: true };
    }
};

favoriteSchema.statics.isFavorite = async function(userId, residenceId) {
    const favorite = await this.findOne({ user: userId, residence: residenceId });
    return !!favorite;
};

// Middleware pre-save
favoriteSchema.pre('save', async function(next) {
    // Vérifier si la résidence existe
    const residence = await mongoose.model('Residence').findById(this.residence);
    if (!residence) {
        throw new Error('Residence not found');
    }
    next();
});

module.exports = mongoose.model('Favorite', favoriteSchema);
