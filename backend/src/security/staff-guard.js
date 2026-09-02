const mongoose = require('mongoose');
const User = require('../models/user.model');
const StaffMutex = require('../models/staff-mutex.model');
const { ROLES, isStaff, pickUserSafePatch } = require('./roles');
const ApiError = require('../utils/apiError');

const SUPERADMIN_MUTEX_KEY = 'superadmin-guard';

const MUTABLE_ROLES = Object.freeze([
  ROLES.CLIENT,
  ROLES.PARTNER,
  ROLES.PARTNER_PENDING,
  ROLES.ADMIN,
  ROLES.SUPERADMIN,
]);

/** Clés settings mutables via PUT /superadmin/settings — pas d’upsert libre. */
const SETTINGS_WHITELIST = Object.freeze({
  'maintenance.enabled': { category: 'maintenance', type: 'boolean' },
  'maintenance.banner': { category: 'maintenance', type: 'string' },
  'notification.emailEnabled': { category: 'notification', type: 'boolean' },
  'booking.autoConfirmHours': { category: 'booking', type: 'number' },
  'security.passwordMinLength': { category: 'security', type: 'number' },
  'security.sessionMaxHours': { category: 'security', type: 'number' },
  'payment.commissionRate': { category: 'payment', type: 'number' },
  'payment.providersEnabled': { category: 'payment', type: 'json' },
});

function pickAdminCreateFields(body = {}) {
  return {
    email: body.email,
    password: body.password,
    firstName: body.firstName,
    lastName: body.lastName,
    phoneNumber: body.phoneNumber,
    role: ROLES.ADMIN,
  };
}

function pickSettingsPatch(body = {}) {
  const src = body && typeof body === 'object' && !Array.isArray(body) ? body : {};
  const nested = src.settings && typeof src.settings === 'object' ? src.settings : src;
  const allowed = {};
  const rejected = [];
  for (const [key, value] of Object.entries(nested)) {
    if (key === 'settings' || key === 'reason') continue;
    if (SETTINGS_WHITELIST[key]) {
      allowed[key] = value;
    } else {
      rejected.push(key);
    }
  }
  return { allowed, rejected };
}

async function countActiveSuperadmins(session) {
  const q = User.countDocuments({
    role: ROLES.SUPERADMIN,
    isActive: { $ne: false },
  });
  if (session) q.session(session);
  return q;
}

async function withSuperadminMutex(work) {
  await StaffMutex.updateOne(
    { key: SUPERADMIN_MUTEX_KEY },
    { $setOnInsert: { key: SUPERADMIN_MUTEX_KEY, seq: 0 } },
    { upsert: true }
  );

  const session = await mongoose.startSession();
  try {
    let result;
    await session.withTransaction(async () => {
      await StaffMutex.findOneAndUpdate(
        { key: SUPERADMIN_MUTEX_KEY },
        { $inc: { seq: 1 } },
        { session, upsert: true }
      );
      result = await work(session);
    });
    return result;
  } finally {
    await session.endSession();
  }
}

/**
 * Empêche de retirer le dernier superadmin actif (delete, disable, downgrade).
 * Doit être appelé dans withSuperadminMutex avec la même session que la mutation.
 */
async function assertCanRevokeSuperadmin(target, session) {
  if (!target || target.role !== ROLES.SUPERADMIN) return;
  if (target.isActive === false) return;
  const remaining = await countActiveSuperadmins(session);
  if (remaining <= 1) {
    throw new ApiError(
      'Impossible de supprimer, désactiver ou rétrograder le dernier Superadmin actif',
      403
    );
  }
}

function assertValidRole(role) {
  if (!MUTABLE_ROLES.includes(role)) {
    throw new ApiError('Rôle cible invalide', 400);
  }
}

module.exports = {
  MUTABLE_ROLES,
  SETTINGS_WHITELIST,
  pickAdminCreateFields,
  pickSettingsPatch,
  pickUserSafePatch,
  isStaff,
  countActiveSuperadmins,
  withSuperadminMutex,
  assertCanRevokeSuperadmin,
  assertValidRole,
};
