const mongoose = require('mongoose');

const availabilitySchema = new mongoose.Schema({
  residenceId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Residence',
    required: true,
    index: true
  },
  date: {
    type: Date,
    required: true
  },
  status: {
    type: String,
    enum: ['available', 'reserved', 'blocked'],
    default: 'available'
  },
  // Prix spécifique pour cette date (override du prix par défaut de la résidence)
  price: {
    type: Number,
    min: 0
  },
  // Règles spécifiques pour cette date
  rules: {
    minStay: {
      type: Number,
      min: 1,
      default: 1
    },
    maxStay: {
      type: Number,
      min: 1
    },
    checkInAllowed: {
      type: Boolean,
      default: true
    },
    checkOutAllowed: {
      type: Boolean,
      default: true
    }
  },
  // Capacité spécifique pour cette date (override de la capacité par défaut)
  capacity: {
    type: Number,
    min: 1
  },
  // ID de la réservation associée si le statut est 'reserved'
  reservationId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Reservation'
  },
  // Notes pour cette disponibilité (visible uniquement par le propriétaire)
  notes: {
    type: String,
    maxlength: 500
  },
  // Promotions spécifiques pour cette date
  promotion: {
    active: {
      type: Boolean,
      default: false
    },
    discountPercentage: {
      type: Number,
      min: 0,
      max: 100
    },
    discountAmount: {
      type: Number,
      min: 0
    },
    description: {
      type: String,
      maxlength: 200
    }
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Index composé pour recherche rapide des disponibilités par résidence et date
availabilitySchema.index({ residenceId: 1, date: 1 }, { unique: true });

// Méthode pour vérifier si une disponibilité est réservable
availabilitySchema.methods.isReservable = function() {
  return this.status === 'available';
};

// Méthode pour calculer le prix final avec les promotions
availabilitySchema.methods.getFinalPrice = function() {
  if (!this.price) return null;
  
  if (this.promotion && this.promotion.active) {
    if (this.promotion.discountPercentage) {
      return this.price * (1 - this.promotion.discountPercentage / 100);
    }
    if (this.promotion.discountAmount) {
      return Math.max(0, this.price - this.promotion.discountAmount);
    }
  }
  
  return this.price;
};

// Méthode statique pour rechercher les disponibilités d'une résidence dans une plage de dates
availabilitySchema.statics.findForPeriod = async function(residenceId, startDate, endDate) {
  return this.find({
    residenceId,
    date: {
      $gte: startDate,
      $lte: endDate
    }
  }).sort({ date: 1 });
};

// Méthode statique pour vérifier si une plage de dates est disponible
availabilitySchema.statics.isPeriodAvailable = async function(residenceId, startDate, endDate) {
  // Calculer le nombre de jours entre les dates
  const start = new Date(startDate);
  const end = new Date(endDate);
  const totalDays = Math.ceil((end - start) / (1000 * 60 * 60 * 24)) + 1;

  console.log(`DEBUG: Vérification de disponibilité pour résidence ${residenceId}, du ${start.toISOString()} au ${end.toISOString()} (${totalDays} jours)`);
  
  // Chercher uniquement les entrées NON disponibles
  const blockedAvailabilities = await this.find({
    residenceId,
    date: {
      $gte: start,
      $lte: end
    },
    status: { $ne: 'available' } // Uniquement les statuts non disponibles
  });
  
  console.log(`DEBUG: ${blockedAvailabilities.length} dates bloquées trouvées sur ${totalDays} jours`);
  
  // Si aucune date bloquée n'a été trouvée, la période est disponible
  // Cela signifie qu'une date soit n'a pas d'entrée, soit a une entrée avec status='available'
  const isAvailable = blockedAvailabilities.length === 0;

  console.log(`DEBUG: La résidence est ${isAvailable ? 'disponible' : 'NON disponible'} pour cette période`);
  
  return isAvailable;
};

// Méthode statique pour créer ou mettre à jour plusieurs disponibilités en une seule opération
availabilitySchema.statics.upsertBulk = async function(records) {
  const operations = records.map(record => ({
    updateOne: {
      filter: {
        residenceId: record.residenceId,
        date: record.date
      },
      update: { $set: record },
      upsert: true
    }
  }));
  
  return this.bulkWrite(operations);
};

const Availability = mongoose.model('Availability', availabilitySchema);

module.exports = Availability;