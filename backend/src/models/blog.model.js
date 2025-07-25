const mongoose = require('mongoose');

const blogSchema = new mongoose.Schema({
    title: {
        type: String,
        required: [true, 'Veuillez fournir un titre'],
        trim: true,
        maxlength: [200, 'Le titre ne peut pas dépasser 200 caractères']
    },
    slug: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    excerpt: {
        type: String,
        required: [true, 'Veuillez fournir un résumé'],
        trim: true,
        maxlength: [500, 'Le résumé ne peut pas dépasser 500 caractères']
    },
    content: {
        type: String,
        required: [true, 'Veuillez fournir le contenu de l\'article']
    },
    imageUrl: {
        type: String,
        required: [true, 'Veuillez fournir une image']
    },
    author: {
        type: String,
        required: [true, 'Veuillez fournir le nom de l\'auteur'],
        trim: true
    },
    authorAvatar: {
        type: String,
        default: null
    },
    category: {
        type: String,
        required: [true, 'Veuillez fournir une catégorie'],
        enum: ['Conseils', 'Marché immobilier', 'Technologie', 'Investissement', 'Actualités', 'Guide'],
        default: 'Actualités'
    },
    tags: [{
        type: String,
        trim: true
    }],
    status: {
        type: String,
        enum: ['draft', 'published', 'archived'],
        default: 'draft'
    },
    featured: {
        type: Boolean,
        default: false
    },
    readTime: {
        type: Number, // en minutes
        default: 5
    },
    views: {
        type: Number,
        default: 0
    },
    likes: {
        type: Number,
        default: 0
    },
    publishedAt: {
        type: Date,
        default: null
    },
    seo: {
        metaTitle: {
            type: String,
            maxlength: [60, 'Le titre SEO ne peut pas dépasser 60 caractères']
        },
        metaDescription: {
            type: String,
            maxlength: [160, 'La description SEO ne peut pas dépasser 160 caractères']
        },
        keywords: [{
            type: String,
            trim: true
        }]
    }
}, {
    timestamps: true
});

// Index pour les recherches
blogSchema.index({ title: 'text', content: 'text', excerpt: 'text' });
blogSchema.index({ category: 1 });
blogSchema.index({ status: 1 });
blogSchema.index({ publishedAt: -1 });
blogSchema.index({ featured: -1 });

// Middleware pour générer le slug automatiquement
blogSchema.pre('save', function(next) {
    if (this.isModified('title') && !this.slug) {
        this.slug = this.title
            .toLowerCase()
            .replace(/[^a-z0-9\s-]/g, '')
            .replace(/\s+/g, '-')
            .replace(/-+/g, '-')
            .trim('-');
    }
    
    // Auto-set publishedAt when status changes to published
    if (this.isModified('status') && this.status === 'published' && !this.publishedAt) {
        this.publishedAt = new Date();
    }
    
    next();
});

// Méthode virtuelle pour formater la date
blogSchema.virtual('formattedDate').get(function() {
    if (!this.publishedAt) return null;
    
    return this.publishedAt.toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
    });
});

// Méthode pour incrémenter les vues
blogSchema.methods.incrementViews = function() {
    this.views += 1;
    return this.save();
};

// Méthode pour calculer le temps de lecture approximatif
blogSchema.methods.calculateReadTime = function() {
    const wordsPerMinute = 200; // Moyenne de lecture
    const wordCount = this.content.split(/\s+/).length;
    this.readTime = Math.ceil(wordCount / wordsPerMinute);
    return this.readTime;
};

// Static method pour obtenir les articles publiés
blogSchema.statics.getPublished = function() {
    return this.find({ status: 'published' })
               .sort({ publishedAt: -1 });
};

// Static method pour obtenir les articles en vedette
blogSchema.statics.getFeatured = function(limit = 3) {
    return this.find({ status: 'published', featured: true })
               .sort({ publishedAt: -1 })
               .limit(limit);
};

// Static method pour rechercher des articles
blogSchema.statics.search = function(query) {
    return this.find({
        $and: [
            { status: 'published' },
            {
                $or: [
                    { $text: { $search: query } },
                    { title: { $regex: query, $options: 'i' } },
                    { excerpt: { $regex: query, $options: 'i' } },
                    { category: { $regex: query, $options: 'i' } }
                ]
            }
        ]
    }).sort({ publishedAt: -1 });
};

const Blog = mongoose.model('Blog', blogSchema);

module.exports = Blog;
