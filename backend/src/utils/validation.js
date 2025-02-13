const Joi = require('joi');

// Validation pour l'inscription
const registerValidation = Joi.object({
    firstName: Joi.string().min(2).max(50).required(),
    lastName: Joi.string().min(2).max(50).required(),
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
    phone: Joi.string().pattern(/^[0-9+\s-]{8,}$/),
    address: Joi.string()
});

// Validation pour la connexion
const loginValidation = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
});

// Validation pour la création d'une résidence
const residenceValidation = Joi.object({
    name: Joi.string().min(3).max(100).required(),
    description: Joi.string().min(10).required(),
    address: Joi.string().required(),
    city: Joi.string().required(),
    country: Joi.string().required(),
    pricePerNight: Joi.number().min(0).required(),
    capacity: Joi.number().min(1).required(),
    amenities: Joi.array().items(Joi.string()),
    images: Joi.array().items(Joi.string()),
    rules: Joi.array().items(Joi.string())
});

// Validation pour la création d'une réservation
const bookingValidation = Joi.object({
    residenceId: Joi.string().required(),
    checkIn: Joi.date().greater('now').required(),
    checkOut: Joi.date().greater(Joi.ref('checkIn')).required(),
    guests: Joi.number().min(1).required()
});

// Validation pour la création d'un avis
const reviewValidation = Joi.object({
    rating: Joi.number().min(1).max(5).required(),
    comment: Joi.string().min(10).required(),
    residenceId: Joi.string().required()
});

// Validation pour la mise à jour du profil
const updateProfileValidation = Joi.object({
    firstName: Joi.string().min(2).max(50),
    lastName: Joi.string().min(2).max(50),
    email: Joi.string().email(),
    phone: Joi.string().pattern(/^[0-9+\s-]{8,}$/),
    address: Joi.string()
}).min(1);

// Validation pour le changement de mot de passe
const changePasswordValidation = Joi.object({
    currentPassword: Joi.string().required(),
    newPassword: Joi.string().min(6).required(),
    confirmPassword: Joi.string().valid(Joi.ref('newPassword')).required()
});

// Validation pour la réinitialisation du mot de passe
const resetPasswordValidation = Joi.object({
    token: Joi.string().required(),
    newPassword: Joi.string().min(6).required(),
    confirmPassword: Joi.string().valid(Joi.ref('newPassword')).required()
});

// Validation pour le paiement
const paymentValidation = Joi.object({
    bookingId: Joi.string().required(),
    paymentMethod: Joi.string().valid('card', 'paypal', 'mobile_money').required(),
    amount: Joi.number().min(0).required()
});

// Middleware de validation
const validate = (schema) => {
    return (req, res, next) => {
        const { error } = schema.validate(req.body);
        if (error) {
            return res.status(400).json({
                success: false,
                message: error.details[0].message
            });
        }
        next();
    };
};

module.exports = {
    registerValidation,
    loginValidation,
    residenceValidation,
    bookingValidation,
    reviewValidation,
    updateProfileValidation,
    changePasswordValidation,
    resetPasswordValidation,
    paymentValidation,
    validate
};
