const Joi = require('joi');
const { password } = require('./custom.validation');

const register = {
    body: Joi.object().keys({
        email: Joi.string().required().email().messages({
            'string.email': 'Adresse email invalide',
            'any.required': 'L\'email est obligatoire'
        }),
        password: Joi.string().required().custom(password),
        firstName: Joi.string().required().messages({
            'any.required': 'Le prénom est obligatoire'
        }),
        lastName: Joi.string().required().messages({
            'any.required': 'Le nom est obligatoire'
        }),
        phoneNumber: Joi.string().pattern(/^\+?[1-9]\d{1,14}$/).required().messages({
            'string.pattern.base': 'Numéro de téléphone invalide',
            'any.required': 'Le numéro de téléphone est obligatoire'
        }),
        role: Joi.string().valid('client', 'partner', 'admin', 'superadmin').default('client')
    })
};

// Schéma dédié pour l'inscription partenaire (sans inviteCode pour réduire la friction)
const registerPartner = {
    body: Joi.object().keys({
        email: Joi.string().required().email().messages({
            'string.email': 'Adresse email invalide',
            'any.required': 'L\'email est obligatoire'
        }),
        password: Joi.string().required().custom(password),
        firstName: Joi.string().required().messages({
            'any.required': 'Le prénom est obligatoire'
        }),
        lastName: Joi.string().required().messages({
            'any.required': 'Le nom est obligatoire'
        }),
        // Accepter formats locaux et internationaux - normalisation côté contrôleur
        phoneNumber: Joi.string().pattern(/^[\+]?[0-9\s\-\.\(\)]{7,20}$/).required().messages({
            'string.pattern.base': 'Numéro de téléphone invalide (formats acceptés: +225..., 07..., 77...)',
            'any.required': 'Le numéro de téléphone est obligatoire'
        }),
        countryCode: Joi.string().length(2).optional().default('CI').messages({
            'string.length': 'Code pays doit faire 2 caractères (ex: CI, SN, FR)'
        })
    })
};

const login = {
    body: Joi.object().keys({
        email: Joi.string().required().messages({
            'any.required': 'L\'email ou téléphone est obligatoire'
        }),
        password: Joi.string().required().messages({
            'any.required': 'Le mot de passe est obligatoire'
        })
    })
};

const logout = {
    body: Joi.object().keys({
        refreshToken: Joi.string().required().messages({
            'any.required': 'Le jeton de rafraîchissement est obligatoire'
        })
    })
};

const refreshTokens = {
    body: Joi.object().keys({
        refreshToken: Joi.string().required().messages({
            'any.required': 'Le jeton de rafraîchissement est obligatoire'
        })
    })
};

const forgotPassword = {
    body: Joi.object().keys({
        email: Joi.string().required().email().messages({
            'string.email': 'Adresse email invalide',
            'any.required': 'L\'email est obligatoire'
        })
    })
};

const resetPassword = {
    query: Joi.object().keys({
        token: Joi.string().required().messages({
            'any.required': 'Le jeton de réinitialisation est obligatoire'
        })
    }),
    body: Joi.object().keys({
        password: Joi.string().required().custom(password)
    })
};

const verifyEmail = {
    query: Joi.object().keys({
        token: Joi.string().required().messages({
            'any.required': 'Le jeton de vérification est obligatoire'
        })
    })
};

// Nouveaux schémas pour l'authentification sociale
const googleAuth = {
    body: Joi.object().keys({
        idToken: Joi.string().required().messages({
            'any.required': 'Le token Google est obligatoire'
        }),
        email: Joi.string().email().optional(),
        displayName: Joi.string().optional(),
        photoUrl: Joi.string().uri().optional().messages({
            'string.uri': 'URL de photo de profil invalide'
        }),
        uid: Joi.string().optional()
    })
};

const facebookAuth = {
    body: Joi.object().keys({
        accessToken: Joi.string().required().messages({
            'any.required': 'Le token Facebook est obligatoire'
        }),
        email: Joi.string().email().optional(),
        displayName: Joi.string().optional(),
        photoUrl: Joi.string().uri().optional().messages({
            'string.uri': 'URL de photo de profil invalide'
        }),
        uid: Joi.string().optional()
    })
};

// Schémas pour la vérification par SMS
const requestVerificationCode = {
    body: Joi.object().keys({
        phoneNumber: Joi.string().pattern(/^[\+]?[0-9\s\-\.\(\)]{7,20}$/).required().messages({
            'string.pattern.base': 'Numéro de téléphone invalide (formats acceptés: +225..., 07..., 77...)',
            'any.required': 'Le numéro de téléphone est obligatoire'
        }),
        countryCode: Joi.string().length(2).optional().default('CI').messages({
            'string.length': 'Code pays doit faire 2 caractères (ex: CI, SN, FR)'
        }),
        channel: Joi.string().valid('sms', 'whatsapp').optional().default('sms').messages({
            'any.only': 'Canal invalide (sms ou whatsapp uniquement)'
        }),
        userId: Joi.string().optional(),
        email: Joi.string().email().optional()
    })
};

const verifyCode = {
    body: Joi.object().keys({
        phoneNumber: Joi.string().pattern(/^[\+]?[0-9\s\-\.\(\)]{7,20}$/).required().messages({
            'string.pattern.base': 'Numéro de téléphone invalide (formats acceptés: +225..., 07..., 77...)',
            'any.required': 'Le numéro de téléphone est obligatoire'
        }),
        countryCode: Joi.string().length(2).optional().default('CI').messages({
            'string.length': 'Code pays doit faire 2 caractères (ex: CI, SN, FR)'
        }),
        code: Joi.string().length(6).required().messages({
            'string.length': 'Le code doit contenir exactement 6 caractères',
            'any.required': 'Le code de vérification est obligatoire'
        }),
        codeId: Joi.string().optional().messages({
            'string.base': 'L\'ID du code doit être une chaîne de caractères'
        }),
        userId: Joi.string().optional()
    })
};

const resendVerificationCode = {
    body: Joi.object().keys({
        phoneNumber: Joi.string().pattern(/^\+?[1-9]\d{1,14}$/).required().messages({
            'string.pattern.base': 'Numéro de téléphone invalide',
            'any.required': 'Le numéro de téléphone est obligatoire'
        }),
        userId: Joi.string().optional()
    })
};

const changePassword = {
    body: Joi.object().keys({
        currentPassword: Joi.string().required().messages({
            'any.required': 'Le mot de passe actuel est obligatoire'
        }),
        newPassword: Joi.string().required().custom(password),
        confirmPassword: Joi.string().valid(Joi.ref('newPassword')).required().messages({
            'any.only': 'La confirmation doit correspondre au nouveau mot de passe',
            'any.required': 'La confirmation du mot de passe est obligatoire'
        })
    })
};

module.exports = {
    register,
    registerPartner,
    login,
    logout,
    refreshTokens,
    forgotPassword,
    resetPassword,
    verifyEmail,
    googleAuth,
    facebookAuth,
    requestVerificationCode,
    verifyCode,
    resendVerificationCode,
    changePassword
};
