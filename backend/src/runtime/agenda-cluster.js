/**
 * P2-01 — PM2 cluster : un seul worker enregistre les jobs `every`.
 * Tous les workers exécutent les jobs (locks Agenda Mongo).
 */
function isPrimaryScheduler() {
  const inst = process.env.NODE_APP_INSTANCE;
  if (inst === undefined || inst === null || inst === '') return true;
  return String(inst) === '0';
}

function workerLabel() {
  const inst = process.env.NODE_APP_INSTANCE;
  if (inst === undefined || inst === null || inst === '') return 'single';
  return `pm2:${inst}`;
}

const MAX_UNIQUE_SAVE_ATTEMPTS = 3;

function isDuplicateKeyError(err) {
  return err && (err.code === 11000 || err.code === 11001);
}

/**
 * Un seul job Agenda par clé métier (expire / refund / host approval / arrival reminder).
 * Garantie finale arrival reminder : index Mongo partiel unique (P2-07C).
 * E11000 concurrent → retry borné (upsert/update sur document existant).
 */
async function saveUniqueScheduledJob(agenda, name, when, data, uniqueField) {
  const payload = data && typeof data === 'object' ? { ...data } : {};
  const uniqueValue = String(payload[uniqueField] || '');
  const uniqueQuery = { name, [`data.${uniqueField}`]: uniqueValue };

  let lastError;
  for (let attempt = 1; attempt <= MAX_UNIQUE_SAVE_ATTEMPTS; attempt++) {
    try {
      const job = agenda.create(name, payload);
      job.unique(uniqueQuery);
      if (when === 'now' || when == null) {
        job.schedule(new Date());
      } else {
        job.schedule(when);
      }
      return await job.save();
    } catch (err) {
      lastError = err;
      if (isDuplicateKeyError(err) && attempt < MAX_UNIQUE_SAVE_ATTEMPTS) {
        continue;
      }
      throw err;
    }
  }
  throw lastError;
}

const FINANCIAL_JOB_OPTIONS = Object.freeze({
  concurrency: 1,
  lockLimit: 1,
  lockLifetime: 10 * 60 * 1000,
});

module.exports = {
  isPrimaryScheduler,
  workerLabel,
  saveUniqueScheduledJob,
  FINANCIAL_JOB_OPTIONS,
  MAX_UNIQUE_SAVE_ATTEMPTS,
  isDuplicateKeyError,
};
