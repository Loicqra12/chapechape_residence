const { resolveRequestId, resolveCorrelationId } = require('../observability/trace-ids');
const { runWithRequestContext } = require('../observability/request-context');

function requestIdMiddleware(req, res, next) {
  const requestId = resolveRequestId(req.headers['x-request-id']);
  const correlationId = resolveCorrelationId(req.headers['x-correlation-id']);

  req.id = requestId;
  req.requestId = requestId;
  req.correlationId = correlationId || undefined;

  res.setHeader('X-Request-Id', requestId);
  if (correlationId) {
    res.setHeader('X-Correlation-Id', correlationId);
  }

  const ctx = { requestId };
  if (correlationId) ctx.correlationId = correlationId;

  runWithRequestContext(ctx, () => next());
}

module.exports = {
  requestIdMiddleware,
};
