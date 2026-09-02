const OpsAuditLog = require('../models/ops-audit-log.model');

/**
 * Audit append-only des actions staff (P2-02E).
 * Réutilise OpsAuditLog (immuable) avec actions étendues.
 */
async function logStaffAction({
  actor,
  action,
  entityType,
  entityId,
  reason = '',
  before = {},
  after = {},
  req,
}) {
  if (!actor || !entityId) return null;
  return OpsAuditLog.create({
    actor: actor._id || actor.id,
    actorRole: actor.role || 'unknown',
    action,
    entityType,
    entityId,
    reason: String(reason || '').slice(0, 500),
    before,
    after,
    metadata: {},
    requestId: req?.id || req?.headers?.['x-request-id'] || undefined,
    correlationId: req?.headers?.['x-correlation-id'] || undefined,
  });
}

module.exports = { logStaffAction };
