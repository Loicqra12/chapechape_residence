
const mongoose = require('mongoose');

/**
 * @swagger
 * components:
 *   schemas:
 *     Promotion:
 *       type: object
 *       required:
 *         - title
 *         - description
 *         - discountPercentage
 *         - startDate
 *         - endDate
 *         - imageUrl
 *         - residenceId
 *       properties:
 *         id:
 *           type: string
 *           description: L'ID auto-généré de la promotion
 *         title:
 *           type: string
 *           description: Le titre de la promotion
 *         description:
 *           type: string
 *           description: La description détaillée de la promotion
 *         discountPercentage:
 *           type: number
 *           description: Le pourcentage de réduction offert
 *         discountCode:
 *           type: string
 *           description: Le code promo à utiliser (optionnel)
 *         startDate:
 *           type: string
 *           format: date
 *           description: La date de début de la promotion
 *         endDate:
 *           type: string
 *           format: date
 *           description: La date de fin de la promotion
 *         imageUrl:
 *           type: string
 *           description: L'URL de l'image illustrant la promotion
 *         residenceId:
 *           type: string
 *           description: L'ID de la résidence concernée par la promotion
 *         badge:
 *           type: string
 *           description: Un texte court pour le badge de la promotion (optionnel)
 *         isExclusive:
 *           type: boolean
 *           description: Indique si la promotion est exclusive
 *         type:
 *           type: string
 *           enum: [discount, flash, seasonal, bundle, exclusive, newUser]
 *           description: Le type de promotion
 *         termsAndConditions:
 *           type: string
 *           description: Conditions d'utilisation de la promotion (optionnel)
 *       example:
 *         id: 61dbae02-c147-4e28-863c-db7bd402b2d6
 *         title: Week-end luxueux à -30%
 *         description: Profitez d'un séjour de luxe avec une réduction exclusive de 30% sur nos suites premium.
 *         discountPercentage: 30
 *         discountCode: WEEKEND30
 *         startDate: 2025-04-01T00:00:00.000Z
 *         endDate: 2025-04-30T23:59:59.000Z
 *         imageUrl: https://example.com/images/promotion1.jpg
 *         residenceId: 5f8a7d6c5e8d3a2b1c9f8a7d
 *         badge: PROMO FLASH
 *         isExclusive: true
 *         type: flash
 *         termsAndConditions: Offre valable pour les réservations de plus de 2 nuits, non cumulable avec d'autres promotions.
 */

const promotionSchema = mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Le titre est requis'],
    trim: true,
    maxlength: [100, 'Le titre ne peut pas dépasser 100 caractères']
  },
  description: {
    type: String,
    required: [true, 'La description est requise'],
    trim: true
  },
  discountPercentage: {
    type: Number,
    required: [true, 'Le pourcentage de réduction est requis'],
    min: [0, 'Le pourcentage ne peut pas être négatif'],
    max: [100, 'Le pourcentage ne peut pas dépasser 100%']
  },
  discountCode: {
    type: String,
    trim: true
  },
  startDate: {
    type: Date,
    required: [true, 'La date de début est requise']
  },
  endDate: {
    type: Date,
    required: [true, 'La date de fin est requise']
  },
  imageUrl: {
    type: String,
    required: [true, 'L\'URL de l\'image est requise']
  },
  residenceId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Residence',
    required: [true, 'L\'ID de la résidence est requis']
  },
  badge: {
    type: String,
    trim: true
  },
  isExclusive: {
    type: Boolean,
    default: false
  },
  type: {
    type: String,
    enum: ['discount', 'flash', 'seasonal', 'bundle', 'exclusive', 'newUser'],
    default: 'discount'
  },
  termsAndConditions: {
    type: String
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Indexation pour améliorer les performances de recherche
promotionSchema.index({ title: 'text', description: 'text' });
promotionSchema.index({ residenceId: 1 });
promotionSchema.index({ type: 1 });
promotionSchema.index({ isExclusive: 1 });
promotionSchema.index({ startDate: 1, endDate: 1 });

// Vérifier si la promotion est active à une date donnée
promotionSchema.methods.checkActive = function(date = new Date()) {
  return date >= this.startDate && date <= this.endDate;
};

// Calculer le prix après réduction
promotionSchema.methods.calculateDiscountedPrice = function(originalPrice) {
  return originalPrice * (1 - this.discountPercentage / 100);
};

// Calculer le temps restant avant expiration (retourne un objet avec jours, heures, minutes)
promotionSchema.methods.getTimeRemaining = function() {
  const now = new Date();
  const difference = this.endDate - now;
  
  // Si la promotion est déjà expirée
  if (difference <= 0) {
    return { days: 0, hours: 0, minutes: 0, expired: true };
  }
  
  const days = Math.floor(difference / (1000 * 60 * 60 * 24));
  const hours = Math.floor((difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60));
  
  return { days, hours, minutes, expired: false };
};

// Virtuel : indique si c'est une offre de dernière minute (moins de 24h restantes)
promotionSchema.virtual('isLastMinute').get(function() {
  const remaining = this.getTimeRemaining();
  return !remaining.expired && remaining.days === 0 && remaining.hours < 24;
});

// Middleware pre-save pour s'assurer que endDate est après startDate
promotionSchema.pre('save', function(next) {
  if (this.endDate <= this.startDate) {
    return next(new Error('La date de fin doit être postérieure à la date de début'));
  }
  next();
});

const Promotion = mongoose.model('Promotion', promotionSchema);

module.exports = Promotion;
