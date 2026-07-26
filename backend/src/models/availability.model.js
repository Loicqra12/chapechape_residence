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
// Convention hôtel : [start, end) — le jour de checkout n'est pas bloqué
// options: { session, excludeReservationId }
availabilitySchema.statics.isPeriodAvailable = async function(residenceId, startDate, endDate, options = {}) {
  const { session = null, excludeReservationId = null } = options;
  const start = new Date(startDate);
  const end = new Date(endDate);

  const query = {
    residenceId,
    date: {
      $gte: start,
      $lt: end, // checkout exclusif (aligné updateAvailabilityForReservation)
    },
    status: { $ne: 'available' },
  };

  // Ne pas compter les jours déjà réservés par la réservation en cours de modification
  if (excludeReservationId) {
    query.reservationId = { $ne: excludeReservationId };
  }

  let findQuery = this.find(query);
  if (session) findQuery = findQuery.session(session);

  const blockedAvailabilities = await findQuery;

  return blockedAvailabilities.length === 0;
};

/**
 * Upsert bulk avec option anti-écrasement.
 * Si failIfReservedByOther=true et status=reserved :
 * - n'écrase pas une date déjà réservée par une autre réservation
 * - upsert crée le doc si absent ; conflit unique → erreur Mongo (course concurrente)
 */
availabilitySchema.statics.upsertBulk = async function(records, options = {}) {
  const { session = null, failIfReservedByOther = false } = options;

  const operations = records.map((record) => {
    if (failIfReservedByOther && record.status === 'reserved') {
      return {
        updateOne: {
          filter: {
            residenceId: record.residenceId,
            date: record.date,
            $or: [
              { status: { $ne: 'reserved' } },
              { reservationId: null },
              { reservationId: { $exists: false } },
              { reservationId: record.reservationId },
            ],
          },
          update: { $set: record },
          upsert: true,
        },
      };
    }

    return {
      updateOne: {
        filter: {
          residenceId: record.residenceId,
          date: record.date,
        },
        update: { $set: record },
        upsert: true,
      },
    };
  });

  const writeOpts = { ordered: true };
  if (session) writeOpts.session = session;
  return this.bulkWrite(operations, writeOpts);
};

const Availability = mongoose.model('Availability', availabilitySchema);

module.exports = Availability;