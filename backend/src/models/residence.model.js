const mongoose = require('mongoose');

const residenceSchema = mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Le titre est requis'],
    trim: true,
    maxlength: [100, 'Le titre ne peut pas dépasser 100 caractères']
  },
  description: {
    type: String,
    required: [true, 'La description est requise']
  },
  price: {
    type: Number,
    required: [true, 'Le prix est requis'],
    min: [0, 'Le prix ne peut pas être négatif']
  },
  pricePeriod: {
    type: String,
    enum: ['hour', 'day', 'week', 'month'],
    default: 'month'
  },
  hourlyRates: {
    oneHour: { type: Number, default: 0 },
    twoHours: { type: Number, default: 0 },
    threeHours: { type: Number, default: 0 },
    additionalHour: { type: Number, default: 0 }
  },
  dailyRates: {
    halfDay: { type: Number, default: 0 },
    fullDay: { type: Number, default: 0 },
    weekend: { type: Number, default: 0 }
  },
  address: {
    type: String,
    required: [true, 'L\'adresse est requise']
  },
  city: {
    type: String,
    required: [true, 'La ville est requise']
  },
  latitude: {
    type: Number,
    default: 0
  },
  longitude: {
    type: Number,
    default: 0
  },
  images: [String],
  bedrooms: {
    type: Number,
    required: [true, 'Le nombre de chambres est requis'],
    min: [0, 'Le nombre de chambres ne peut pas être négatif']
  },
  bathrooms: {
    type: Number,
    required: [true, 'Le nombre de salles de bain est requis'],
    min: [0, 'Le nombre de salles de bain ne peut pas être négatif']
  },
  area: {
    type: Number,
    required: [true, 'La surface est requise'],
    min: [0, 'La surface ne peut pas être négative']
  },
  isFurnished: {
    type: Boolean,
    default: false
  },
  type: {
    type: String,
    required: [true, 'Le type de propriété est requis'],
    enum: ['apartment', 'house', 'villa', 'studio']
  },
  status: {
    type: String,
    enum: ['available', 'unavailable', 'maintenance'],
    default: 'available'
  },
  partner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Le partenaire est requis']
  },
  amenities: [{
    type: String,
    enum: [
      // Options de base
      'wifi', 'parking', 'pool', 'gym', 'security',
      'air_conditioning', 'heating', 'kitchen', 'tv',
      'washing_machine', 'dryer',
      
      // Options générales étendues
      'hot_water', 'balcony', 'garden', 'terrace', 
      'shared_kitchen', 'generator', 'solar_energy',
      'spa', 'restaurant', 'bar', 'room_service', 
      'laundry', 'meeting_room',
      
      // Options liées à l'eau
      'running_water', 'water_tank',
      
      // Options liées à l'électricité
      'electricity', 'inverter', 
      
      // Options liées à Internet
      'fiber_optic', 'ethernet',
      
      // Options liées à la cuisine
      'full_kitchen', 'kitchenette', 'refrigerator', 
      'microwave', 'oven',
      
      // Options liées au confort climatique
      'fan', 'ceiling_fan',
      
      // Options liées à la sécurité
      'alarm_system', 'cctv', 'security_guard',
      
      // Autres options
      'cleaning'
    ]
  }],
  rules: {
    smoking: { type: Boolean, default: false },
    pets: { type: Boolean, default: false },
    parties: { type: Boolean, default: false },
    maxGuests: { type: Number, default: 2 }
  },
  cancellationPolicy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'CancellationPolicy'
  },
  // Classification par étoiles
  stars: {
    type: Number,
    min: 0,
    max: 5,
    default: 0
  },
  // Notation et avis
  rating: {
    overall: { type: Number, default: 0 },
    cleanliness: { type: Number, default: 0 },
    comfort: { type: Number, default: 0 },
    facilities: { type: Number, default: 0 },
    reviewCount: { type: Number, default: 0 }
  },
  // Points d'intérêt à proximité
  nearbyPlaces: [{
    name: { type: String },
    type: { type: String, enum: ['restaurant', 'bar', 'shop', 'market', 'other'] },
    distance: { type: Number }, // en mètres
    description: { type: String }
  }],
  // Questions fréquentes
  faqs: [{
    question: { type: String },
    answer: { type: String }
  }],
  // Informations détaillées sur les équipements
  enhancedAmenities: {
    water: {
      runningWater: { type: Boolean, default: false },
      hotWater: { type: Boolean, default: false },
      waterTank: { type: Boolean, default: false }
    },
    electricity: {
      mainGrid: { type: Boolean, default: false },
      generator: { type: Boolean, default: false },
      solarEnergy: { type: Boolean, default: false },
      inverter: { type: Boolean, default: false }
    },
    internet: {
      wifi: { type: Boolean, default: false },
      fiberOptic: { type: Boolean, default: false },
      ethernet: { type: Boolean, default: false }
    },
    kitchen: {
      fullKitchen: { type: Boolean, default: false },
      kitchenette: { type: Boolean, default: false },
      sharedKitchen: { type: Boolean, default: false },
      refrigerator: { type: Boolean, default: false },
      microwave: { type: Boolean, default: false },
      oven: { type: Boolean, default: false }
    },
    cooling: {
      airConditioning: { type: Boolean, default: false },
      fan: { type: Boolean, default: false },
      ceilingFan: { type: Boolean, default: false }
    },
    security: {
      securitySystem: { type: Boolean, default: false },
      alarmSystem: { type: Boolean, default: false },
      cctv: { type: Boolean, default: false },
      securityGuard: { type: Boolean, default: false }
    },
    extras: {
      cleaning: { type: Boolean, default: false },
      balcony: { type: Boolean, default: false },
      garden: { type: Boolean, default: false },
      terrace: { type: Boolean, default: false },
      parking: { type: Boolean, default: false },
      pool: { type: Boolean, default: false },
      gym: { type: Boolean, default: false },
      spa: { type: Boolean, default: false },
      restaurant: { type: Boolean, default: false },
      bar: { type: Boolean, default: false },
      roomService: { type: Boolean, default: false },
      laundry: { type: Boolean, default: false },
      meetingRoom: { type: Boolean, default: false },
      tv: { type: Boolean, default: false }
    }
  },
  // Méthodes de paiement acceptées
  paymentMethods: [{
    type: String,
    enum: ['cash', 'wave', 'orange_money', 'moov_money', 'mtn_money', 'credit_card', 'bank_transfer']
  }],
  // Champs pour la suppression douce
  deleted: {
    type: Boolean,
    default: false
  },
  deletedAt: {
    type: Date,
    default: null
  }
}, {
  timestamps: true,
  toJSON: { getters: true },
  toObject: { getters: true }
});

// Indexes
residenceSchema.index({
  title: 'text',
  description: 'text',
  city: 'text'
});
residenceSchema.index({ cancellationPolicy: 1 });

// Virtual pour la rétrocompatibilité avec le frontend
residenceSchema.virtual('location').get(function() {
  return {
    address: this.address,
    city: this.city,
    coordinates: [this.longitude, this.latitude]
  };
});

// Méthodes d'instance
residenceSchema.methods.isAvailableForDates = async function(startDate, endDate) {
  const Availability = mongoose.model('Availability');
  return Availability.isPeriodAvailable(this._id, startDate, endDate);
};

residenceSchema.methods.calculateTotalPrice = async function(startDate, endDate) {
  // Implémentation simplifiée: calculer le nombre de jours entre les dates
  const start = new Date(startDate);
  const end = new Date(endDate);
  const days = Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24)));
  
  // Utiliser le prix par jour/mois de la résidence
  let pricePerDay;
  if (this.pricePeriod === 'day') {
    pricePerDay = this.price;
  } else if (this.pricePeriod === 'month') {
    pricePerDay = this.price / 30; // Prix par jour estimé
  } else {
    pricePerDay = this.price; // Utiliser le prix directement
  }
  
  // Calculer le prix total
  return days * pricePerDay;
};

const Residence = mongoose.model('Residence', residenceSchema);
module.exports = Residence;
