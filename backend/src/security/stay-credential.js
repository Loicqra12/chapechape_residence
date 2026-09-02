/**
 * P2-05C2 — Stay credential crypto (opaque bearer).
 *
 * Canonical representation hashed:
 *   full credential string "CCSTAY1.<base64url(32 bytes)>"
 * Hash:
 *   SHA-256(utf8(credential)) → hex digest
 * Raw token is never persisted.
 */
const crypto = require('crypto');

const VERSION_PREFIX = 'CCSTAY1';
const ENTROPY_BYTES = 32;
const TTL_MS = 10 * 60 * 1000;
const CREDENTIAL_RE = /^CCSTAY1\.([A-Za-z0-9_-]+)$/;

const PURPOSE = Object.freeze({
  CHECKIN: 'checkin',
  CHECKOUT: 'checkout',
});

function purposeToSlot(purpose) {
  if (purpose === PURPOSE.CHECKIN) return 'checkIn';
  if (purpose === PURPOSE.CHECKOUT) return 'checkOut';
  return null;
}

function toBase64Url(buf) {
  return Buffer.from(buf)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/g, '');
}

function fromBase64Url(str) {
  const pad = str.length % 4 === 0 ? '' : '='.repeat(4 - (str.length % 4));
  const b64 = str.replace(/-/g, '+').replace(/_/g, '/') + pad;
  return Buffer.from(b64, 'base64');
}

/** SHA-256 of the full canonical credential string. */
function hashCredential(credential) {
  return crypto.createHash('sha256').update(String(credential), 'utf8').digest('hex');
}

function generateCredential() {
  const raw = crypto.randomBytes(ENTROPY_BYTES);
  const body = toBase64Url(raw);
  const credential = `${VERSION_PREFIX}.${body}`;
  return {
    credential,
    tokenHash: hashCredential(credential),
  };
}

/**
 * Parse + validate format. Does not touch DB.
 * @returns {{ credential: string, tokenHash: string }}
 */
function parseCredential(input) {
  if (input == null || typeof input !== 'string') {
    return null;
  }
  const trimmed = input.trim();
  const match = CREDENTIAL_RE.exec(trimmed);
  if (!match) return null;
  let bytes;
  try {
    bytes = fromBase64Url(match[1]);
  } catch {
    return null;
  }
  if (!bytes || bytes.length !== ENTROPY_BYTES) return null;
  return {
    credential: trimmed,
    tokenHash: hashCredential(trimmed),
  };
}

/** valid iff now < expiresAt ; expired iff now >= expiresAt */
function isCredentialExpired(expiresAt, now = new Date()) {
  if (!expiresAt) return true;
  return now.getTime() >= new Date(expiresAt).getTime();
}

function isCredentialActive(slot, now = new Date()) {
  if (!slot || !slot.tokenHash) return false;
  if (slot.consumedAt) return false;
  if (isCredentialExpired(slot.expiresAt, now)) return false;
  return true;
}

function checkInWindowOpen(checkIn, now = new Date()) {
  const checkInTime = new Date(checkIn);
  const twoHoursBefore = new Date(checkInTime.getTime() - 2 * 60 * 60 * 1000);
  return now.getTime() >= twoHoursBefore.getTime();
}

module.exports = {
  VERSION_PREFIX,
  ENTROPY_BYTES,
  TTL_MS,
  PURPOSE,
  purposeToSlot,
  generateCredential,
  hashCredential,
  parseCredential,
  isCredentialExpired,
  isCredentialActive,
  checkInWindowOpen,
};
