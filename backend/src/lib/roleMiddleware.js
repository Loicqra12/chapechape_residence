const ROLES = {
    SUPER_ADMIN: 'superadmin',
    ADMIN: 'admin',
    PARTNER: 'partner',
    USER: 'user'
};

// Middleware pour vérifier si l'utilisateur est un super admin
exports.isSuperAdmin = (req, res, next) => {
    if (req.user && req.user.role === ROLES.SUPER_ADMIN) {
        next();
    } else {
        res.status(403).json({
            success: false,
            message: "Accès non autorisé. Rôle Super Admin requis."
        });
    }
};

// Middleware pour vérifier si l'utilisateur est un admin
exports.isAdmin = (req, res, next) => {
    if (req.user && (req.user.role === ROLES.ADMIN || req.user.role === ROLES.SUPER_ADMIN)) {
        next();
    } else {
        res.status(403).json({
            success: false,
            message: "Accès non autorisé. Rôle Admin requis."
        });
    }
};

// Middleware pour vérifier si l'utilisateur est un partenaire
exports.isPartner = (req, res, next) => {
    if (req.user && req.user.role === ROLES.PARTNER) {
        next();
    } else {
        res.status(403).json({
            success: false,
            message: "Accès non autorisé. Rôle Partenaire requis."
        });
    }
};

// Middleware pour vérifier si l'utilisateur est un utilisateur normal
exports.isUser = (req, res, next) => {
    if (req.user && req.user.role === ROLES.USER) {
        next();
    } else {
        res.status(403).json({
            success: false,
            message: "Accès non autorisé. Rôle Utilisateur requis."
        });
    }
};

// Middleware pour vérifier plusieurs rôles
exports.hasRole = (roles) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                success: false,
                message: "Non authentifié"
            });
        }

        if (Array.isArray(roles)) {
            if (roles.includes(req.user.role)) {
                next();
            } else {
                res.status(403).json({
                    success: false,
                    message: "Accès non autorisé. Rôle requis : " + roles.join(' ou ')
                });
            }
        } else {
            if (req.user.role === roles) {
                next();
            } else {
                res.status(403).json({
                    success: false,
                    message: "Accès non autorisé. Rôle requis : " + roles
                });
            }
        }
    };
};

// Middleware pour vérifier si l'utilisateur est propriétaire de la ressource
exports.isOwner = (resourceModel) => {
    return async (req, res, next) => {
        try {
            const resource = await resourceModel.findById(req.params.id);
            
            if (!resource) {
                return res.status(404).json({
                    success: false,
                    message: "Ressource non trouvée"
                });
            }

            if (resource.partner.toString() === req.user.id || 
                req.user.role === ROLES.ADMIN || 
                req.user.role === ROLES.SUPER_ADMIN) {
                next();
            } else {
                res.status(403).json({
                    success: false,
                    message: "Vous n'êtes pas autorisé à accéder à cette ressource"
                });
            }
        } catch (error) {
            res.status(500).json({
                success: false,
                message: "Erreur lors de la vérification des droits"
            });
        }
    };
};
