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

const login = {
    body: Joi.object().keys({
        email: Joi.string().required().email().messages({
            'string.email': 'Adresse email invalide',
            'any.required': 'L\'email est obligatoire'
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
        phoneNumber: Joi.string().pattern(/^\+?[1-9]\d{1,14}$/).required().messages({
            'string.pattern.base': 'Numéro de téléphone invalide',
            'any.required': 'Le numéro de téléphone est obligatoire'
        }),
        userId: Joi.string().optional(),
        email: Joi.string().email().optional()
    })
};

const verifyCode = {
    body: Joi.object().keys({
        phoneNumber: Joi.string().pattern(/^\+?[1-9]\d{1,14}$/).required().messages({
            'string.pattern.base': 'Numéro de téléphone invalide',
            'any.required': 'Le numéro de téléphone est obligatoire'
        }),
        code: Joi.string().length(6).required().messages({
            'string.length': 'Le code doit contenir exactement 6 caractères',
            'any.required': 'Le code de vérification est obligatoire'
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

module.exports = {
    register,
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
    resendVerificationCode
};
