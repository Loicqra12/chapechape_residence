const Joi = require('joi');
const { objectId } = require('./custom.validation');

const availabilityValidation = {
  // Validation pour l'endpoint existant check
  checkAvailability: {
    query: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      startDate: Joi.date().required(),
      endDate: Joi.date().required().min(Joi.ref('startDate'))
    })
  },
  
  // Nouvelle validation pour l'endpoint flutter-check avec les paramètres adaptés au client Flutter
  checkFlutterAvailability: {
    query: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      checkIn: Joi.date().required(),
      checkOut: Joi.date().required().min(Joi.ref('checkIn'))
    })
  },

  getAvailabilityCalendar: {
    query: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      startDate: Joi.date().required(),
      endDate: Joi.date().required().min(Joi.ref('startDate'))
    })
  },

  blockDates: {
    body: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      startDate: Joi.date().required(),
      endDate: Joi.date().required().min(Joi.ref('startDate')),
      reason: Joi.string().max(500).allow(''),
      bookingType: Joi.string().valid('hour', 'day', 'week', 'month'),
      type: Joi.string().valid('personal_use', 'maintenance', 'cleaning', 'renovation', 'administrative', 'other'),
    })
  },

  unblockDates: {
    body: Joi.object().keys({
      residenceId: Joi.string().custom(objectId),
      startDate: Joi.date(),
      endDate: Joi.date().min(Joi.ref('startDate')),
      blockId: Joi.string().custom(objectId),
    }).or('blockId', 'residenceId')
  },

  createBlock: {
    body: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      startDate: Joi.date().required(),
      endDate: Joi.date().required().min(Joi.ref('startDate')),
      reason: Joi.string().max(500).allow(''),
      bookingType: Joi.string().valid('hour', 'day', 'week', 'month'),
      type: Joi.string().valid('personal_use', 'maintenance', 'cleaning', 'renovation', 'administrative', 'other'),
    })
  },

  listBlocks: {
    query: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      status: Joi.string().valid('active', 'released'),
    })
  },

  deleteBlock: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId),
    })
  },

  createExternal: {
    body: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      checkIn: Joi.date().required(),
      checkOut: Joi.date().required().min(Joi.ref('checkIn')),
      bookingType: Joi.string().valid('hour', 'day', 'week', 'month'),
      channel: Joi.string().valid('phone', 'whatsapp', 'walk_in', 'other_platform', 'airbnb', 'booking_com', 'other'),
      guestName: Joi.string().max(120).allow(''),
      guestPhone: Joi.string().max(40).allow(''),
      externalReference: Joi.string().max(120).allow(''),
      notes: Joi.string().max(500).allow(''),
    })
  },

  listExternal: {
    query: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      status: Joi.string().valid('active', 'cancelled', 'completed'),
    })
  },

  getExternal: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId),
    })
  },

  updateExternal: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId),
    }),
    body: Joi.object().keys({
      checkIn: Joi.date(),
      checkOut: Joi.date(),
      bookingType: Joi.string().valid('hour', 'day', 'week', 'month'),
      channel: Joi.string().valid('phone', 'whatsapp', 'walk_in', 'other_platform', 'airbnb', 'booking_com', 'other'),
      guestName: Joi.string().max(120).allow(''),
      guestPhone: Joi.string().max(40).allow(''),
      externalReference: Joi.string().max(120).allow(''),
      notes: Joi.string().max(500).allow(''),
    })
  },

  deleteExternal: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId),
    })
  },

  completeExternal: {
    params: Joi.object().keys({
      id: Joi.string().required().custom(objectId),
    })
  },

  updatePricing: {
    body: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      date: Joi.date().required(),
      price: Joi.number().min(0).required()
    })
  }
};

module.exports = availabilityValidation;