const mongoose = require('mongoose');

const verificationCodeSchema = new mongoose.Schema({
  code: {
    type: String,
    required: [true, 'Code de vérification requis']
  },
  phoneNumber: {
    type: String,
    required: [true, 'Numéro de téléphone requis'],
    trim: true
  },
  codeId: {
    type: String,
    required: [true, 'ID unique du code requis'],
    unique: true
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  attempts: {
    type: Number,
    default: 0
  },
  expiresAt: {
    type: Date,
    required: [true, 'Date d\'expiration requise']
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: { expires: '1h' } // Auto-suppression après 1 heure
  }
});

// Méthode pour vérifier si le code est expiré
verificationCodeSchema.methods.isExpired = function() {
  return new Date() > this.expiresAt;
};

// Suppression périodique des codes expirés (au cas où l'index TTL échoue)
verificationCodeSchema.statics.cleanupExpiredCodes = async function() {
  return this.deleteMany({ expiresAt: { $lt: new Date() } });
};

module.exports = mongoose.model('VerificationCode', verificationCodeSchema);
