const crypto = require('crypto');

/**
 * Secret webhook Wave pour les transferts / payouts sortants.
 * Priorité : secret dédié payout, puis signing secret (souvent le même dans le dashboard Wave).
 * WAVE_WEBHOOK_SECRET est réservé au checkout ; ne pas le mélanger avec les payouts.
 */
function getWavePayoutWebhookSecret() {
  return (
    process.env.WAVE_PAYOUT_WEBHOOK_SECRET ||
    process.env.WAVE_SIGNING_SECRET ||
    null
  );
}

/**
 * Secret webhook Wave pour les paiements checkout entrants.
 */
function getWavePaymentWebhookSecret() {
  return process.env.WAVE_SIGNING_SECRET || process.env.WAVE_WEBHOOK_SECRET || null;
}

/**
 * Normalise le header Wave-Signature (hex brut, sha256=..., ou format t=...,v1=...).
 */
function normalizeWaveSignatureHeader(headerValue) {
  if (!headerValue || typeof headerValue !== 'string') {
    return null;
  }

  let sig = headerValue.trim();

  const v1Match = sig.match(/v1=([a-fA-F0-9]+)/);
  if (v1Match) {
    return v1Match[1].toLowerCase();
  }

  if (sig.startsWith('sha256=')) {
    sig = sig.slice(7);
  }

  return sig.trim().toLowerCase();
}

/**
 * Vérifie HMAC-SHA256 du corps brut (Buffer) contre le secret Wave.
 */
function verifyWaveWebhookHmac(rawBody, signatureHeader, secret) {
  if (!secret || !signatureHeader || !Buffer.isBuffer(rawBody)) {
    return false;
  }

  const provided = normalizeWaveSignatureHeader(signatureHeader);
  if (!provided || !/^[a-f0-9]+$/.test(provided)) {
    return false;
  }

  const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');

  try {
    const sigBuf = Buffer.from(provided, 'utf8');
    const calcBuf = Buffer.from(expected, 'utf8');
    if (sigBuf.length !== calcBuf.length) {
      return false;
    }
    return crypto.timingSafeEqual(sigBuf, calcBuf);
  } catch {
    return false;
  }
}

module.exports = {
  getWavePayoutWebhookSecret,
  getWavePaymentWebhookSecret,
  normalizeWaveSignatureHeader,
  verifyWaveWebhookHmac,
};
