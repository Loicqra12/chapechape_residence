const Joi = require('joi');
const { password } = require('./custom.validation');

const register = {
    body: Joi.object().keys({
        email: Joi.string().required().email(),
        password: Joi.string().required().custom(password),
        firstName: Joi.string().required(),
        lastName: Joi.string().required(),
        phoneNumber: Joi.string().pattern(/^\+?[1-9]\d{1,14}$/).required(),
        role: Joi.string().valid('client', 'partner', 'admin', 'superadmin').default('client')
    })
};

const login = {
    body: Joi.object().keys({
        email: Joi.string().required().email(),
        password: Joi.string().required()
    })
};

const logout = {
    body: Joi.object().keys({
        refreshToken: Joi.string().required()
    })
};

const refreshTokens = {
    body: Joi.object().keys({
        refreshToken: Joi.string().required()
    })
};

const forgotPassword = {
    body: Joi.object().keys({
        email: Joi.string().required().email()
    })
};

const resetPassword = {
    query: Joi.object().keys({
        token: Joi.string().required()
    }),
    body: Joi.object().keys({
        password: Joi.string().required().custom(password)
    })
};

const verifyEmail = {
    query: Joi.object().keys({
        token: Joi.string().required()
    })
};

module.exports = {
    register,
    login,
    logout,
    refreshTokens,
    forgotPassword,
    resetPassword,
    verifyEmail
};
