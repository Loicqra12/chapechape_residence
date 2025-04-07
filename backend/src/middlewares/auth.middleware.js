const jwt = require('../utils/jwt');
const User = require('../models/user.model');
const logger = require('../utils/logger');

// Protéger les routes
exports.protect = async (req, res, next) => {
    try {
        let token;

        // Vérifier si le token est dans les headers
        if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
            token = req.headers.authorization.split(' ')[1];
        }

        // Vérifier si le token existe
        if (!token) {
            return res.status(401).json({
                success: false,
                message: 'Non autorisé à accéder à cette route'
            });
        }

        try {
            // Vérifier le token avec le nouvel utilitaire
            const decoded = jwt.verifyToken(token, 'JWT_SECRET');

            // Ajouter l'utilisateur à la requête
            req.user = await User.findById(decoded.id);
            
            // Vérifier si l'utilisateur existe
            if (!req.user) {
                return res.status(401).json({
                    success: false,
                    message: 'L\'utilisateur associé à ce token n\'existe plus'
                });
            }
            
            next();
        } catch (error) {
            logger.error(`Erreur d'authentification: ${error.message}`);
            return res.status(401).json({
                success: false,
                message: 'Token invalide ou expiré'
            });
        }
    } catch (error) {
        logger.error('Auth middleware error:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'authentification'
        });
    }
};

// Autoriser certains rôles
exports.authorize = (...roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: 'Authentification requise'
            });
        }
        
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Le rôle ${req.user.role} n'est pas autorisé à accéder à cette route`
            });
        }
        
        next();
    };
};

// Vérifier la validité d'un refresh token
exports.validateRefreshToken = async (req, res, next) => {
    try {
        const { refreshToken } = req.body;
        
        if (!refreshToken) {
            return res.status(400).json({
                success: false,
                message: 'Refresh token non fourni'
            });
        }
        
        try {
            // Vérifier le refresh token
            const decoded = jwt.verifyToken(refreshToken, 'JWT_REFRESH_SECRET');
            
            // Trouver l'utilisateur associé
            const user = await User.findById(decoded.id);
            
            if (!user) {
                return res.status(401).json({
                    success: false,
                    message: 'Utilisateur non trouvé'
                });
            }
            
            // Ajouter l'utilisateur à la requête
            req.user = user;
            req.refreshToken = refreshToken;
            
            next();
        } catch (error) {
            logger.error(`Erreur de validation du refresh token: ${error.message}`);
            return res.status(401).json({
                success: false,
                message: 'Refresh token invalide ou expiré'
            });
        }
    } catch (error) {
        logger.error('Refresh token middleware error:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de la validation du refresh token'
        });
    }
};
