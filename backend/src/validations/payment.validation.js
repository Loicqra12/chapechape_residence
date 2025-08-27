const Joi = require('joi');
const { objectId } = require('./custom.validation');

/**
 * Validation des requêtes liées aux paiements
 * Permet de sécuriser toutes les routes de paiement avec une validation stricte des entrées
 */

const createPaymentIntent = {
  body: Joi.object().keys({
    reservationId: Joi.string().required().custom(objectId).messages({
      'any.required': 'L\'ID de réservation est obligatoire',
      'string.empty': 'L\'ID de réservation ne peut pas être vide',
      'string.base': 'L\'ID de réservation doit être une chaîne de caractères'
    }),
    paymentMethod: Joi.string().required().valid('card', 'mobile_money', 'om', 'momo', 'wave', 'cinetpay').messages({
      'any.required': 'La méthode de paiement est obligatoire',
      'string.empty': 'La méthode de paiement ne peut pas être vide',
      'any.only': 'Méthode de paiement non valide, options: card, mobile_money, om, momo, wave, cinetpay'
    }),
    phoneNumber: Joi.string().when('paymentMethod', {
      is: Joi.string().valid('mobile_money', 'om', 'momo', 'cinetpay'),
      then: Joi.string().required().pattern(/^\+?[0-9]{8,15}$/).messages({
        'any.required': 'Le numéro de téléphone est requis pour ce mode de paiement',
        'string.pattern.base': 'Format de numéro de téléphone invalide'
      }),
      otherwise: Joi.string().optional()
    }),
    // Champs optionnels pour la carte
    saveCard: Joi.boolean().optional(),
    cardToken: Joi.string().optional()
  })
};

const confirmPayment = {
  params: Joi.object().keys({
    paymentId: Joi.string().required().custom(objectId).messages({
      'any.required': 'L\'ID de paiement est obligatoire',
      'string.empty': 'L\'ID de paiement ne peut pas être vide'
    })
  }),
  body: Joi.object().keys({
    paymentIntentId: Joi.string().optional(),
    transactionId: Joi.string().optional(),
    paymentProof: Joi.string().optional(),
    otp: Joi.string().optional().min(4).max(10).messages({
      'string.min': 'L\'OTP doit contenir au moins {#limit} caractères',
      'string.max': 'L\'OTP ne peut pas dépasser {#limit} caractères'
    })
  }).min(1).messages({
    'object.min': 'Au moins une information de confirmation est requise'
  })
};

const requestRefund = {
  params: Joi.object().keys({
    paymentId: Joi.string().required().custom(objectId).messages({
      'any.required': 'L\'ID de paiement est obligatoire',
      'string.empty': 'L\'ID de paiement ne peut pas être vide'
    })
  }),
  body: Joi.object().keys({
    reason: Joi.string().required().min(10).max(500).messages({
      'any.required': 'La raison du remboursement est obligatoire',
      'string.min': 'La raison doit contenir au moins {#limit} caractères',
      'string.max': 'La raison ne peut pas dépasser {#limit} caractères'
    }),
    amount: Joi.number().optional().min(0).messages({
      'number.min': 'Le montant ne peut pas être négatif'
    })
  })
};

const getUserPayments = {
  query: Joi.object().keys({
    limit: Joi.number().integer().min(1).optional().default(10),
    page: Joi.number().integer().min(1).optional().default(1),
    status: Joi.string().optional().valid('pending', 'paid', 'failed', 'refunded', 'cancelled'), // ✅ HARMONISÉ - 'completed' → 'paid'
    sortBy: Joi.string().optional().valid('createdAt:desc', 'createdAt:asc', 'amount:desc', 'amount:asc'),
    fromDate: Joi.date().optional(),
    toDate: Joi.date().optional().min(Joi.ref('fromDate')).messages({
      'date.min': 'La date de fin doit être postérieure à la date de début'
    })
  })
};

module.exports = {
  createPaymentIntent,
  confirmPayment,
  requestRefund,
  getUserPayments
};
