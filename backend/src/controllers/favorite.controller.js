const Favorite = require('../models/favorite.model');
const Residence = require('../models/residence.model');
const ApiError = require('../utils/apiError');
const asyncHandler = require('../middlewares/async.middleware');
const notificationService = require('../services/notification.service');
const { LEGACY } = require('../utils/notification-types');

// @desc    Add residence to favorites
// @route   POST /api/v1/favorites
// @access  Private
exports.addToFavorites = asyncHandler(async (req, res) => {
    const { residenceId } = req.body;

    // Vérifier si la résidence existe
    const residence = await Residence.findById(residenceId);
    if (!residence) {
        throw new ApiError('Residence not found', 404);
    }

    // Vérifier si déjà dans les favoris
    const existingFavorite = await Favorite.findOne({
        user: req.user.id,
        residence: residenceId
    });

    if (existingFavorite) {
        throw new ApiError('Residence already in favorites', 400);
    }

    // Ajouter aux favoris
    const favorite = await Favorite.create({
        user: req.user.id,
        residence: residenceId
    });

    // Créer une notification
    await notificationService.createNotification(
        req.user.id,
        LEGACY.FAVORITE_ADDED,
        `Vous avez ajouté "${residence.title}" à vos favoris`,
        { residenceId, favoriteId: favorite._id }
    );

    res.status(201).json({
        success: true,
        data: favorite
    });
});

// @desc    Get user favorites
// @route   GET /api/v1/favorites
// @access  Private
exports.getFavorites = asyncHandler(async (req, res) => {
    const favorites = await Favorite.find({ user: req.user.id })
        .populate('residence');

    res.status(200).json({
        success: true,
        count: favorites.length,
        data: favorites
    });
});

// @desc    Remove from favorites
// @route   DELETE /api/favorites/:residenceId
// @access  Private
exports.removeFromFavorites = asyncHandler(async (req, res) => {
    const residenceId = req.params.residenceId;
    const userId = req.user.id || req.user._id;
    const favorite = await Favorite.findOne({
        residence: residenceId,
        user: userId,
    }).populate('residence');

    if (!favorite) {
        throw new ApiError('Favorite not found', 404);
    }

    await Favorite.deleteOne({ _id: favorite._id });

    // Créer une notification
    await notificationService.createNotification(
        req.user.id,
        LEGACY.FAVORITE_STATUS_CHANGED,
        `"${favorite.residence.title}" a été retiré de vos favoris`,
        { residenceId: favorite.residence._id }
    );

    res.status(200).json({
        success: true,
        data: {}
    });
});

// @desc    Check if residence is in favorites
// @route   GET /api/v1/favorites/:residenceId/check
// @access  Private
exports.checkFavorite = asyncHandler(async (req, res) => {
    const favorite = await Favorite.findOne({
        user: req.user.id,
        residence: req.params.residenceId
    });

    res.status(200).json({
        success: true,
        isFavorite: !!favorite
    });
});

// @desc    Get favorite statistics (for admin)
// @route   GET /api/v1/favorites/stats
// @access  Private/Admin
exports.getFavoriteStats = asyncHandler(async (req, res) => {
    const stats = await Favorite.aggregate([
        {
            $group: {
                _id: '$residence',
                count: { $sum: 1 }
            }
        },
        {
            $lookup: {
                from: 'residences',
                localField: '_id',
                foreignField: '_id',
                as: 'residence'
            }
        },
        {
            $unwind: '$residence'
        },
        {
            $project: {
                _id: 1,
                count: 1,
                'residence.title': 1,
                'residence.location': 1
            }
        },
        {
            $sort: { count: -1 }
        }
    ]);

    res.status(200).json({
        success: true,
        data: stats
    });
});
