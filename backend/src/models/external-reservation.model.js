const mongoose = require('mongoose');

const CHANNELS = [
  'phone',
  'whatsapp',
  'walk_in',
  'other_platform',
  'airbnb',
  'booking_com',
  'other',
];

const STATUSES = ['active', 'cancelled', 'completed'];

/**
 * Réservation hors ChapeChape. Occupe l'inventaire, ne crée jamais Payment/Payout.
 * PII (guestName, guestPhone, notes) : Partner/Admin seulement — jamais dans les APIs publiques.
 */
const externalReservationSchema = new mongoose.Schema({
  residence: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Residence',
    required: true,
    index: true,
  },
  partner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  checkIn: { type: Date, required: true },
  checkOut: { type: Date, required: true },
  bookingType: {
    type: String,
    enum: ['hour', 'day', 'week', 'month'],
    default: 'day',
  },
  channel: {
    type: String,
    enum: CHANNELS,
    default: 'other',
  },
  guestName: { type: String, maxlength: 120, default: '' },
  guestPhone: { type: String, maxlength: 40, default: '' },
  externalReference: { type: String, maxlength: 120, default: '' },
  notes: { type: String, maxlength: 500, default: '' },
  status: {
    type: String,
    enum: STATUSES,
    default: 'active',
    index: true,
  },
  actualCheckOut: { type: Date, default: null },
  sourceType: {
    type: String,
    enum: ['external_reservation'],
    default: 'external_reservation',
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  cancelledAt: { type: Date, default: null },
  cancelledBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
  completedAt: { type: Date, default: null },
}, { timestamps: true });

externalReservationSchema.index({ residence: 1, status: 1, checkIn: 1, checkOut: 1 });

externalReservationSchema.pre('validate', function (next) {
  if (this.checkOut <= this.checkIn) {
    return next(new Error('Le check-out doit être postérieur au check-in'));
  }
  next();
});

function toPublicOccupation(doc) {
  if (!doc) return null;
  const plain = typeof doc.toObject === 'function' ? doc.toObject() : doc;
  return {
    id: String(plain._id),
    residence: plain.residence,
    checkIn: plain.checkIn,
    checkOut: plain.checkOut,
    bookingType: plain.bookingType,
    status: plain.status,
    sourceType: 'external_reservation',
  };
}

function toPartnerView(doc) {
  if (!doc) return null;
  return typeof doc.toObject === 'function' ? doc.toObject() : doc;
}

module.exports = mongoose.model('ExternalReservation', externalReservationSchema);
module.exports.CHANNELS = CHANNELS;
module.exports.STATUSES = STATUSES;
module.exports.toPublicOccupation = toPublicOccupation;
module.exports.toPartnerView = toPartnerView;
