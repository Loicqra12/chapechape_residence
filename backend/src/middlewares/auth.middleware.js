const jwt = require('../utils/jwt');
const apiError = require('../utils/apiError');
const User = require('../models/user.model');
const logger = require('../utils/logger');

// Protéger les routes
exports.protect = async (req, res, next) => {
    try {
        logger.info('Auth middleware appelé', { 
            url: req.originalUrl, 
            method: req.method,
            hasAuth: !!req.headers.authorization 
        });
        
        let token;

        // Vérifier si le token est dans les headers
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
            logger.info('Token extrait du header Authorization');
        }

        // Vérifier si le token existe
        if (!token) {
            logger.error('Token manquant dans la requête');
            return next(
                new apiError('Non autorisé - Token non fourni', 401)
            );
        }

        try {
            // Vérifier le token avec le nouvel utilitaire
            const decoded = jwt.verifyToken(token, 'JWT_SECRET');

            // Ajouter l'utilisateur à la requête
            logger.info('Token décodé avec succès', { userId: decoded.id });
            const user = await User.findById(decoded.id);
            
            // Vérifier si l'utilisateur existe
            if (!user) {
                logger.error('Utilisateur non trouvé pour le token', { userId: decoded.id });
                return next(
                    new apiError('L\'utilisateur associé à ce token n\'existe plus', 401)
                );
            }
            
            logger.info('Utilisateur authentifié avec succès', { 
                userId: user._id, 
                email: user.email, 
                role: user.role 
            });
            
            // Vérification du changement de mot de passe désactivée temporairement
            // car la méthode hasPasswordChangedAfter n'existe pas dans le modèle User
            // if (user.hasPasswordChangedAfter(decoded.iat)) {
            //     return next(
            //         new apiError('L\'utilisateur a récemment changé de mot de passe, veuillez vous reconnecter', 401)
            //     );
            // }

            // Tout est OK, passer l'utilisateur dans la requête
            req.user = user;
            next();
        } catch (error) {
            logger.error('Erreur d\'authentification:', error);
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

// Autoriser certains rôles
exports.authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return next(
                new apiError('Authentification requise', 401)
            );
        }
        
        if (!roles.includes(req.user.role)) {
            return next(
                new apiError(`Le rôle ${req.user.role} n'est pas autorisé à accéder à cette route`, 403)
            );
        }
        
        next();
    };
};

// Alias utilisé par les routes (partner-verification, etc.) : même logique qu'authorize
exports.restrictTo = exports.authorize;

// Vérifier la validité d'un refresh token
exports.validateRefreshToken = async (req, res, next) => {
    try {
        const { refreshToken } = req.body;
        
        if (!refreshToken) {
            return next(
                new apiError('Refresh token non fourni', 400)
            );
        }
        
        try {
            // Vérifier le refresh token
            const decoded = jwt.verifyToken(refreshToken, 'JWT_REFRESH_SECRET');
            
            // Trouver l'utilisateur associé
            const user = await User.findById(decoded.id);
            
            if (!user) {
                return next(
                    new apiError('Utilisateur non trouvé', 401)
                );
            }
            
            // Ajouter l'utilisateur à la requête
            req.user = user;
            req.refreshToken = refreshToken;
            
            next();
        } catch (error) {
            logger.error(`Erreur de validation du refresh token: ${error.message}`);
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
