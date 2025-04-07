const Joi = require('joi');
const { objectId } = require('./custom.validation');

const cancellationPolicyValidation = {
  getCancellationPolicies: {
    query: Joi.object().keys({
      residenceType: Joi.string().valid(
        'studio_meuble',
        'appartement_meuble',
        'villa_meublee',
        'hotel_de_passage',
        'motel',
        'boutique_hotel',
        'hotel_de_luxe',
        'auberge_et_maison_dhotes',
        'residence_hoteliere',
        'bungalow',
        'lodge_et_ecolodge',
        'case_traditionnelle',
        'maison_flottante',
        'campement_touristique',
        'chambre_en_colocation'
      )
    })
  },

  getCancellationPolicy: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId)
    })
  },

  createCancellationPolicy: {
    body: Joi.object().keys({
      name: Joi.string().required().max(100),
      description: Joi.string().required().max(500),
      rules: Joi.array().items(
        Joi.object({
          timeBeforeCheckIn: Joi.number().required().min(0),
          refundPercentage: Joi.number().required().min(0).max(100),
          description: Joi.string().required().max(200)
        })
      ).min(1).required(),
      modificationFee: Joi.number().min(0),
      modificationTimeLimit: Joi.number().min(0),
      residenceTypes: Joi.array().items(
        Joi.string().valid(
          'studio_meuble',
          'appartement_meuble',
          'villa_meublee',
          'hotel_de_passage',
          'motel',
          'boutique_hotel',
          'hotel_de_luxe',
          'auberge_et_maison_dhotes',
          'residence_hoteliere',
          'bungalow',
          'lodge_et_ecolodge',
          'case_traditionnelle',
          'maison_flottante',
          'campement_touristique',
          'chambre_en_colocation'
        )
      ),
      isDefault: Joi.boolean()
    })
  },

  updateCancellationPolicy: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId)
    }),
    body: Joi.object().keys({
      name: Joi.string().max(100),
      description: Joi.string().max(500),
      rules: Joi.array().items(
        Joi.object({
          timeBeforeCheckIn: Joi.number().min(0),
          refundPercentage: Joi.number().min(0).max(100),
          description: Joi.string().max(200)
        })
      ).min(1),
      modificationFee: Joi.number().min(0),
      modificationTimeLimit: Joi.number().min(0),
      residenceTypes: Joi.array().items(
        Joi.string().valid(
          'studio_meuble',
          'appartement_meuble',
          'villa_meublee',
          'hotel_de_passage',
          'motel',
          'boutique_hotel',
          'hotel_de_luxe',
          'auberge_et_maison_dhotes',
          'residence_hoteliere',
          'bungalow',
          'lodge_et_ecolodge',
          'case_traditionnelle',
          'maison_flottante',
          'campement_touristique',
          'chambre_en_colocation'
        )
      ),
      isDefault: Joi.boolean()
    }).min(1)
  },

  deleteCancellationPolicy: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId)
    })
  },

  calculateRefund: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId)
    }),
    body: Joi.object().keys({
      reservationTotal: Joi.number().required().min(0),
      checkInDate: Joi.date().required().greater('now')
    })
  },

  checkModification: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId)
    }),
    body: Joi.object().keys({
      checkInDate: Joi.date().required().greater('now'),
      oldTotal: Joi.number().required().min(0),
      newTotal: Joi.number().required().min(0)
    })
  }
};

module.exports = {
  cancellationPolicyValidation
};
