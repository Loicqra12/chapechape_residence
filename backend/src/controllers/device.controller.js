const asyncHandler = require('../middlewares/async.middleware');
const ErrorResponse = require('../utils/errorResponse');
const User = require('../models/user.model');
const mongoose = require('mongoose');
const logger = require('../utils/logger');

const REGISTER_MAX_ATTEMPTS = 8;

function isDeviceRegistrationRetryable(error) {
    if (!error) return false;
    if (error.code === 112 || error.codeName === 'WriteConflict') return true;
    if (Array.isArray(error.errorLabels) && (
        error.errorLabels.includes('TransientTransactionError')
        || error.errorLabels.includes('UnknownTransactionCommitResult')
    )) {
        return true;
    }
    if (error.code === 11000) {
        const dup = `${error.message || ''} ${error.errmsg || ''}`;
        return /deviceTokens/i.test(dup);
    }
    const msg = `${error.message || ''} ${error.errmsg || ''}`;
    return /WriteConflict|TransientTransactionError|Unable to read from a snapshot/i.test(msg);
}

async function registerDeviceTokenOnce(userId, deviceToken) {
    const session = await mongoose.startSession();
    session.startTransaction();
    try {
        await User.updateMany(
            { deviceTokens: deviceToken },
            { $pull: { deviceTokens: deviceToken } },
            { session }
        );

        const user = await User.findByIdAndUpdate(
            userId,
            {
                $addToSet: { deviceTokens: deviceToken },
                $set: { lastAppActivity: new Date() },
            },
            { new: true, session }
        );

        if (!user) {
            await session.abortTransaction();
            return null;
        }

        await session.commitTransaction();
        return user;
    } catch (error) {
        if (session.inTransaction()) {
            await session.abortTransaction();
        }
        throw error;
    } finally {
        session.endSession();
    }
}

async function registerDeviceTokenAtomic(userId, deviceToken) {
    for (let attempt = 1; attempt <= REGISTER_MAX_ATTEMPTS; attempt += 1) {
        try {
            return await registerDeviceTokenOnce(userId, deviceToken);
        } catch (error) {
            if (attempt < REGISTER_MAX_ATTEMPTS && isDeviceRegistrationRetryable(error)) {
                await new Promise((resolve) => setTimeout(resolve, 15 * attempt));
                continue;
            }
            throw error;
        }
    }
    return null;
}

/**
 * @desc      Enregistrer un nouveau token d'appareil pour un utilisateur
 * @route     POST /api/devices/register
 * @access    Privé
 */
exports.registerDevice = asyncHandler(async (req, res, next) => {
    const { deviceToken, appKind, platform } = req.body;
    const userId = req.user._id;

    if (!deviceToken) {
        return next(new ErrorResponse('Token d\'appareil requis', 400));
    }

    const user = await registerDeviceTokenAtomic(userId, deviceToken);

    if (!user) {
        return next(new ErrorResponse('Utilisateur non trouvé', 404));
    }

    logger.info(`Token d'appareil enregistré pour l'utilisateur ${userId}`, {
        appKind: appKind || null,
        platform: platform || null,
        role: user.role,
        tokenCount: user.deviceTokens?.length || 0,
    });
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
    const userId = req.user._id;

    if (!deviceToken) {
        return next(new ErrorResponse('Token d\'appareil requis', 400));
    }

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
        if (categories.messages !== undefined) {
            updateData['notificationSettings.categories.messages'] = categories.messages;
        }
        if (categories.payments !== undefined) {
            updateData['notificationSettings.categories.payments'] = categories.payments;
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
                    messages: true,
                    payments: true,
                    promotions: true,
                    system: true
                }
            }
        }
    });
});

module.exports.registerDeviceTokenAtomic = registerDeviceTokenAtomic;
