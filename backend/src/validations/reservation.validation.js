const Joi = require('joi');

const createReservationSchema = {
    body: Joi.object().keys({
        residence: Joi.string()
            .required()
            .regex(/^[0-9a-fA-F]{24}$/)
            .messages({
                'string.pattern.base': 'ID de résidence invalide'
            }),
        checkIn: Joi.date()
            .required()
            .min('now')
            .messages({
                'date.min': 'La date d\'arrivée doit être dans le futur',
                'date.base': 'La date d\'arrivée doit être une date valide'
            }),
        checkOut: Joi.date()
            .required()
            .greater(Joi.ref('checkIn'))
            .messages({
                'date.greater': 'La date de départ doit être après la date d\'arrivée',
                'date.base': 'La date de départ doit être une date valide'
            }),
        numberOfGuests: Joi.number()
            .required()
            .min(1)
            .messages({
                'number.min': 'Le nombre de voyageurs doit être d\'au moins 1',
                'number.base': 'Le nombre de voyageurs doit être un nombre'
            }),
        specialRequests: Joi.string()
            .max(500)
            .allow('')
            .optional()
    })
};

const modifyReservationSchema = {
    params: Joi.object().keys({
        id: Joi.string()
            .required()
            .regex(/^[0-9a-fA-F]{24}$/)
            .messages({
                'string.pattern.base': 'ID de réservation invalide',
                'string.base': 'ID de réservation doit être une chaîne de caractères'
            })
    }),
    body: Joi.object().keys({
        checkIn: Joi.date()
            .min('now')
            .messages({
                'date.min': 'La date d\'arrivée doit être dans le futur',
                'date.base': 'La date d\'arrivée doit être une date valide'
            }),
        checkOut: Joi.date()
            .greater(Joi.ref('checkIn'))
            .messages({
                'date.greater': 'La date de départ doit être après la date d\'arrivée'
            }),
        numberOfGuests: Joi.number()
            .min(1)
            .messages({
                'number.min': 'Le nombre de voyageurs doit être d\'au moins 1',
                'number.base': 'Le nombre de voyageurs doit être un nombre'
            }),
        specialRequests: Joi.string()
            .max(500)
            .allow('')
    }).min(1) // Au moins un champ doit être modifié
};

const updateStatusSchema = {
    params: Joi.object().keys({
        id: Joi.string()
            .required()
            .regex(/^[0-9a-fA-F]{24}$/)
            .messages({
                'string.pattern.base': 'ID de réservation invalide',
                'string.base': 'ID de réservation doit être une chaîne de caractères'
            })
    }),
    body: Joi.object().keys({
        status: Joi.string()
            .required()
            .valid('pending', 'awaiting_approval', 'payment_pending', 'confirmed', 'in_stay', 'cancelled', 'completed', 'expired', 'refunded') // ✅ ALIGNÉ - statuts réservation complets
            .messages({
                'any.only': 'Statut invalide',
                'string.base': 'Statut doit être une chaîne de caractères'
            })
    })
};

const calculateModificationFeesSchema = {
    body: Joi.object().keys({
        newCheckIn: Joi.date()
            .min('now')
            .messages({
                'date.min': 'La nouvelle date d\'arrivée doit être dans le futur',
                'date.base': 'La nouvelle date d\'arrivée doit être une date valide'
            }),
        newCheckOut: Joi.date()
            .min(Joi.ref('newCheckIn'))
            .messages({
                'date.min': 'La nouvelle date de départ doit être après la nouvelle date d\'arrivée',
                'date.base': 'La nouvelle date de départ doit être une date valide'
            }),
        newNumberOfGuests: Joi.number()
            .min(1)
            .messages({
                'number.min': 'Le nombre de voyageurs doit être supérieur à 0',
                'number.base': 'Le nombre de voyageurs doit être un nombre'
            })
    }).min(1).messages({
        'object.min': 'Au moins une modification doit être spécifiée'
    })
};

const checkAvailabilitySchema = {
    params: Joi.object().keys({
        id: Joi.string()
            .required()
            .regex(/^[0-9a-fA-F]{24}$/)
            .messages({
                'string.pattern.base': 'ID de réservation invalide',
                'string.base': 'ID de réservation doit être une chaîne de caractères'
            })
    }),
    query: Joi.object().keys({
        checkIn: Joi.date()
            .min('now')
            .messages({
                'date.min': 'La date d\'arrivée doit être dans le futur',
                'date.base': 'La date d\'arrivée doit être une date valide'
            }),
        checkOut: Joi.date()
            .greater(Joi.ref('checkIn'))
            .messages({
                'date.greater': 'La date de départ doit être après la date d\'arrivée'
            })
    }).min(1)
};

module.exports = {
    createReservationSchema,
    modifyReservationSchema,
    updateStatusSchema,
    calculateModificationFeesSchema,
    checkAvailabilitySchema
};
