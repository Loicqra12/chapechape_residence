const Joi = require('joi');

/**
 * Validation schemas pour les endpoints liés aux appareils
 */

// Validation pour l'enregistrement et la désinscription des appareils
const deviceTokenSchema = {
  body: Joi.object().keys({
    deviceToken: Joi.string()
      .required()
      .min(32) // La plupart des tokens font au moins 32 caractères
      .max(256) // Limiter la taille maximum pour éviter les attaques par injection
      .pattern(/^[A-Za-z0-9_\-\.]+$/) // Accepter uniquement des caractères valides pour un token
      .message({
        'string.base': 'Le token doit être une chaîne de caractères',
        'string.empty': 'Le token ne peut pas être vide',
        'string.min': 'Le token doit contenir au moins {#limit} caractères',
        'string.max': 'Le token ne doit pas dépasser {#limit} caractères',
        'string.pattern.base': 'Le token contient des caractères non autorisés',
        'any.required': 'Le token d\'appareil est requis'
      })
  })
};

// Validation pour la mise à jour des préférences de notification
const notificationPreferencesSchema = {
  body: Joi.object().keys({
    pushEnabled: Joi.boolean()
      .optional()
      .description('Activer/désactiver les notifications push'),
    
    emailEnabled: Joi.boolean()
      .optional()
      .description('Activer/désactiver les notifications par email'),
    
    categories: Joi.object({
      bookings: Joi.boolean().optional(),
      promotions: Joi.boolean().optional(),
      system: Joi.boolean().optional(),
      messages: Joi.boolean().optional(),
      payments: Joi.boolean().optional()
    })
      .optional()
      .description('Préférences par catégorie de notification')
  })
    .min(1)
    .message('Au moins un champ de préférence doit être fourni')
};

module.exports = {
  registerDevice: deviceTokenSchema,
  unregisterDevice: deviceTokenSchema,
  updateNotificationPreferences: notificationPreferencesSchema
};
