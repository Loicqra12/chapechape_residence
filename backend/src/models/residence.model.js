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
  // Structure améliorée pour les données de géolocalisation
  locationData: {
    coordinates: {
      latitude: {
        type: Number,
        default: 0
      },
      longitude: {
        type: Number,
        default: 0
      }
    },
    formattedAddress: {
      type: String,
      trim: true
    },
    // Champs maintenus pour compatibilité avec le code existant
    address: {
      type: String,
      required: [true, 'L\'adresse est requise']
    },
    city: {
      type: String,
      required: [true, 'La ville est requise']
    },
    country: {
      type: String,
      default: 'CI' // Côte d'Ivoire par défaut
    }
  },
  // Maintenir les champs précédents pour compatibilité descendante
  latitude: {
    type: Number,
    default: function() {
      return this.locationData?.coordinates?.latitude || 0;
    }
  },
  longitude: {
    type: Number,
    default: function() {
      return this.locationData?.coordinates?.longitude || 0;
    }
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
  // Si nous avons des données dans la nouvelle structure, les utiliser
  if (this.locationData && this.locationData.coordinates) {
    return {
      address: this.locationData.address || this.address,
      city: this.locationData.city || this.city,
      formattedAddress: this.locationData.formattedAddress,
      coordinates: [this.locationData.coordinates.longitude, this.locationData.coordinates.latitude]
    };
  }
  // Sinon utiliser les anciennes données
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
  const start = new Date(startDate);
  const end = new Date(endDate);
  
  // Différentes méthodes de calcul selon la période de tarification
  switch(this.pricePeriod) {
    case 'hour':
      // Calculer le nombre d'heures entre les dates
      const hours = Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60)));
      console.log(`[Price] Calcul pour résidence horaire: ${hours} heures à ${this.price} par heure`);
      return parseFloat((hours * this.price).toFixed(2)); // Forcer un nombre à virgule flottante
    
    case 'day':
      // Calculer le nombre de jours entre les dates
      const daysForDay = Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24)));
      console.log(`[Price] Calcul pour résidence journalière: ${daysForDay} jours à ${this.price} par jour`);
      return parseFloat((daysForDay * this.price).toFixed(2));
    
    case 'week':
      // Calculer le nombre de semaines entre les dates
      const weeks = Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24 * 7)));
      console.log(`[Price] Calcul pour résidence hebdomadaire: ${weeks} semaines à ${this.price} par semaine`);
      return parseFloat((weeks * this.price).toFixed(2));
    
    case 'month':
    default:
      // Calculer le nombre de mois approximatif (base 30 jours)
      const daysForMonth = Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24)));
      const months = daysForMonth / 30;
      console.log(`[Price] Calcul pour résidence mensuelle: ${daysForMonth} jours (${months.toFixed(2)} mois) à ${this.price} par mois`);
      return parseFloat((months * this.price).toFixed(2));
  }
};

// Ajout d'index pour améliorer les performances des requêtes

// Index géospatial pour les recherches par proximité
residenceSchema.index({ 'locationData.coordinates.latitude': 1, 'locationData.coordinates.longitude': 1 });

// Index 2dsphere pour les recherches géospatiales avancées (nearby, radius, etc.)
residenceSchema.index({
  'locationData.coordinates': '2dsphere'
});

// Index composé pour les recherches par ville et prix (filtres courants)
residenceSchema.index({ city: 1, price: 1 });

// Index composés pour les recherches et tris les plus courants
residenceSchema.index({ featured: -1, price: 1 }); // Pour les résidences en vedette
residenceSchema.index({ createdAt: -1 }); // Pour les résidences récentes
residenceSchema.index({ rating: -1 }); // Pour les meilleures notes

// Index pour les recherches par propriétaire
residenceSchema.index({ owner: 1 });

// Index texte pour la recherche full-text
residenceSchema.index({ title: 'text', description: 'text' }, {
  weights: {
    title: 10,
    description: 5
  },
  name: 'residence_text_index'
});

// Index pour améliorer les performances des recherches par type et capacité
residenceSchema.index({ type: 1, capacity: 1 });

const Residence = mongoose.model('Residence', residenceSchema);
module.exports = Residence;
