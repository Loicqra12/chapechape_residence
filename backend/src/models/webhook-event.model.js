const mongoose = require('mongoose');

/**
 * Idempotence des webhooks PSP.
 * status: processing → completed | failed
 * Un événement failed peut être retraité ; completed ne l'est jamais.
 */
const webhookEventSchema = new mongoose.Schema(
  {
    provider: { type: String, required: true, index: true },
    eventId: { type: String, required: true },
    payloadHash: { type: String },
    status: {
      type: String,
      enum: ['processing', 'completed', 'failed'],
      default: 'processing',
      index: true,
    },
    lastError: { type: String },
    processedAt: { type: Date },
  },
  { timestamps: true }
);

webhookEventSchema.index({ provider: 1, eventId: 1 }, { unique: true });

module.exports = mongoose.model('WebhookEvent', webhookEventSchema);
