const mongoose = require('mongoose');

/**
 * Idempotence des webhooks PSP (éviter double traitement).
 */
const webhookEventSchema = new mongoose.Schema(
  {
    provider: { type: String, required: true, index: true },
    eventId: { type: String, required: true },
    payloadHash: { type: String },
    processedAt: { type: Date, default: Date.now },
  },
  { timestamps: true }
);

webhookEventSchema.index({ provider: 1, eventId: 1 }, { unique: true });

module.exports = mongoose.model('WebhookEvent', webhookEventSchema);
