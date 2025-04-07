const mongoose = require('mongoose');

const cancellationPolicySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Un nom est requis'],
      trim: true,
      unique: true
    },
    description: {
      type: String,
      required: [true, 'Une description est requise']
    },
    rules: [
      {
        timeBeforeCheckIn: {
          type: Number,
          required: [true, 'Le délai est requis'],
          min: 0,
          comment: 'Délai en heures avant le check-in'
        },
        refundPercentage: {
          type: Number,
          required: [true, 'Le pourcentage de remboursement est requis'],
          min: 0,
          max: 100,
          comment: 'Pourcentage de remboursement (0-100)'
        },
        description: {
          type: String,
          required: [true, 'Une description de la règle est requise']
        }
      }
    ],
    modificationFee: {
      type: Number,
      default: 0,
      min: 0,
      comment: 'Frais appliqués en cas de modification (montant fixe)'
    },
    modificationTimeLimit: {
      type: Number,
      default: 48,
      min: 0,
      comment: 'Délai minimum en heures avant le check-in pour autoriser les modifications'
    },
    residenceTypes: [{
      type: String,
      enum: [
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
      ],
      comment: 'Types de résidences auxquels cette politique s\'applique par défaut'
    }],
    isDefault: {
      type: Boolean,
      default: false,
      comment: 'Si cette politique est la politique par défaut'
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Admin',
      required: true
    }
  },
  {
    timestamps: true
  }
);

// Méthode pour calculer le montant de remboursement
cancellationPolicySchema.methods.calculateRefund = function(bookingTotal, hoursBeforeCheckIn) {
  // Trouver la règle applicable
  const applicableRule = this.rules
    .filter(rule => rule.timeBeforeCheckIn >= hoursBeforeCheckIn)
    .sort((a, b) => a.timeBeforeCheckIn - b.timeBeforeCheckIn)[0];
  
  if (!applicableRule) {
    // Si aucune règle ne s'applique, prendre la règle avec le plus petit délai
    if (this.rules.length > 0) {
      const smallestTimeRule = this.rules.sort((a, b) => a.timeBeforeCheckIn - b.timeBeforeCheckIn)[0];
      return (smallestTimeRule.refundPercentage / 100) * bookingTotal;
    }
    return 0; // Pas de remboursement si aucune règle
  }
  
  return (applicableRule.refundPercentage / 100) * bookingTotal;
};

// Méthode pour vérifier si une modification est autorisée
cancellationPolicySchema.methods.isModificationAllowed = function(hoursBeforeCheckIn) {
  return hoursBeforeCheckIn >= this.modificationTimeLimit;
};

// Méthode pour calculer les frais de modification
cancellationPolicySchema.methods.calculateModificationFee = function(newTotal, oldTotal) {
  // Appliquer des frais fixes, plus la différence si le nouveau total est plus élevé
  const priceDifference = Math.max(0, newTotal - oldTotal);
  return this.modificationFee + priceDifference;
};

// Créer quelques politiques par défaut lors de l'initialisation
cancellationPolicySchema.statics.createDefaultPolicies = async function(adminId) {
  const defaults = [
    {
      name: 'Flexible',
      description: 'Annulation gratuite jusqu\'à 24h avant l\'arrivée. Ensuite, le premier jour est non remboursable.',
      rules: [
        { timeBeforeCheckIn: 24, refundPercentage: 100, description: 'Remboursement complet jusqu\'à 24h avant le check-in' },
        { timeBeforeCheckIn: 0, refundPercentage: 50, description: 'Remboursement de 50% moins de 24h avant le check-in' }
      ],
      modificationFee: 0,
      modificationTimeLimit: 24,
      residenceTypes: ['studio_meuble', 'appartement_meuble', 'chambre_en_colocation'],
      isDefault: true
    },
    {
      name: 'Modéré',
      description: 'Annulation gratuite jusqu\'à 5 jours avant l\'arrivée. Pénalité de 50% après.',
      rules: [
        { timeBeforeCheckIn: 120, refundPercentage: 100, description: 'Remboursement complet jusqu\'à 5 jours avant le check-in' },
        { timeBeforeCheckIn: 24, refundPercentage: 50, description: 'Remboursement de 50% entre 5 jours et 24h avant le check-in' },
        { timeBeforeCheckIn: 0, refundPercentage: 0, description: 'Pas de remboursement moins de 24h avant le check-in' }
      ],
      modificationFee: 1000,
      modificationTimeLimit: 72,
      residenceTypes: ['villa_meublee', 'bungalow', 'maison_flottante']
    },
    {
      name: 'Strict',
      description: 'Annulation avec remboursement de 50% jusqu\'à 7 jours avant l\'arrivée. Après, aucun remboursement.',
      rules: [
        { timeBeforeCheckIn: 168, refundPercentage: 50, description: 'Remboursement de 50% jusqu\'à 7 jours avant le check-in' },
        { timeBeforeCheckIn: 0, refundPercentage: 0, description: 'Pas de remboursement moins de 7 jours avant le check-in' }
      ],
      modificationFee: 5000,
      modificationTimeLimit: 168,
      residenceTypes: ['hotel_de_luxe', 'boutique_hotel', 'residence_hoteliere']
    }
  ];
  
  // Supprimer toutes les politiques existantes si c'est nécessaire pour réinitialiser
  // await this.deleteMany({});
  
  for (const policy of defaults) {
    await this.findOneAndUpdate(
      { name: policy.name },
      { ...policy, createdBy: adminId },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  }
};

const CancellationPolicy = mongoose.model('CancellationPolicy', cancellationPolicySchema);

module.exports = CancellationPolicy; 