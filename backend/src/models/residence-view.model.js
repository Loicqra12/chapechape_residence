const mongoose = require('mongoose');

/**
 * Vues de résidences par client authentifié — pour relances "recherche abandonnée".
 */
const residenceViewSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    residence: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Residence',
      required: true,
      index: true,
    },
    viewedAt: {
      type: Date,
      default: Date.now,
      index: true,
    },
    reminderScheduledAt: Date,
    remindedAt: Date,
  },
  { timestamps: true }
);

residenceViewSchema.index({ user: 1, residence: 1 }, { unique: true });

module.exports = mongoose.model('ResidenceView', residenceViewSchema);
