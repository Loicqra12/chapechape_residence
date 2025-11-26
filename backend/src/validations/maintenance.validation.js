const Joi = require('joi');

const createBackup = {
  body: Joi.object().keys({
    name: Joi.string().optional().max(100)
  })
};

const deleteBackup = {
  params: Joi.object().keys({
    id: Joi.string().required()
  })
};

const restoreBackup = {
  params: Joi.object().keys({
    id: Joi.string().required()
  })
};

const cleanup = {
  params: Joi.object().keys({
    type: Joi.string().required().valid('cache', 'logs', 'sessions', 'temp')
  })
};

const toggleMaintenanceMode = {
  body: Joi.object().keys({
    enabled: Joi.boolean().required()
  })
};

module.exports = {
  createBackup,
  deleteBackup,
  restoreBackup,
  cleanup,
  toggleMaintenanceMode
};
