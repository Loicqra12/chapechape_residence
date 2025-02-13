const User = require('../../models/user.model');
const Partner = require('../../models/partner.model');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const asyncHandler = require('../../middlewares/async.middleware');
const ApiError = require('../../utils/apiError');

// @desc    Register user
// @route   POST /api/auth/register
// @access  Public
exports.register = asyncHandler(async (req, res) => {
    try {
        const { email, password, firstName, lastName, phoneNumber, role } = req.body;

        // Vérifier si l'utilisateur existe déjà
        const userExists = await User.findOne({ email });
        if (userExists) {
            throw new ApiError('Un utilisateur avec cet email existe déjà', 400);
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

        // Générer le token
        const token = jwt.sign(
            { id: user._id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: parseInt(process.env.JWT_EXPIRE) * 3600 } // Convert hours to seconds
        );

        res.status(201).json({
            success: true,
            token,
            user: {
                id: user._id,
                email: user.email,
                firstName: user.firstName,
                lastName: user.lastName,
                role: user.role
            }
        });
    } catch (error) {
        throw new ApiError('Erreur lors de l\'inscription', 500);
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
            throw new ApiError('Veuillez fournir un email et un mot de passe', 400);
        }

        // Trouver l'utilisateur et inclure le mot de passe
        const user = await User.findOne({ email }).select('+password');
        if (!user) {
            throw new ApiError('Email ou mot de passe incorrect', 401);
        }

        // Vérifier le mot de passe
        const isMatch = await user.matchPassword(password);
        if (!isMatch) {
            throw new ApiError('Email ou mot de passe incorrect', 401);
        }

        // Mettre à jour la dernière connexion
        user.lastLogin = Date.now();
        await user.save();

        // Générer le token
        const token = jwt.sign(
            { id: user._id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: parseInt(process.env.JWT_EXPIRE) * 3600 } // Convert hours to seconds
        );

        res.status(200).json({
            success: true,
            token,
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
        throw new ApiError('Erreur lors de la connexion', 500);
    }
});

// @desc    Get current logged in user
// @route   GET /api/auth/me
// @access  Private
exports.getMe = asyncHandler(async (req, res) => {
    try {
        const user = await User.findById(req.user.id);
        
        if (!user) {
            throw new ApiError('Utilisateur non trouvé', 404);
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
        throw new ApiError('Erreur lors de la récupération du profil', 500);
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
            throw new ApiError('Aucun utilisateur trouvé avec cet email', 404);
        }

        // Générer le token de réinitialisation
        const resetToken = user.getResetPasswordToken();
        await user.save();

        // TODO: Envoyer l'email avec le token
        // Pour l'instant, on renvoie juste le token
        res.json({
            success: true,
            message: 'Instructions envoyées par email',
            resetToken // À supprimer en production
        });
    } catch (error) {
        throw new ApiError('Erreur lors de la réinitialisation du mot de passe', 500);
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
            throw new ApiError('Token invalide ou expiré', 400);
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
        throw new ApiError('Erreur lors de la réinitialisation du mot de passe', 500);
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
