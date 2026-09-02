/**
 * P2-01 — readiness process-local.
 * /health = process vivant. /ready = dépendances critiques.
 */
let ready = false;
let shuttingDown = false;
let agendaStarted = false;

function markReady() {
  ready = true;
}

function markNotReady() {
  ready = false;
}

function beginShutdown() {
  shuttingDown = true;
  ready = false;
}

function isShuttingDown() {
  return shuttingDown;
}

function isReady() {
  return ready && !shuttingDown;
}

function markAgendaStarted(value = true) {
  agendaStarted = Boolean(value);
}

function isAgendaStarted() {
  return agendaStarted;
}

function resetForTests() {
  ready = false;
  shuttingDown = false;
  agendaStarted = false;
}

module.exports = {
  markReady,
  markNotReady,
  beginShutdown,
  isShuttingDown,
  isReady,
  markAgendaStarted,
  isAgendaStarted,
  resetForTests,
};
