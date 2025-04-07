const Joi = require('joi');
const { objectId } = require('./custom.validation');

const availabilityValidation = {
  checkAvailability: {
    query: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      startDate: Joi.date().required(),
      endDate: Joi.date().required().min(Joi.ref('startDate'))
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
      reason: Joi.string().max(500)
    })
  },

  unblockDates: {
    body: Joi.object().keys({
      residenceId: Joi.string().required().custom(objectId),
      startDate: Joi.date().required(),
      endDate: Joi.date().required().min(Joi.ref('startDate'))
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