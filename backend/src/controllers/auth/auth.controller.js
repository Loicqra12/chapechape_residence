const User = require('../../models/user.model');
const Partner = require('../../models/partner.model');
const jwt = require('../../utils/jwt');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const asyncHandler = require('../../middlewares/async.middleware');
const apiError = require('../../utils/apiError');
const notificationService = require('../../services/notification.service');
const auditService = require('../../services/audit.service');
const LoginAttempt = require('../../models/loginAttempt.model');
const logger = require('../../utils/logger');

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

// @desc    Register partner
// @route   POST /api/auth/register-partner
// @access  Public
exports.registerPartner = asyncHandler(async (req, res) => {
    try {
        const { email, password, firstName, lastName, phoneNumber, countryCode = 'CI' } = req.body;

        // Importer l'utilitaire de normalisation téléphone
        const { normalizePhoneToE164, isValidE164 } = require('../../utils/phone.util');

        // Normaliser le numéro de téléphone en E.164 avec le code pays
        const normalizedPhone = normalizePhoneToE164(phoneNumber, countryCode);

        // Vérifier que la normalisation a réussi
        if (!isValidE164(normalizedPhone)) {
            throw new apiError(`Numéro de téléphone invalide pour le pays ${countryCode}. Formats acceptés: +225..., 07..., 77...`, 400);
        }

        // Vérifier si l'utilisateur existe déjà
        const userExists = await User.findOne({ email });
        if (userExists) {
            throw new apiError('Un utilisateur avec cet email existe déjà', 400);
        }

        // Créer l'utilisateur avec le rôle partner
        const user = await User.create({
            email,
            password,
            firstName,
            lastName,
            phoneNumber: normalizedPhone,
            role: 'partner', // Activation immédiate - pas besoin de vérification séparée
            isPhoneVerified: true // Auto-approuver le téléphone
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
                role: user.role,
                isPhoneVerified: user.isPhoneVerified || false,
                phoneNumber: user.phoneNumber
            },
            message: 'Compte partenaire créé. Veuillez vérifier votre numéro de téléphone pour activer votre compte.'
        });
    } catch (error) {
        // Si c'est déjà une ApiError (par ex. email déjà utilisé, téléphone invalide),
        // on la relaisse remonter telle quelle pour que le client voie le bon message + code HTTP.
        if (error instanceof apiError) {
            throw error;
        }

        // Sinon, on journalise l'erreur technique et on renvoie une 500 générique.
        console.error('Erreur inattendue lors de l\'inscription partenaire:', error);
        throw apiError.internal('Erreur lors de l\'inscription du partenaire');
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

        // Importer l'utilitaire de normalisation téléphone
        const { normalizePhoneToE164, isValidE164 } = require('../../utils/phone.util');

        let user = null;

        // Détecter si c'est un email ou un numéro de téléphone
        if (email.includes('@')) {
            // C'est un email
            user = await User.findOne({ email }).select('+password');
        } else {
            // C'est probablement un numéro de téléphone, essayer de le normaliser
            const normalizedPhone = normalizePhoneToE164(email, 'CI'); // Défaut CI
            if (isValidE164(normalizedPhone)) {
                user = await User.findOne({ phoneNumber: normalizedPhone }).select('+password');
            }

            // Si pas trouvé avec la normalisation, essayer tel quel (fallback)
            if (!user) {
                user = await User.findOne({ phoneNumber: email }).select('+password');
            }
        }

        // ✅ PROTECTION TIMING ATTACK: Hash dummy si utilisateur inexistant
        // Cela garantit que le temps de réponse est constant, que l'utilisateur existe ou non
        const dummyPassword = '$2a$10$dummyhashtopreventtimingattacksonnonexistentusers1234567890';
        const userPassword = user ? user.password : dummyPassword;

        // ✅ TOUJOURS exécuter bcrypt.compare (même si user n'existe pas)
        // Temps de réponse constant
        const isMatch = await bcrypt.compare(password, userPassword);

        // ✅ Vérifier APRÈS le hash (évite short-circuit)
        if (!user || !isMatch) {
            // ✅ Délai aléatoire pour masquer le timing (50-150ms)
            const randomDelay = Math.floor(Math.random() * 100) + 50;
            await new Promise(resolve => setTimeout(resolve, randomDelay));

            // Enregistrer la tentative de connexion échouée (non bloquant)
            try {
                await LoginAttempt.create({
                    ip: req.ip,
                    email: email,
                    success: false,
                    attempts: 1,
                    lastAttempt: new Date()
                });
            } catch (e) {
                logger.warn('LoginAttempt create (échec) ignoré:', e?.message);
            }
            if (user) {
                try {
                    await auditService.logActivity({
                        userId: user._id,
                        action: 'login_failed',
                        module: 'auth',
                        description: `Tentative de connexion échouée depuis ${req.ip}`,
                        ipAddress: req.ip,
                        userAgent: req.get('User-Agent'),
                        metadata: { email, reason: 'invalid_password' },
                        status: 'failure',
                        severity: 'medium'
                    });
                } catch (e) {
                    logger.warn('Audit login_failed ignoré:', e?.message);
                }
            }

            throw new apiError('Email ou mot de passe incorrect', 401);
        }

        // Mettre à jour la dernière connexion (update ciblé pour éviter erreur de validation sur anciens comptes)
        await User.findByIdAndUpdate(user._id, { lastLogin: new Date() }, { runValidators: false });

        // Enregistrer la tentative de connexion réussie (non bloquant)
        try {
            await LoginAttempt.create({
                ip: req.ip,
                email: email,
                success: true,
                attempts: 1,
                lastAttempt: new Date()
            });
        } catch (e) {
            logger.warn('LoginAttempt create (succès) ignoré:', e?.message);
        }
        try {
            await auditService.logActivity({
                userId: user._id,
                action: 'login',
                module: 'auth',
                description: `Connexion réussie depuis ${req.ip}`,
                ipAddress: req.ip,
                userAgent: req.get('User-Agent'),
                metadata: { email, role: user.role },
                status: 'success',
                severity: 'low'
            });
        } catch (e) {
            logger.warn('Audit login ignoré:', e?.message);
        }

        // Envoyer notification de nouvelle connexion
        try {
            await notificationService.notifyNewLogin(
                user._id,
                req.ip,
                req.get('User-Agent')
            );
        } catch (notificationError) {
            console.error('Erreur notification nouvelle connexion:', notificationError);
        }

        // Rôle normalisé (anciens comptes peuvent avoir rôle invalide ou manquant)
        const safeRole = ['client', 'partner_pending', 'partner', 'admin', 'superadmin', 'owner'].includes(user.role) ? user.role : 'client';
        const accessToken = jwt.generateAccessToken(user._id, safeRole);
        const refreshToken = jwt.generateRefreshToken(user._id);

        res.status(200).json({
            success: true,
            token: accessToken,
            refreshToken,
            user: {
                id: user._id.toString(),
                email: user.email,
                firstName: user.firstName || '',
                lastName: user.lastName || '',
                role: safeRole,
                phoneNumber: user.phoneNumber || ''
            }
        });
    } catch (error) {
        logger.error('POST /api/auth/login - erreur', {
            message: error?.message,
            stack: error?.stack,
            name: error?.name
        });
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
                isPhoneVerified: user.isPhoneVerified || false,
                profilePicture: user.profilePicture || user.profileImage,
                profileImage: user.profilePicture || user.profileImage, // Compatibilité partner app
                profilePictureUrl: user.profilePicture || user.profileImage, // Compatibilité client app
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

        // Vérifier le refresh token (key rotation via utils/jwt)
        let decoded;
        try {
            decoded = jwt.verifyToken(refreshToken, 'JWT_REFRESH_SECRET');
        } catch (error) {
            throw new apiError('Token de rafraîchissement invalide ou expiré', 401);
        }

        // Vérifier si l'utilisateur existe toujours
        const user = await User.findById(decoded.id);
        if (!user) {
            throw new apiError('Utilisateur non trouvé', 404);
        }

        // Générer un nouveau token d'accès et refresh (key rotation via utils/jwt)
        const accessToken = jwt.generateAccessToken(user._id.toString(), user.role);
        const newRefreshToken = jwt.generateRefreshToken(user._id.toString());

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

// @desc    Upload profile picture
// @route   POST /api/auth/profile/picture
// @access  Private
exports.uploadProfilePicture = asyncHandler(async (req, res) => {
    try {
        const userId = req.user.id;

        // Vérifier si un fichier a été uploadé (format Multer)
        if (!req.file) {
            throw new apiError('Aucun fichier fourni', 400);
        }

        const file = req.file;

        // Valider le type de fichier
        if (!file.mimetype.startsWith('image/')) {
            throw new apiError('Le fichier doit être une image', 400);
        }

        // Valider la taille du fichier (5MB max)
        const maxSize = 5 * 1024 * 1024; // 5MB
        if (file.size > maxSize) {
            throw new apiError('Le fichier ne doit pas dépasser 5MB', 400);
        }

        // Le fichier est déjà sauvegardé par Multer
        const uploadPath = `uploads/profiles/${file.filename}`;
        const fullPath = file.path;

        // Mettre à jour l'utilisateur avec la nouvelle URL de profil
        const user = await User.findByIdAndUpdate(
            userId,
            { profileImage: `/${uploadPath}` },
            { new: true, select: '-password' }
        );

        if (!user) {
            throw new apiError('Utilisateur non trouvé', 404);
        }

        res.status(200).json({
            success: true,
            message: 'Photo de profil mise à jour avec succès',
            data: {
                profileImage: `/${uploadPath}`,
                profilePictureUrl: `/${uploadPath}`,
                user: {
                    id: user._id,
                    email: user.email,
                    firstName: user.firstName,
                    lastName: user.lastName,
                    profileImage: user.profileImage,
                    role: user.role
                }
            }
        });
    } catch (error) {
        console.error('Erreur upload profile picture:', error);
        throw new apiError(error.message || 'Erreur lors de l\'upload de la photo de profil', error.statusCode || 500);
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

// @desc    Update user profile
// @route   PUT /api/auth/profile
// @access  Private
exports.updateProfile = asyncHandler(async (req, res) => {
    try {
        const userId = req.user.id;
        const { firstName, lastName, phoneNumber, isPhoneVerified } = req.body;

        // Construire l'objet de mise à jour
        const updateData = {};
        if (firstName !== undefined) updateData.firstName = firstName;
        if (lastName !== undefined) updateData.lastName = lastName;
        if (phoneNumber !== undefined) {
            // Normaliser le numéro de téléphone au format E.164
            updateData.phoneNumber = normalizePhoneToE164(phoneNumber);
        }
        if (isPhoneVerified !== undefined) updateData.isPhoneVerified = isPhoneVerified;

        // Mettre à jour l'utilisateur
        const user = await User.findByIdAndUpdate(
            userId,
            updateData,
            { new: true, runValidators: true }
        ).select('-password');

        if (!user) {
            throw new apiError('Utilisateur non trouvé', 404);
        }

        res.status(200).json({
            success: true,
            user: user
        });

    } catch (error) {
        console.error('Erreur updateProfile:', error);
        throw new apiError('Erreur lors de la mise à jour du profil', 500);
    }
});

// Fonction utilitaire pour normaliser les numéros de téléphone
const normalizePhoneToE164 = (phoneNumber) => {
    if (!phoneNumber) return phoneNumber;

    // Si déjà en format E.164, retourner tel quel
    if (phoneNumber.startsWith('+')) {
        return phoneNumber;
    }

    // Par défaut, ajouter le code pays de la Côte d'Ivoire (+225)
    return `+225${phoneNumber}`;
};
