const Joi = require('joi');
const { objectId } = require('./custom.validation');

const createResidence = {
    body: Joi.object().keys({
        title: Joi.string().required().min(3).max(100),
        description: Joi.string().required().min(10).max(1000),
        price: Joi.number().required().min(0),
        location: Joi.object().keys({
            address: Joi.string().required(),
            city: Joi.string().required(),
            state: Joi.string().required(),
            country: Joi.string().required(),
            coordinates: Joi.object().keys({
                latitude: Joi.number().required().min(-90).max(90),
                longitude: Joi.number().required().min(-180).max(180)
            })
        }).required(),
        features: Joi.array().items(Joi.string()).min(1),
        type: Joi.string().required().valid('apartment', 'house', 'villa', 'studio'),
        bedrooms: Joi.number().required().min(0),
        bathrooms: Joi.number().required().min(0),
        maxOccupancy: Joi.number().required().min(1),
        amenities: Joi.array().items(Joi.string()),
        rules: Joi.array().items(Joi.string()),
        availability: Joi.object().keys({
            startDate: Joi.date().iso(),
            endDate: Joi.date().iso().min(Joi.ref('startDate'))
        }),
        status: Joi.string().valid('available', 'unavailable', 'maintenance')
    })
};

const updateResidence = {
    params: Joi.object().keys({
        id: Joi.string().custom(objectId)
    }),
    body: Joi.object().keys({
        title: Joi.string().min(3).max(100),
        description: Joi.string().min(10).max(1000),
        price: Joi.number().min(0),
        location: Joi.object().keys({
            address: Joi.string(),
            city: Joi.string(),
            state: Joi.string(),
            country: Joi.string(),
            coordinates: Joi.object().keys({
                latitude: Joi.number().min(-90).max(90),
                longitude: Joi.number().min(-180).max(180)
            })
        }),
        features: Joi.array().items(Joi.string()),
        type: Joi.string().valid('apartment', 'house', 'villa', 'studio'),
        bedrooms: Joi.number().min(0),
        bathrooms: Joi.number().min(0),
        maxOccupancy: Joi.number().min(1),
        amenities: Joi.array().items(Joi.string()),
        rules: Joi.array().items(Joi.string()),
        availability: Joi.object().keys({
            startDate: Joi.date().iso(),
            endDate: Joi.date().iso().min(Joi.ref('startDate'))
        }),
        status: Joi.string().valid('available', 'unavailable', 'maintenance')
    }).min(1)
};

const getResidence = {
    params: Joi.object().keys({
        id: Joi.string().custom(objectId)
    })
};

const searchResidences = {
    query: Joi.object().keys({
        query: Joi.string(),
        location: Joi.string(),
        minPrice: Joi.number().min(0),
        maxPrice: Joi.number().min(Joi.ref('minPrice')),
        type: Joi.string().valid('apartment', 'house', 'villa', 'studio'),
        bedrooms: Joi.number().min(0),
        bathrooms: Joi.number().min(0),
        features: Joi.string(),
        page: Joi.number().min(1),
        limit: Joi.number().min(1).max(100),
        sortBy: Joi.string().valid('price', 'createdAt', 'rating'),
        order: Joi.string().valid('asc', 'desc')
    })
};

module.exports = {
    createResidence,
    updateResidence,
    getResidence,
    searchResidences
};
