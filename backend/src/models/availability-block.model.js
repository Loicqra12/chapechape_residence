const mongoose = require('mongoose');

const BLOCK_TYPES = [
  'personal_use',
  'maintenance',
  'cleaning',
  'renovation',
  'administrative',
  'other',
];

/**
 * Occupation d'inventaire Partner (hors Reservation ChapeChape).
 * external_booking n'est PAS un type ici — P1-03 ExternalReservation.
 */
const availabilityBlockSchema = new mongoose.Schema({
  residence: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Residence',
    required: true,
    index: true,
  },
  start: { type: Date, required: true },
  end: { type: Date, required: true },
  bookingType: {
    type: String,
    enum: ['hour', 'day', 'week', 'month'],
    default: 'day',
  },
  type: {
    type: String,
    enum: BLOCK_TYPES,
    default: 'other',
  },
  reason: {
    type: String,
    maxlength: 500,
    default: '',
  },
  status: {
    type: String,
    enum: ['active', 'released'],
    default: 'active',
    index: true,
  },
  sourceType: {
    type: String,
    enum: ['manual_block'],
    default: 'manual_block',
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  releasedAt: { type: Date, default: null },
  releasedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
}, { timestamps: true });

availabilityBlockSchema.index({ residence: 1, status: 1, start: 1, end: 1 });

availabilityBlockSchema.pre('validate', function (next) {
  if (this.end <= this.start) {
    return next(new Error('La fin du bloc doit être postérieure au début'));
  }
  next();
});

module.exports = mongoose.model('AvailabilityBlock', availabilityBlockSchema);
module.exports.BLOCK_TYPES = BLOCK_TYPES;
