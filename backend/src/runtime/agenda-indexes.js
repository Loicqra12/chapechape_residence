/**
 * P2-07C — Contrat d'index Mongo pour l'unicité des rappels d'arrivée Agenda.
 * Ne crée PAS l'index au démarrage application — rollout Ops séparé.
 */

const AGENDA_JOBS_COLLECTION = 'agendaJobs';

const ARRIVAL_REMINDER_JOB_NAME = 'sendReservationReminder';

/** Index partiel : un seul document par (name, data.reservationId) pour les arrival reminders canoniques. */
const ARRIVAL_REMINDER_UNIQUE_INDEX = Object.freeze({
  name: 'agenda_arrival_reminder_reservation_unique',
  key: { name: 1, 'data.reservationId': 1 },
  unique: true,
  partialFilterExpression: {
    name: ARRIVAL_REMINDER_JOB_NAME,
    'data.reservationId': { $exists: true, $type: 'string', $gt: '' },
  },
});

function classifyArrivalReminderIndex(indexes) {
  const expected = ARRIVAL_REMINDER_UNIQUE_INDEX;
  const byName = indexes.find((idx) => idx.name === expected.name);
  const byKey = indexes.find(
    (idx) =>
      idx.key
      && idx.key.name === 1
      && idx.key['data.reservationId'] === 1
      && Object.keys(idx.key).length === 2
  );

  if (!byName && !byKey) {
    return { status: 'MISSING', detail: 'index absent', index: null };
  }

  const idx = byName || byKey;
  const problems = [];

  if (!idx.unique) problems.push('not unique');
  if (idx.name !== expected.name) problems.push(`name=${idx.name}`);

  const pfe = idx.partialFilterExpression || {};
  if (pfe.name !== expected.partialFilterExpression.name) {
    problems.push('partialFilterExpression.name mismatch');
  }
  const ridFilter = pfe['data.reservationId'];
  if (
    !ridFilter
    || ridFilter.$type !== 'string'
    || ridFilter.$exists !== true
    || ridFilter.$gt !== ''
  ) {
    problems.push('partialFilterExpression.data.reservationId mismatch');
  }

  if (problems.length) {
    return { status: 'MISMATCH', detail: problems.join('; '), index: idx };
  }
  return { status: 'PRESENT', detail: 'partial unique', index: idx };
}

/**
 * Tests uniquement — simule le rollout Ops en environnement CI.
 */
async function ensureArrivalReminderUniqueIndexForTests(db) {
  if (process.env.NODE_ENV !== 'test') {
    throw new Error('ensureArrivalReminderUniqueIndexForTests: NODE_ENV=test requis');
  }
  const collection = db.collection(AGENDA_JOBS_COLLECTION);
  await collection.createIndex(ARRIVAL_REMINDER_UNIQUE_INDEX.key, {
    name: ARRIVAL_REMINDER_UNIQUE_INDEX.name,
    unique: ARRIVAL_REMINDER_UNIQUE_INDEX.unique,
    partialFilterExpression: ARRIVAL_REMINDER_UNIQUE_INDEX.partialFilterExpression,
  });
}

module.exports = {
  AGENDA_JOBS_COLLECTION,
  ARRIVAL_REMINDER_JOB_NAME,
  ARRIVAL_REMINDER_UNIQUE_INDEX,
  classifyArrivalReminderIndex,
  ensureArrivalReminderUniqueIndexForTests,
};
