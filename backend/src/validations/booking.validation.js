const Joi = require('joi');
const { objectId } = require('./custom.validation');

const createBooking = {
    body: Joi.object().keys({
        residenceId: Joi.string().required().custom(objectId),
        checkIn: Joi.date().required().min('now'),
        checkOut: Joi.date().required().min(Joi.ref('checkIn')),
        guests: Joi.number().required().min(1),
        specialRequests: Joi.string().max(500)
    })
};

const getBookings = {
    query: Joi.object().keys({
        status: Joi.string().valid('pending', 'confirmed', 'cancelled', 'completed'),
        sortBy: Joi.string(),
        limit: Joi.number().integer(),
        page: Joi.number().integer()
    })
};

const getBooking = {
    params: Joi.object().keys({
        bookingId: Joi.string().required().custom(objectId)
    })
};

const updateBooking = {
    params: Joi.object().keys({
        bookingId: Joi.string().required().custom(objectId)
    }),
    body: Joi.object().keys({
        checkIn: Joi.date().min('now'),
        checkOut: Joi.date().min(Joi.ref('checkIn')),
        guests: Joi.number().min(1),
        specialRequests: Joi.string().max(500),
        status: Joi.string().valid('pending', 'confirmed', 'cancelled', 'completed')
    }).min(1)
};

const deleteBooking = {
    params: Joi.object().keys({
        bookingId: Joi.string().required().custom(objectId)
    })
};

module.exports = {
    createBooking,
    getBookings,
    getBooking,
    updateBooking,
    deleteBooking
};
