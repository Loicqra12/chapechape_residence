const mongoose = require('mongoose');

/**
 * P1-07 — piste d'audit des actions Ops Admin.
 * Append-only : aucune route de mutation, hooks de mise à jour refusés.
 * Distinct de ActivityLog (enum historique strict).
 */
const opsAuditLogSchema = new mongoose.Schema({
  actor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true,
  },
  actorRole: {
    type: String,
    default: 'unknown',
  },
  action: {
    type: String,
    required: true,
    enum: [
      'cancel',
      'checkin',
      'checkout',
      'refund_confirm',
      'admin_created',
      'admin_disabled',
      'admin_deleted',
      'role_changed',
      'permissions_changed',
      'settings_changed',
    ],
    index: true,
  },
  entityType: {
    type: String,
    required: true,
    enum: ['reservation', 'payment', 'user', 'setting', 'role'],
  },
  entityId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    index: true,
  },
  reason: {
    type: String,
    default: '',
  },
  before: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  after: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  metadata: {
    type: mongoose.Schema.Types.Mixed,
    default: {},
  },
  correlationId: {
    type: String,
    index: true,
  },
  requestId: {
    type: String,
    index: true,
  },
}, {
  timestamps: { createdAt: true, updatedAt: false },
});

opsAuditLogSchema.index({ createdAt: -1 });
opsAuditLogSchema.index({ entityType: 1, entityId: 1, createdAt: -1 });

function rejectMutation() {
  throw new Error('OpsAuditLog is immutable');
}

opsAuditLogSchema.pre('save', function rejectSaveIfNotNew(next) {
  if (!this.isNew) {
    return next(new Error('OpsAuditLog is immutable'));
  }
  next();
});

for (const hook of ['updateOne', 'updateMany', 'findOneAndUpdate', 'findOneAndReplace', 'replaceOne']) {
  opsAuditLogSchema.pre(hook, rejectMutation);
}

module.exports = mongoose.model('OpsAuditLog', opsAuditLogSchema);
