const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

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
            // Vérifier le token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);

            // Ajouter l'utilisateur à la requête
            req.user = await User.findById(decoded.id);
            next();
        } catch (error) {
            return res.status(401).json({
                success: false,
                message: 'Non autorisé à accéder à cette route'
            });
        }
    } catch (error) {
        console.error('Auth middleware error:', error);
        res.status(500).json({
            success: false,
            message: 'Erreur lors de l\'authentification'
        });
    }
};

// Autoriser certains rôles
exports.authorize = (...roles) => {
    return (req, res, next) => {
        if (!roles.includes(req.user.role)) {
            return res.status(403).json({
                success: false,
                message: `Le rôle ${req.user.role} n'est pas autorisé à accéder à cette route`
            });
        }
        next();
    };
};
