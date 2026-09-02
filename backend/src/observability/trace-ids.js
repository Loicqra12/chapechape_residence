const { randomUUID } = require('crypto');

const TRACE_ID_RE = /^[A-Za-z0-9._-]{8,128}$/;

function firstHeaderValue(raw) {
  if (raw == null) return null;
  if (Array.isArray(raw)) return raw[0];
  return raw;
}

function parseBoundedTraceId(raw) {
  const value = firstHeaderValue(raw);
  if (typeof value !== 'string') return null;
  const trimmed = value.trim();
  if (!TRACE_ID_RE.test(trimmed)) return null;
  return trimmed;
}

function resolveRequestId(headerValue) {
  return parseBoundedTraceId(headerValue) || randomUUID();
}

function resolveCorrelationId(headerValue) {
  return parseBoundedTraceId(headerValue);
}

module.exports = {
  TRACE_ID_RE,
  parseBoundedTraceId,
  resolveRequestId,
  resolveCorrelationId,
};
