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
      'wifi', 'parking', 'pool', 'gym', 'security',
      'air_conditioning', 'heating', 'kitchen', 'tv',
      'washing_machine', 'dryer'
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
  return Availability.checkAvailability(this._id, startDate, endDate);
};

residenceSchema.methods.calculateTotalPrice = async function(startDate, endDate) {
  const Availability = mongoose.model('Availability');
  return Availability.calculateTotalPrice(this._id, startDate, endDate);
};

const Residence = mongoose.model('Residence', residenceSchema);
module.exports = Residence;
