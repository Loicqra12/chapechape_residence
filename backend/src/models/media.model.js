const mongoose = require('mongoose');
const { MEDIA_TYPES } = require('../utils/constants');

const mediaSchema = new mongoose.Schema({
    type: {
        type: String,
        enum: Object.values(MEDIA_TYPES),
        required: true
    },
    url: {
        type: String,
        required: true
    },
    filename: {
        type: String,
        required: true
    },
    mimeType: {
        type: String,
        required: true
    },
    size: {
        type: Number,
        required: true
    },
    dimensions: {
        width: Number,
        height: Number
    },
    thumbnails: {
        small: String,
        medium: String,
        large: String
    },
    residence: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Residence'
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    isPublic: {
        type: Boolean,
        default: true
    },
    metadata: {
        type: mongoose.Schema.Types.Mixed,
        default: {}
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

// Index pour améliorer les performances
mediaSchema.index({ residence: 1 });
mediaSchema.index({ user: 1 });
mediaSchema.index({ type: 1 });

// Méthodes statiques
mediaSchema.statics.getResidenceMedia = async function(residenceId) {
    return this.find({ residence: residenceId })
        .sort('-createdAt');
};

mediaSchema.statics.getUserMedia = async function(userId) {
    return this.find({ user: userId })
        .sort('-createdAt');
};

// Méthodes d'instance
mediaSchema.methods.generateThumbnails = async function() {
    if (this.type !== MEDIA_TYPES.IMAGE) {
        return;
    }

    // Logique pour générer les thumbnails
    // Utiliser sharp ou autre bibliothèque de manipulation d'images
    // this.thumbnails = {
    //     small: smallThumbnailUrl,
    //     medium: mediumThumbnailUrl,
    //     large: largeThumbnailUrl
    // };
    // await this.save();
};

mediaSchema.methods.getPublicUrl = function() {
    if (!this.isPublic) {
        return null;
    }
    return this.url;
};

// Middleware pre-save
mediaSchema.pre('save', function(next) {
    // Si c'est une image, extraire les dimensions
    if (this.type === MEDIA_TYPES.IMAGE && !this.dimensions) {
        // Logique pour extraire les dimensions
        // this.dimensions = { width: ..., height: ... };
    }
    next();
});

// Middleware pre-remove
mediaSchema.pre('remove', async function(next) {
    try {
        // Supprimer le fichier du stockage
        // await deleteFile(this.filename);
        
        // Supprimer les thumbnails
        // if (this.thumbnails) {
        //     await Promise.all([
        //         deleteFile(this.thumbnails.small),
        //         deleteFile(this.thumbnails.medium),
        //         deleteFile(this.thumbnails.large)
        //     ]);
        // }
        next();
    } catch (error) {
        next(error);
    }
});

module.exports = mongoose.model('Media', mediaSchema);
