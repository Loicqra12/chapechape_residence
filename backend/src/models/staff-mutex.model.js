const mongoose = require('mongoose');

/**
 * Document de lock staff (dernier superadmin).
 * `_id` + `key` unique : un seul verrou `superadmin-guard`.
 * Utilisé dans une transaction Mongo — pas un droit métier.
 */
const staffMutexSchema = new mongoose.Schema(
  {
    key: {
      type: String,
      required: true,
    },
    seq: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

staffMutexSchema.index({ key: 1 }, { unique: true });

module.exports = mongoose.model('StaffMutex', staffMutexSchema);
