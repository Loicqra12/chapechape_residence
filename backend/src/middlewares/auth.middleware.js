const jwt = require('../utils/jwt');
const apiError = require('../utils/apiError');
const User = require('../models/user.model');
const logger = require('../utils/logger');

exports.protect = async (req, res, next) => {
    try {
        let token;

        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            logger.warn('AUTH_FAILURE', { reason: 'missing_token' });
            return next(
                new apiError('Non autorisé - Token non fourni', 401)
            );
        }

        try {
            const decoded = jwt.verifyToken(token, 'JWT_SECRET');

            const user = await User.findById(decoded.id);

            if (!user) {
                logger.warn('AUTH_FAILURE', { reason: 'user_not_found', userId: decoded.id });
                return next(
                    new apiError('L\'utilisateur associé à ce token n\'existe plus', 401)
                );
            }

            logger.debug('AUTH_SUCCESS', {
                userId: user._id,
                role: user.role,
            });

            if (typeof user.hasPasswordChangedAfter === 'function' && user.hasPasswordChangedAfter(decoded.iat)) {
                logger.warn('AUTH_FAILURE', { reason: 'password_changed', userId: user._id });
                return next(
                    new apiError('L\'utilisateur a récemment changé de mot de passe, veuillez vous reconnecter', 401)
                );
            }

            if (user.isActive === false) {
                logger.warn('AUTH_FAILURE', { reason: 'account_disabled', userId: user._id });
                return next(
                    new apiError('Ce compte a été désactivé', 403)
                );
            }

            req.user = user;
            next();
        } catch (error) {
            logger.warn('AUTH_FAILURE', { reason: 'invalid_token', message: error.message });
            return next(
                new apiError('Erreur d\'authentification: ' + error.message, 401)
            );
        }
    } catch (error) {
        logger.error('Auth middleware error:', error);
        return next(
            new apiError('Erreur lors de l\'authentification', 500)
        );
    }
};

exports.authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return next(
                new apiError('Authentification requise', 401)
            );
        }

        const userRole = req.user.role;
        const allowed = new Set(roles);
        if (allowed.has('admin')) {
            allowed.add('superadmin');
        }
        if (allowed.has('partner')) {
            allowed.add('partner_pending');
        }

        if (!allowed.has(userRole)) {
            logger.warn('FORBIDDEN_ACCESS', { reason: 'role_not_allowed', role: userRole });
            return next(
                new apiError(`Le rôle ${userRole} n'est pas autorisé à accéder à cette route`, 403)
            );
        }

        next();
    };
};

exports.restrictTo = exports.authorize;

exports.validateRefreshToken = async (req, res, next) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            return next(
                new apiError('Refresh token non fourni', 400)
            );
        }

        try {
            const decoded = jwt.verifyToken(refreshToken, 'JWT_REFRESH_SECRET');

            const user = await User.findById(decoded.id);

            if (!user) {
                logger.warn('AUTH_FAILURE', { reason: 'user_not_found' });
                return next(
                    new apiError('Utilisateur non trouvé', 401)
                );
            }

            if (user.isActive === false) {
                logger.warn('AUTH_FAILURE', { reason: 'account_disabled', userId: user._id });
                return next(
                    new apiError('Ce compte a été désactivé', 403)
                );
            }

            req.user = user;
            req.refreshToken = refreshToken;

            next();
        } catch (error) {
            logger.warn('AUTH_FAILURE', { reason: 'invalid_refresh_token', message: error.message });
            return next(
                new apiError('Refresh token invalide ou expiré', 401)
            );
        }
    } catch (error) {
        logger.error('Refresh token middleware error:', error);
        return next(
            new apiError('Erreur lors de la validation du refresh token', 500)
        );
    }
};
