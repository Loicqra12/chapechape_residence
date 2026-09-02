const Review = require('../models/review.model');
const Residence = require('../models/residence.model');
const Reservation = require('../models/reservation.model');
const { cacheService } = require('../services/cache.service');
const redisClient = require('../config/redis');

const { isPartnerAccount } = require('../security/roles');

async function assertEligibleStayReview(user, residenceId, reservationId) {
    if (!reservationId) {
        const err = new Error('reservationId requis');
        err.statusCode = 400;
        throw err;
    }
    const residence = await Residence.findById(residenceId).select('partner');
    if (!residence) {
        const err = new Error('Résidence introuvable');
        err.statusCode = 404;
        throw err;
    }
    if (isPartnerAccount(user.role) && String(residence.partner) === String(user._id || user.id)) {
        const err = new Error('Un partenaire ne peut pas noter sa propre résidence');
        err.statusCode = 403;
        throw err;
    }
    const reservation = await Reservation.findById(reservationId).select('user partner residence status');
    if (!reservation) {
        const err = new Error('Réservation introuvable');
        err.statusCode = 404;
        throw err;
    }
    if (String(reservation.user) !== String(user._id || user.id)) {
        const err = new Error('Cette réservation ne vous appartient pas');
        err.statusCode = 403;
        throw err;
    }
    if (String(reservation.residence) !== String(residenceId)) {
        const err = new Error('La réservation ne correspond pas à cette résidence');
        err.statusCode = 403;
        throw err;
    }
    if (reservation.status !== 'completed') {
        const err = new Error('Vous ne pouvez noter qu’un séjour terminé');
        err.statusCode = 403;
        throw err;
    }
    return reservation;
}

// Créer un avis
const createReview = async (req, res) => {
    try {
        const { residenceId, reservationId, rating, comment, photos } = req.body;

        if (!residenceId || rating === undefined || rating === null) {
            return res.status(400).json({
                success: false,
                message: "Veuillez fournir l'identifiant de la résidence et une note"
            });
        }

        try {
            await assertEligibleStayReview(req.user, residenceId, reservationId);
        } catch (authErr) {
            return res.status(authErr.statusCode || 403).json({
                success: false,
                message: authErr.message,
            });
        }

        // Vérifier si l'utilisateur a déjà laissé un avis pour cette résidence
        const existingReview = await Review.findOne({
            user: req.user._id,
            residence: residenceId
        });

        if (existingReview) {
            return res.status(409).json({
                success: false,
                message: 'Un avis existe déjà pour cette résidence / ce séjour',
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
        try {
        const keys = await redisClient.keys(cachePattern);
        if (keys.length > 0) {
            await redisClient.del(keys);
        }
        } catch (_cacheErr) {
            // Cache Redis optionnel.
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

// Obtenir tous les avis (pour l'admin dashboard)
const getAllReviews = async (req, res) => {
    try {
        const { page = 1, limit = 20, sort = '-createdAt' } = req.query;

        // Récupérer tous les avis avec pagination
        const reviews = await Review.find()
            .populate('user', 'firstName lastName avatar email')
            .populate('residence', 'title images city')
            .sort(sort)
            .limit(limit * 1)
            .skip((page - 1) * limit);

        // Compter le nombre total d'avis pour la pagination
        const count = await Review.countDocuments();

        res.status(200).json({
            success: true,
            data: reviews,
            pagination: {
                total: count,
                pages: Math.ceil(count / limit),
                currentPage: parseInt(page),
                perPage: parseInt(limit)
            }
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

        const requesterId = (req.user._id && req.user._id.toString()) || req.user.id;
        const privileged = ['admin', 'superadmin'].includes(req.user.role);
        if (review.user.toString() !== requesterId && !privileged) {
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
    getAllReviews,
    getResidenceReviews,
    respondToReview,
    updateReview,
    deleteReview
};
