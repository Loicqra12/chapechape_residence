const User = require('../../models/user.model');
const Partner = require('../../models/partner.model');
const jwt = require('../../utils/jwt');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const asyncHandler = require('../../middlewares/async.middleware');
const apiError = require('../../utils/apiError');

// @desc    Register user
// @route   POST /api/auth/register
// @access  Public
exports.register = asyncHandler(async (req, res) => {
    try {
        const { email, password, firstName, lastName, phoneNumber, role } = req.body;

        // Vérifier si l'utilisateur existe déjà
        const userExists = await User.findOne({ email });
        if (userExists) {
            throw new apiError('Un utilisateur avec cet email existe déjà', 400);
        }

        // Créer l'utilisateur
        const user = await User.create({
            email,
            password,
            firstName,
            lastName,
            phoneNumber,
            role: role || 'client' // Par défaut, c'est un client
        });

        // Générer le token d'accès avec la nouvelle fonction
        const accessToken = jwt.generateAccessToken(user._id, user.role);
        
        // Générer le token de rafraîchissement
        const refreshToken = jwt.generateRefreshToken(user._id);

        res.status(201).json({
            success: true,
            token: accessToken,
            refreshToken,
            user: {
                id: user._id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                role: user.role
            }
        });
    } catch (error) {
        throw new apiError('Erreur lors de l\'inscription', 500);
    }
});

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
exports.login = asyncHandler(async (req, res) => {
    try {
        const { email, password } = req.body;

        // Vérifier si l'email et le mot de passe sont fournis
        if (!email || !password) {
            throw new apiError('Veuillez fournir un email et un mot de passe', 400);
        }

        // Trouver l'utilisateur et inclure le mot de passe
        const user = await User.findOne({ email }).select('+password');
        if (!user) {
            throw new apiError('Email ou mot de passe incorrect', 401);
        }

        // Vérifier le mot de passe
        const isMatch = await user.matchPassword(password);
        if (!isMatch) {
            throw new apiError('Email ou mot de passe incorrect', 401);
        }

        // Mettre à jour la dernière connexion
        user.lastLogin = Date.now();
        await user.save();

        // Générer le token d'accès avec la nouvelle fonction
        const accessToken = jwt.generateAccessToken(user._id, user.role);
        
        // Générer le token de rafraîchissement
        const refreshToken = jwt.generateRefreshToken(user._id);

        res.status(200).json({
            success: true,
            token: accessToken,
            refreshToken,
            user: {
                id: user._id.toString(),  // Convertir l'ObjectId en string
                email: user.email,
                firstName: user.firstName || '',  // Valeur par défaut si null
                lastName: user.lastName || '',    // Valeur par défaut si null
                role: user.role || 'client',     // Valeur par défaut si null
                phoneNumber: user.phoneNumber || '' // Valeur par défaut si null
            }
        });
    } catch (error) {
        throw new apiError('Erreur lors de la connexion', 500);
    }
});

// @desc    Get current logged in user
// @route   GET /api/auth/me
// @access  Private
exports.getMe = asyncHandler(async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        
        if (!user) {
            throw new apiError('Utilisateur non trouvé', 404);
        }

        res.json({
            success: true,
            user: {
                id: user._id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                role: user.role,
                phoneNumber: user.phoneNumber,
                profileImage: user.profileImage,
                createdAt: user.createdAt
            }
        });
    } catch (error) {
        throw new apiError('Erreur lors de la récupération du profil', 500);
    }
});

// @desc    Forgot password
// @route   POST /api/auth/forgot-password
// @access  Public
exports.forgotPassword = asyncHandler(async (req, res) => {
    try {
        const { email } = req.body;

        const user = await User.findOne({ email });
        if (!user) {
            throw new apiError('Aucun utilisateur trouvé avec cet email', 404);
        }

        // Générer le token de réinitialisation
        const resetToken = user.getResetPasswordToken();
        await user.save();

        // Envoyer l'email avec le token
        try {
            const emailService = require('../../services/email.service');
            await emailService.sendPasswordReset(email, resetToken);
            
            res.json({
                success: true,
                message: 'Instructions envoyées par email'
            });
        } catch (emailError) {
            // En cas d'erreur d'envoi, réinitialiser le token
            user.resetPasswordToken = undefined;
            user.resetPasswordExpire = undefined;
            await user.save();
            
            throw new apiError('Erreur lors de l\'envoi de l\'email. Veuillez réessayer.', 500);
        }
    } catch (error) {
        throw new apiError('Erreur lors de la réinitialisation du mot de passe', 500);
    }
});

// @desc    Reset password
// @route   PUT /api/auth/reset-password/:resetToken
// @access  Public
exports.resetPassword = asyncHandler(async (req, res) => {
    try {
        // Get hashed token
        const resetPasswordToken = crypto
            .createHash('sha256')
            .update(req.params.resetToken)
            .digest('hex');

        const user = await User.findOne({
            resetPasswordToken,
            resetPasswordExpire: { $gt: Date.now() }
        });

        if (!user) {
            throw new apiError('Token invalide ou expiré', 400);
        }

        // Set new password
        user.password = req.body.password;
        user.resetPasswordToken = undefined;
        user.resetPasswordExpire = undefined;
        await user.save();

        res.json({
            success: true,
            message: 'Mot de passe réinitialisé avec succès'
        });
    } catch (error) {
        throw new apiError('Erreur lors de la réinitialisation du mot de passe', 500);
    }
});

// @desc    Refresh JWT token
// @route   POST /api/auth/refresh-token
// @access  Public
exports.refreshToken = asyncHandler(async (req, res) => {
    try {
        const { refreshToken } = req.body;

        if (!refreshToken) {
            throw new apiError('Token de rafraîchissement non fourni', 400);
        }

        // Vérifier le refresh token
        let decoded;
        try {
            decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        } catch (error) {
            throw new apiError('Token de rafraîchissement invalide ou expiré', 401);
        }

        // Vérifier si l'utilisateur existe toujours
        const user = await User.findById(decoded.id);
        if (!user) {
            throw new apiError('Utilisateur non trouvé', 404);
        }

        // Générer un nouveau token d'accès
        const accessToken = jwt.sign(
            { id: user._id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: parseInt(process.env.JWT_EXPIRE) * 3600 } // Convert hours to seconds
        );

        // Générer un nouveau token de rafraîchissement 
        const newRefreshToken = jwt.sign(
            { id: user._id },
            process.env.JWT_REFRESH_SECRET,
            { expiresIn: parseInt(process.env.JWT_REFRESH_EXPIRE) * 24 * 3600 } // Convert days to seconds
        );

        res.status(200).json({
            success: true,
            accessToken,
            refreshToken: newRefreshToken,
            user: {
                id: user._id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                role: user.role
            }
        });
    } catch (error) {
        throw new apiError('Erreur lors du rafraîchissement du token', 500);
    }
});

// @desc    Logout user
// @route   POST /api/auth/logout
// @access  Private
exports.logout = asyncHandler(async (req, res) => {
    try {
        // Optionnel: on pourrait ajouter le token à une liste noire
        // mais cela nécessiterait une infrastructure Redis ou similaire
        // pour une gestion efficace des tokens invalidés
        
        // Pour l'instant, nous retournons simplement un succès
        // La déconnexion réelle se fait côté client en supprimant le token
        res.status(200).json({
            success: true,
            message: 'Déconnexion réussie'
        });
    } catch (error) {
        throw new apiError('Erreur lors de la déconnexion', 500);
    }
});

// Fonction utilitaire pour générer un JWT
const generateToken = (userId) => {
    return jwt.sign(
        { id: userId },
        process.env.JWT_SECRET,
        { expiresIn: parseInt(process.env.JWT_EXPIRE) * 3600 } // Convert hours to seconds
    );
};
