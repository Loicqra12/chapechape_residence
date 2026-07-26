const mongoose = require('mongoose');

const statsSchema = new mongoose.Schema({
    residence: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Residence',
        required: true
    },
    partner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    date: {
        type: Date,
        required: true
    },
    views: {
        type: Number,
        default: 0
    },
    bookings: {
        type: Number,
        default: 0
    },
    revenue: {
        type: Number,
        default: 0
    },
    occupancyRate: {
        type: Number,
        default: 0
    },
    averageStayDuration: {
        type: Number,
        default: 0
    },
    favoriteCount: {
        type: Number,
        default: 0
    },
    ratings: {
        average: {
            type: Number,
            default: 0
        },
        count: {
            type: Number,
            default: 0
        }
    },
    trends: {
        viewsGrowth: {
            type: Number,
            default: 0
        },
        bookingsGrowth: {
            type: Number,
            default: 0
        },
        revenueGrowth: {
            type: Number,
            default: 0
        }
    }
}, {
    timestamps: true
});

// Index pour optimiser les requêtes
statsSchema.index({ residence: 1, date: 1 });
statsSchema.index({ partner: 1, date: 1 });

// Méthode statique pour mettre à jour les statistiques
statsSchema.statics.updateStats = async function(residenceId, partnerId, statsData) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const stats = await this.findOne({
        residence: residenceId,
        partner: partnerId,
        date: today
    });

    if (stats) {
        // Mettre à jour les statistiques existantes
        Object.assign(stats, statsData);
        return await stats.save();
    } else {
        // Créer de nouvelles statistiques
        return await this.create({
            residence: residenceId,
            partner: partnerId,
            date: today,
            ...statsData
        });
    }
};

// Méthode statique pour obtenir les tendances
statsSchema.statics.getTrends = async function(residenceId, days = 30) {
    const endDate = new Date();
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    return await this.aggregate([
        {
            $match: {
                residence: mongoose.Types.ObjectId(residenceId),
                date: { $gte: startDate, $lte: endDate }
            }
        },
        {
            $sort: { date: 1 }
        },
        {
            $group: {
                _id: null,
                viewsData: { $push: { date: '$date', views: '$views' } },
                bookingsData: { $push: { date: '$date', bookings: '$bookings' } },
                revenueData: { $push: { date: '$date', revenue: '$revenue' } }
            }
        }
    ]);
};

module.exports = mongoose.model('Stats', statsSchema);
