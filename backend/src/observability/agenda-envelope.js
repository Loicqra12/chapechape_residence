/**
 * P2-04 Lot 1 — enveloppe Agenda unique (observabilité uniquement).
 * N’altère ni scheduling, ni retries métier, ni handlers de jobs.
 */

const logger = require('../utils/logger');

const JOB_DATA_WHITELIST = Object.freeze([
  'reservationId',
  'paymentId',
  'payoutId',
  'residenceId',
  'messageId',
  'userId',
  'partnerId',
  'recipientId',
  'stage',
]);

const startTimes = new Map();

function pickWhitelistedData(data) {
  if (!data || typeof data !== 'object') return {};
  const out = {};
  for (const key of JOB_DATA_WHITELIST) {
    if (data[key] != null && data[key] !== '') {
      out[key] = data[key];
    }
  }
  return out;
}

function jobKey(job) {
  const id = job?.attrs?._id;
  if (id != null) return String(id);
  return null;
}

function buildJobMeta(job, extra = {}) {
  const attrs = job?.attrs || {};
  const meta = {
    jobName: attrs.name,
    jobId: jobKey(job) || undefined,
    timestamp: new Date().toISOString(),
    ...pickWhitelistedData(attrs.data),
    ...extra,
  };
  if (typeof attrs.failCount === 'number') {
    meta.failCount = attrs.failCount;
  }
  return meta;
}

function durationMsFor(job) {
  const key = jobKey(job);
  if (!key || !startTimes.has(key)) return undefined;
  const started = startTimes.get(key);
  startTimes.delete(key);
  return Date.now() - started;
}

/**
 * Attache une seule fois les hooks start/success/fail.
 * AGENDA_JOB_RETRY uniquement si failCount > 0 (retry Agenda observable).
 */
function attachAgendaEnvelope(agenda) {
  if (!agenda || typeof agenda.on !== 'function') {
    return false;
  }
  if (agenda.__chapechapeAgendaEnvelopeAttached) {
    return false;
  }
  agenda.__chapechapeAgendaEnvelopeAttached = true;

  agenda.on('start', (job) => {
    const key = jobKey(job);
    if (key) startTimes.set(key, Date.now());

    const failCount = job?.attrs?.failCount || 0;
    logger.info('AGENDA_JOB_STARTED', buildJobMeta(job, { event: 'AGENDA_JOB_STARTED' }));

    if (failCount > 0) {
      logger.warn(
        'AGENDA_JOB_RETRY',
        buildJobMeta(job, {
          event: 'AGENDA_JOB_RETRY',
          attempt: failCount,
        })
      );
    }
  });

  agenda.on('success', (job) => {
    logger.info(
      'AGENDA_JOB_COMPLETED',
      buildJobMeta(job, {
        event: 'AGENDA_JOB_COMPLETED',
        durationMs: durationMsFor(job),
      })
    );
  });

  agenda.on('fail', (err, job) => {
    logger.error(
      'AGENDA_JOB_FAILED',
      buildJobMeta(job, {
        event: 'AGENDA_JOB_FAILED',
        durationMs: durationMsFor(job),
        err: err && err.message ? err.message : String(err || 'unknown'),
      })
    );
  });

  return true;
}

module.exports = {
  JOB_DATA_WHITELIST,
  pickWhitelistedData,
  buildJobMeta,
  attachAgendaEnvelope,
};
