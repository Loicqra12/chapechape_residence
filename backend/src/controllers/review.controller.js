const Review = require('../models/review.model');
const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');

// Créer un avis
const createReview = async (req, res) => {
    try {
        const { residenceId, reservationId, rating, comment, photos } = req.body;

        // Vérifier si l'utilisateur a déjà laissé un avis pour cette résidence
        const existingReview = await Review.findOne({
            user: req.user._id,
            residence: residenceId
        });

        if (existingReview) {
            return res.status(400).json({
                success: false,
                message: "Vous avez déjà laissé un avis pour cette résidence"
            });
        }

        // Créer l'avis
        const review = await Review.create({
            user: req.user._id,
            residence: residenceId,
            reservation: reservationId,
            rating,
            comment,
            photos: photos || []
        });

        // Populate les informations de l'utilisateur pour la réponse
        await review.populate('user', 'firstName lastName avatar');

        res.status(201).json({
            success: true,
            data: review
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Obtenir les avis d'une résidence
const getResidenceReviews = async (req, res) => {
    try {
        const { residenceId } = req.params;
        const { page = 1, limit = 10, sort = '-createdAt' } = req.query;

        // Récupérer les avis
        const reviews = await Review.find({ residence: residenceId })
            .populate('user', 'firstName lastName avatar')
            .sort(sort)
            .limit(limit * 1)
            .skip((page - 1) * limit);

        // Obtenir les statistiques
        const stats = await Review.getResidenceStats(residenceId);

        // Compter le nombre total d'avis pour la pagination
        const count = await Review.countDocuments({ residence: residenceId });

        res.status(200).json({
            success: true,
            data: {
                reviews,
                stats,
                pagination: {
                    total: count,
                    pages: Math.ceil(count / limit),
                    currentPage: page,
                    perPage: limit
                }
            }
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Répondre à un avis (pour les propriétaires)
const respondToReview = async (req, res) => {
    try {
        const { id } = req.params;
        const { comment } = req.body;

        // Trouver l'avis
        const review = await Review.findById(id)
            .populate({
                path: 'residence',
                select: 'partner'
            });
        
        if (!review) {
            return res.status(404).json({
                success: false,
                message: "Avis non trouvé"
            });
        }

        // Vérifier que l'utilisateur est le propriétaire de la résidence
        if (!review.residence || review.residence.partner.toString() !== req.user.id) {
            return res.status(403).json({
                success: false,
                message: "Vous n'êtes pas autorisé à répondre à cet avis"
            });
        }

        // Mettre à jour la réponse
        review.ownerResponse = {
            comment,
            createdAt: new Date()
        };

        await review.save();

        // Retourner l'avis mis à jour avec les informations du propriétaire
        await review.populate([
            {
                path: 'user',
                select: 'firstName lastName avatar'
            },
            {
                path: 'residence',
                select: 'title partner'
            }
        ]);

        res.status(200).json({
            success: true,
            data: review
        });
    } catch (error) {
        console.error('Erreur lors de la réponse à l\'avis:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Modifier un avis (pour l'auteur)
const updateReview = async (req, res) => {
    try {
        const { id } = req.params;
        const { rating, comment, photos } = req.body;

        // Trouver l'avis
        const review = await Review.findById(id);
        
        if (!review) {
            return res.status(404).json({
                success: false,
                message: "Avis non trouvé"
            });
        }

        // Vérifier que l'utilisateur est l'auteur de l'avis
        if (review.user.toString() !== req.user._id.toString()) {
            return res.status(403).json({
                success: false,
                message: "Vous n'êtes pas autorisé à modifier cet avis"
            });
        }

        // Mettre à jour l'avis
        review.rating = rating || review.rating;
        review.comment = comment || review.comment;
        review.photos = photos || review.photos;

        await review.save();

        res.status(200).json({
            success: true,
            data: review
        });
    } catch (error) {
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

// Supprimer un avis (pour l'auteur ou l'admin)
const deleteReview = async (req, res) => {
    try {
        const { id } = req.params;

        // Trouver l'avis
        const review = await Review.findById(id);
        
        if (!review) {
            return res.status(404).json({
                success: false,
                message: "Avis non trouvé"
            });
        }

        // Vérifier que l'utilisateur est l'auteur de l'avis ou un admin
        if (review.user.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                message: "Vous n'êtes pas autorisé à supprimer cet avis"
            });
        }

        // Utiliser deleteOne au lieu de remove
        await Review.deleteOne({ _id: id });

        res.status(200).json({
            success: true,
            message: "Avis supprimé avec succès"
        });
    } catch (error) {
        console.error('Erreur lors de la suppression de l\'avis:', error);
        res.status(400).json({
            success: false,
            message: error.message
        });
    }
};

module.exports = {
    createReview,
    getResidenceReviews,
    respondToReview,
    updateReview,
    deleteReview
};
