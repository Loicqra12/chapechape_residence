const asyncHandler = require('../middlewares/async.middleware');
const ErrorResponse = require('../utils/errorResponse');
const User = require('../models/user.model');
const logger = require('../utils/logger');

/**
 * @desc      Enregistrer un nouveau token d'appareil pour un utilisateur
 * @route     POST /api/devices/register
 * @access    Privé
 */
exports.registerDevice = asyncHandler(async (req, res, next) => {
    const { deviceToken } = req.body;
    const userId = req.user.id;

    if (!deviceToken) {
        return next(new ErrorResponse('Token d\'appareil requis', 400));
    }

    // Mettre à jour l'utilisateur en ajoutant le token à la liste s'il n'existe pas déjà
    const user = await User.findByIdAndUpdate(
        userId,
        { $addToSet: { deviceTokens: deviceToken } },
        { new: true }
    );

    if (!user) {
        return next(new ErrorResponse('Utilisateur non trouvé', 404));
    }

    logger.info(`Token d'appareil enregistré pour l'utilisateur ${userId}`);
    
    res.status(200).json({
        success: true,
        message: 'Token d\'appareil enregistré avec succès',
        data: {
            deviceTokens: user.deviceTokens
        }
    });
});

/**
 * @desc      Supprimer un token d'appareil pour un utilisateur
 * @route     DELETE /api/devices/unregister
 * @access    Privé
 */
exports.unregisterDevice = asyncHandler(async (req, res, next) => {
    const { deviceToken } = req.body;
    const userId = req.user.id;

    if (!deviceToken) {
        return next(new ErrorResponse('Token d\'appareil requis', 400));
    }

    // Mettre à jour l'utilisateur en retirant le token de la liste
    const user = await User.findByIdAndUpdate(
        userId,
        { $pull: { deviceTokens: deviceToken } },
        { new: true }
    );

    if (!user) {
        return next(new ErrorResponse('Utilisateur non trouvé', 404));
    }

    logger.info(`Token d'appareil supprimé pour l'utilisateur ${userId}`);
    
    res.status(200).json({
        success: true,
        message: 'Token d\'appareil supprimé avec succès',
        data: {
            deviceTokens: user.deviceTokens
        }
    });
});

/**
 * @desc      Mettre à jour les préférences de notification de l'utilisateur
 * @route     PUT /api/devices/preferences
 * @access    Privé
 */
exports.updateNotificationPreferences = asyncHandler(async (req, res, next) => {
    const userId = req.user.id;
    const { pushEnabled, emailEnabled, categories } = req.body;

    // Construire l'objet de mise à jour avec uniquement les champs fournis
    const updateData = {};
    if (pushEnabled !== undefined) {
        updateData['notificationSettings.pushEnabled'] = pushEnabled;
    }
    if (emailEnabled !== undefined) {
        updateData['notificationSettings.emailEnabled'] = emailEnabled;
    }
    if (categories) {
        if (categories.bookings !== undefined) {
            updateData['notificationSettings.categories.bookings'] = categories.bookings;
        }
        if (categories.promotions !== undefined) {
            updateData['notificationSettings.categories.promotions'] = categories.promotions;
        }
        if (categories.system !== undefined) {
            updateData['notificationSettings.categories.system'] = categories.system;
        }
    }

    if (Object.keys(updateData).length === 0) {
        return next(new ErrorResponse('Aucune préférence de notification à mettre à jour', 400));
    }

    const user = await User.findByIdAndUpdate(
        userId,
        { $set: updateData },
        { new: true }
    );

    if (!user) {
        return next(new ErrorResponse('Utilisateur non trouvé', 404));
    }

    logger.info(`Préférences de notification mises à jour pour l'utilisateur ${userId}`);
    
    res.status(200).json({
        success: true,
        message: 'Préférences de notification mises à jour avec succès',
        data: {
            notificationSettings: user.notificationSettings
        }
    });
});

/**
 * @desc      Obtenir les préférences de notification de l'utilisateur
 * @route     GET /api/devices/preferences
 * @access    Privé
 */
exports.getNotificationPreferences = asyncHandler(async (req, res, next) => {
    const userId = req.user.id;
    
    const user = await User.findById(userId);
    
    if (!user) {
        return next(new ErrorResponse('Utilisateur non trouvé', 404));
    }

    res.status(200).json({
        success: true,
        data: {
            deviceTokens: user.deviceTokens,
            notificationSettings: user.notificationSettings || {
                pushEnabled: true,
                emailEnabled: true,
                categories: {
                    bookings: true,
                    promotions: true,
                    system: true
                }
            }
        }
    });
});
