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
        status: Joi.string().valid('available', 'unavailable', 'maintenance'),
        // Nouveau: validation du mode de réservation
        reservationMode: Joi.string().valid('instant', 'approval_required'),
        // Nouveau: validation de la période de prix
        pricePeriod: Joi.string().valid('hour', 'day', 'week', 'month'),
        // Nouveau: validation des méthodes de paiement
        paymentMethods: Joi.array().items(
            Joi.string().valid('cash', 'wave', 'orange_money', 'moov_money', 'mtn_money', 'credit_card', 'bank_transfer')
        ),
        // Nouveau: validation des tarifs horaires
        hourlyRates: Joi.object().keys({
            oneHour: Joi.number().min(0)
        }),
        // Nouveau: validation des tarifs journaliers
        dailyRates: Joi.object().keys({
            halfDay: Joi.number().min(0),
            fullDay: Joi.number().min(0),
            weekend: Joi.number().min(0)
        })
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
        status: Joi.string().valid('available', 'unavailable', 'maintenance'),
        // Nouveau: validation du mode de réservation
        reservationMode: Joi.string().valid('instant', 'approval_required'),
        // Nouveau: validation de la période de prix
        pricePeriod: Joi.string().valid('hour', 'day', 'week', 'month'),
        // Nouveau: validation des méthodes de paiement
        paymentMethods: Joi.array().items(
            Joi.string().valid('cash', 'wave', 'orange_money', 'moov_money', 'mtn_money', 'credit_card', 'bank_transfer')
        ),
        // Nouveau: validation des tarifs horaires
        hourlyRates: Joi.object().keys({
            oneHour: Joi.number().min(0)
        }),
        // Nouveau: validation des tarifs journaliers
        dailyRates: Joi.object().keys({
            halfDay: Joi.number().min(0),
            fullDay: Joi.number().min(0),
            weekend: Joi.number().min(0)
        })
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

// Validation pour le téléchargement d'images
const uploadImages = {
    params: Joi.object().keys({
        id: Joi.string().required().custom(objectId).messages({
            'any.required': "L'identifiant de la résidence est obligatoire",
            'string.empty': "L'identifiant de la résidence ne peut pas être vide"
        })
    }),
    // La validation des fichiers eux-mêmes est gérée par multer et le middleware d'upload
    // Ici nous validons seulement les paramètres de l'URL
};

// Validation pour la suppression d'une image
const deleteImage = {
    params: Joi.object().keys({
        id: Joi.string().required().custom(objectId).messages({
            'any.required': "L'identifiant de la résidence est obligatoire",
            'string.empty': "L'identifiant de la résidence ne peut pas être vide"
        })
    }),
    body: Joi.object().keys({
        imageId: Joi.string().required().messages({
            'any.required': "L'identifiant de l'image est obligatoire",
            'string.empty': "L'identifiant de l'image ne peut pas être vide"
        }),
        cloudinaryId: Joi.string().required().messages({
            'any.required': "L'identifiant Cloudinary est obligatoire pour supprimer l'image",
            'string.empty': "L'identifiant Cloudinary ne peut pas être vide"
        })
    })
};

// Validation pour la mise à jour des FAQs
const updateFaqs = {
    params: Joi.object().keys({
        id: Joi.string().required().custom(objectId).messages({
            'any.required': "L'identifiant de la résidence est obligatoire"
        })
    }),
    body: Joi.object().keys({
        faqs: Joi.array().items(
            Joi.object().keys({
                question: Joi.string().required().min(5).max(200).messages({
                    'any.required': "La question est obligatoire",
                    'string.min': "La question doit contenir au moins {#limit} caractères",
                    'string.max': "La question ne peut pas dépasser {#limit} caractères"
                }),
                answer: Joi.string().required().min(5).max(1000).messages({
                    'any.required': "La réponse est obligatoire",
                    'string.min': "La réponse doit contenir au moins {#limit} caractères",
                    'string.max': "La réponse ne peut pas dépasser {#limit} caractères"
                })
            })
        ).required().messages({
            'any.required': "Les FAQs sont obligatoires"
        })
    })
};

// Validation pour la mise à jour des méthodes de paiement
const updatePaymentMethods = {
    params: Joi.object().keys({
        id: Joi.string().required().custom(objectId)
    }),
    body: Joi.object().keys({
        paymentMethods: Joi.array().items(
            Joi.string().valid(
                'credit_card', 'debit_card', 'bank_transfer', 
                'mobile_money', 'cash', 'om', 'momo', 'wave'
            )
        ).required().min(1).messages({
            'any.required': "Les méthodes de paiement sont obligatoires",
            'array.min': "Au moins une méthode de paiement doit être spécifiée"
        })
    })
};

// Validation pour la mise à jour des équipements améliorés
const updateEnhancedAmenities = {
    params: Joi.object().keys({
        id: Joi.string().required().custom(objectId)
    }),
    body: Joi.object().keys({
        enhancedAmenities: Joi.array().items(
            Joi.object().keys({
                category: Joi.string().required().messages({
                    'any.required': "La catégorie est obligatoire"
                }),
                amenities: Joi.array().items(Joi.string()).required().messages({
                    'any.required': "La liste des équipements est obligatoire"
                })
            })
        ).required().messages({
            'any.required': "Les équipements améliorés sont obligatoires"
        })
    })
};

module.exports = {
    createResidence,
    updateResidence,
    getResidence,
    searchResidences,
    uploadImages,
    deleteImage,
    updateFaqs,
    updatePaymentMethods,
    updateEnhancedAmenities
};
