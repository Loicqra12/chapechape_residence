const mongoose = require('mongoose');

/**
 * Mutex d'inventaire par résidence + jour calendaire.
 * Sert à sérialiser les creates/modifies concurrents (hour et day)
 * à l'intérieur d'une transaction Mongo — pas un inventaire métier.
 */
const inventoryLockSchema = new mongoose.Schema(
  {
    key: {
      type: String,
      required: true,
    },
    acquiredAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

inventoryLockSchema.index({ key: 1 }, { unique: true });

module.exports = mongoose.model('InventoryLock', inventoryLockSchema);
