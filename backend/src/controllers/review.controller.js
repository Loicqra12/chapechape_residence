const Review = require('../models/review.model');
const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');
const { cacheService } = require('../services/cache.service');
const redisClient = require('../config/redis');

// Créer un avis
const createReview = async (req, res) => {
    try {
        const { residenceId, reservationId, rating, comment, photos } = req.body;

        // Validation des champs requis
        if (!residenceId || rating === undefined || rating === null) {
            return res.status(400).json({
                success: false,
                message: "Veuillez fournir l'identifiant de la résidence et une note"
            });
        }

        // Vérifier si l'utilisateur a déjà laissé un avis pour cette résidence
        const existingReview = await Review.findOne({
            user: req.user._id,
            residence: residenceId
        });

        if (existingReview) {
            // Mettre à jour l'avis existant au lieu de créer un nouveau
            let ratingObject;
            if (typeof rating === 'number') {
                ratingObject = {
                    overall: rating,
                    cleanliness: existingReview.rating.cleanliness || 0,
                    comfort: existingReview.rating.comfort || 0,
                    facilities: existingReview.rating.facilities || 0,
                    value: existingReview.rating.value || 0,
                    location: existingReview.rating.location || 0
                };
            } else if (typeof rating === 'object') {
                ratingObject = {
                    overall: rating.overall || existingReview.rating.overall,
                    cleanliness: rating.cleanliness || existingReview.rating.cleanliness,
                    comfort: rating.comfort || existingReview.rating.comfort,
                    facilities: rating.facilities || existingReview.rating.facilities,
                    value: rating.value || existingReview.rating.value,
                    location: rating.location || existingReview.rating.location
                };
            } else {
                return res.status(400).json({
                    success: false,
                    message: "Format de notation invalide"
                });
            }

            // Mettre à jour l'avis existant
            existingReview.rating = ratingObject;
            existingReview.comment = comment || existingReview.comment;
            if (photos && Array.isArray(photos)) {
                existingReview.photos = photos;
            }
            if (reservationId) {
                existingReview.reservation = reservationId;
            }

            await existingReview.save();
            await existingReview.populate('user', 'firstName lastName avatar');

            // Invalider le cache Redis ET Node-cache
            const cachePattern = `api:/api/reviews/residence/${residenceId}*`;
            
            // Invalider Redis cache (utilisé par le middleware)
            const keys = await redisClient.keys(cachePattern);
            if (keys.length > 0) {
                await redisClient.del(keys);
                console.log(`Redis cache invalidated for keys: ${keys.join(', ')}`);
            }
            
            // Invalider Node cache (pour compatibilité)
            await cacheService.invalidatePattern(`*api/reviews/residence/${residenceId}*`);

            return res.status(200).json({
                success: true,
                data: existingReview,
                message: "Votre avis a été mis à jour avec succès"
            });
        }

        // Créer l'avis
        let ratingObject;
        if (typeof rating === 'number') {
            // Compatibilité avec l'ancien format
            ratingObject = {
                overall: rating,
                cleanliness: 0,
                comfort: 0,
                facilities: 0,
                value: 0,
                location: 0
            };
        } else if (typeof rating === 'object') {
            // Nouveau format détaillé
            ratingObject = {
                overall: rating.overall || 0,
                cleanliness: rating.cleanliness || 0,
                comfort: rating.comfort || 0,
                facilities: rating.facilities || 0,
                value: rating.value || 0,
                location: rating.location || 0
            };
        } else {
            return res.status(400).json({
                success: false,
                message: "Format de notation invalide"
            });
        }

        const review = await Review.create({
            user: req.user._id,
            residence: residenceId,
            reservation: reservationId,
            rating: ratingObject,
            comment,
            photos: photos || []
        });

        // Populate les informations de l'utilisateur pour la réponse
        await review.populate('user', 'firstName lastName avatar');

        // Invalider le cache Redis ET Node-cache
        const cachePattern = `api:/api/reviews/residence/${residenceId}*`;
        
        // Invalider Redis cache (utilisé par le middleware)
        const keys = await redisClient.keys(cachePattern);
        if (keys.length > 0) {
            await redisClient.del(keys);
            console.log(`Redis cache invalidated for keys: ${keys.join(', ')}`);
        }
        
        // Invalider Node cache (pour compatibilité)
        await cacheService.invalidatePattern(`*api/reviews/residence/${residenceId}*`);

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

        // Récupérer l'avis
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

        // Mettre à jour les champs
        if (rating) {
            if (typeof rating === 'number') {
                // Compatibilité avec l'ancien format
                review.rating = {
                    overall: rating,
                    cleanliness: review.rating.cleanliness || 0,
                    comfort: review.rating.comfort || 0,
                    facilities: review.rating.facilities || 0,
                    value: review.rating.value || 0,
                    location: review.rating.location || 0
                };
            } else if (typeof rating === 'object') {
                // Nouveau format détaillé
                review.rating = {
                    overall: rating.overall || review.rating.overall,
                    cleanliness: rating.cleanliness || review.rating.cleanliness,
                    comfort: rating.comfort || review.rating.comfort,
                    facilities: rating.facilities || review.rating.facilities,
                    value: rating.value || review.rating.value,
                    location: rating.location || review.rating.location
                };
            }
        }
        
        review.comment = comment || review.comment;
        
        if (photos && Array.isArray(photos)) {
            review.photos = photos;
        }

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
