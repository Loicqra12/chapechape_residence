const Joi = require('joi');
const { objectId } = require('./custom.validation');

/**
 * Validation des requêtes liées à la messagerie
 * Permet de sécuriser toutes les routes de messagerie avec une validation stricte des entrées
 */

const getConversations = {
  query: Joi.object().keys({
    limit: Joi.number().integer().min(1).optional().default(10),
    page: Joi.number().integer().min(1).optional().default(1),
    sort: Joi.string().optional().valid('asc', 'desc').default('desc'),
    search: Joi.string().optional().trim().max(100),
    folder: Joi.string().optional().valid('inbox', 'sent', 'archived') // Pour compatibilité Dashboard
  })
};

const getConversation = {
  params: Joi.object().keys({
    id: Joi.string().required().custom(objectId).messages({
      'any.required': 'L\'ID de la conversation est obligatoire',
      'string.empty': 'L\'ID de la conversation ne peut pas être vide'
    })
  })
};

const getMessages = {
  params: Joi.object().keys({
    id: Joi.string().required().custom(objectId).messages({
      'any.required': 'L\'ID de la conversation est obligatoire',
      'string.empty': 'L\'ID de la conversation ne peut pas être vide'
    })
  }),
  query: Joi.object().keys({
    limit: Joi.number().integer().min(1).optional().default(20),
    page: Joi.number().integer().min(1).optional().default(1),
    sort: Joi.string().optional().valid('asc', 'desc').default('desc')
  })
};

const sendMessage = {
  params: Joi.object().keys({
    id: Joi.string().required().custom(objectId).messages({
      'any.required': 'L\'ID de la conversation est obligatoire',
      'string.empty': 'L\'ID de la conversation ne peut pas être vide'
    })
  }),
  body: Joi.object().keys({
    content: Joi.string().required().trim().min(1).max(2000).messages({
      'any.required': 'Le contenu du message est obligatoire',
      'string.empty': 'Le contenu du message ne peut pas être vide',
      'string.min': 'Le message doit comporter au moins {#limit} caractères',
      'string.max': 'Le message ne peut pas dépasser {#limit} caractères'
    }),
    attachments: Joi.array().items(
      Joi.object().keys({
        url: Joi.string().required().uri().messages({
          'any.required': 'L\'URL de la pièce jointe est obligatoire',
          'string.uri': 'Format d\'URL invalide pour la pièce jointe'
        }),
        type: Joi.string().required().valid('image', 'document', 'video', 'audio', 'other').messages({
          'any.required': 'Le type de la pièce jointe est obligatoire',
          'any.only': 'Type de pièce jointe non valide'
        }),
        name: Joi.string().optional().max(100)
      })
    ).optional(),
    reservationId: Joi.string().optional().custom(objectId)
  })
};

const markAsRead = {
  params: Joi.object().keys({
    id: Joi.string().required().custom(objectId).messages({
      'any.required': 'L\'ID de la conversation est obligatoire',
      'string.empty': 'L\'ID de la conversation ne peut pas être vide'
    })
  })
};

const uploadAttachment = {
  params: Joi.object().keys({
    id: Joi.string().required().custom(objectId).messages({
      'any.required': 'L\'ID de la conversation est obligatoire',
      'string.empty': 'L\'ID de la conversation ne peut pas être vide'
    })
  })
  // Note: La validation du fichier lui-même est gérée par multer
};

const createConversation = {
  body: Joi.object().keys({
    participants: Joi.array().items(
      Joi.string().custom(objectId)
    ).min(1).required().messages({
      'any.required': 'Les participants sont obligatoires',
      'array.min': 'Au moins un participant est requis'
    }),
    reservationId: Joi.string().optional().custom(objectId),
    residenceId: Joi.string().optional().custom(objectId),
    type: Joi.string().optional().valid('general', 'support', 'reservation', 'property').default('general'),
    initialMessage: Joi.string().optional().trim().min(1).max(1000)
  })
};

module.exports = {
  getConversations,
  getConversation,
  getMessages,
  sendMessage,
  markAsRead,
  uploadAttachment,
  createConversation
};
