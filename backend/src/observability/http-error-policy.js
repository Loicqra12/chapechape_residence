/**
 * Politique P2-04 : HTTP 4xx attendu ≠ ERROR technique ≠ Sentry.
 * Classification par status / codes déjà présents (ApiError, Mongoose, JWT).
 */

function resolveHttpStatus(err) {
  if (!err) return 500;
  if (typeof err.statusCode === 'number') return err.statusCode;
  if (typeof err.status === 'number') return err.status;

  if (err.name === 'ValidationError' || err.name === 'CastError') return 400;
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') return 401;
  if (err.code === 11000) return 409;
  if (err.code === 'LIMIT_FILE_SIZE' || err.code === 'LIMIT_UNEXPECTED_FILE') return 400;

  const msg = err.message || '';
  if (
    msg.includes('Invalid state transition') ||
    msg.includes('Transition vers') ||
    msg.includes('Échec de la transition atomique')
  ) {
    return 409;
  }

  return 500;
}

function logLevelForError(err) {
  const status = resolveHttpStatus(err);
  if (status === 409) return 'info';
  if (status >= 400 && status < 500) return 'warn';
  return 'error';
}

function shouldCaptureSentry(err) {
  return resolveHttpStatus(err) >= 500;
}

module.exports = {
  resolveHttpStatus,
  logLevelForError,
  shouldCaptureSentry,
};
