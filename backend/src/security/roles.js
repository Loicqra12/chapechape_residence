/**
 * P2-02 — rôles canoniques et politique d’autorisation.
 *
 * superadmin n’est PAS un joker implicite : il n’est autorisé que si la
 * route accepte `admin` (staff) ou liste `superadmin` explicitement.
 *
 * Partner : role=partner dès l’inscription (accès produit).
 * partner_pending : alias legacy du rôle produit, pas un état KYC.
 * Les gates financières / publication = capabilities, pas le rôle.
 */

const ROLES = Object.freeze({
  CLIENT: 'client',
  PARTNER_PENDING: 'partner_pending',
  PARTNER: 'partner',
  ADMIN: 'admin',
  SUPERADMIN: 'superadmin',
  OWNER: 'owner',
});

const STAFF_ROLES = Object.freeze([ROLES.ADMIN, ROLES.SUPERADMIN]);
const PARTNER_ACCOUNT_ROLES = Object.freeze([ROLES.PARTNER, ROLES.PARTNER_PENDING]);

const SENSITIVE_USER_FIELDS = Object.freeze([
  'role',
  'password',
  'passwordChangedAt',
  'resetPasswordToken',
  'resetPasswordExpire',
  'verificationToken',
  'verificationTokenExpire',
  'isPhoneVerified',
  'isVerified',
  'verification',
  'capabilities',
]);

function isStaff(role) {
  return STAFF_ROLES.includes(role);
}

function isValidatedPartner(role) {
  return role === ROLES.PARTNER || role === ROLES.PARTNER_PENDING;
}

function isPartnerAccount(role) {
  return PARTNER_ACCOUNT_ROLES.includes(role);
}

/**
 * Patch utilisateur : jamais de role/password via mass assignment.
 * isActive : superadmin seulement (désactivation de compte).
 */
function pickUserSafePatch(body, { allowActive = false } = {}) {
  const src = body && typeof body === 'object' ? { ...body } : {};
  for (const field of SENSITIVE_USER_FIELDS) {
    delete src[field];
  }
  if (!allowActive) {
    delete src.isActive;
  }
  return src;
}

module.exports = {
  ROLES,
  STAFF_ROLES,
  PARTNER_ACCOUNT_ROLES,
  SENSITIVE_USER_FIELDS,
  isStaff,
  isValidatedPartner,
  isPartnerAccount,
  pickUserSafePatch,
};
