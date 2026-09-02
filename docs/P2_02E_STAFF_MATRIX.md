# P2-02E — Matrice staff admin vs superadmin

Autorité runtime : **`User.role`**. Les collections `Role` / `Permission` sont un CRUD superadmin **non consulté** par `protect` / `authorize` / `isAdmin`. Un document RBAC ne protège aucune action HTTP aujourd’hui.

Politique : `authorize('admin')` et `isAdmin` = contexte **staff** (admin **et** superadmin). Les mutations staff/config restent derrière `isSuperAdmin` / `authorize` **sans** `admin`. Superadmin n’est **pas** ajouté aux routes `partner` only.

## Capabilities

**Admin (exploitation)** : dashboard, inspection users/partners/residences (lecture + modération listing), P1-07 Ops (reservations, refunds, inventory, anomalies, OpsAuditLog GET), stats, paiements liste, SMS métier dérivé, payouts staff déjà `authorize('admin')`.

**Superadmin (plateforme)** : création/suppression/désactivation admins, mutation `User.role`, CRUD Role/Permission, `/api/superadmin/settings`, maintenance, IPs bloquées, logs globaux, login-attempts.

**Self / dernier superadmin** : interdiction de delete, disable (`isActive: false`) ou downgrade si `count(role=superadmin, isActive≠false) <= 1`. Un superadmin peut se rétrograder **seulement** s’il reste un autre superadmin actif.

## Matrice

| Route/action | admin | superadmin | justification |
|---|---|---|---|
| GET /api/admin/ops/reservations[:id] | ✅ | ✅ staff | exploitation P1-07 |
| POST /api/admin/ops/reservations/:id/cancel\|checkin\|checkout | ✅ | ✅ | exploitation |
| GET/POST /api/admin/ops/refunds | ✅ | ✅ | finance Ops |
| GET /api/admin/ops/inventory/:residenceId | ✅ | ✅ | inventory Ops |
| GET /api/admin/ops/anomalies\|audit | ✅ | ✅ | inspection |
| GET /api/admin/dashboard, payments, stats, activity-logs | ✅ | ✅ | inspection |
| GET /api/admin/users, partners, residences, pending, validate/reject/verify | ✅ | ✅ | modération |
| PUT /api/admin/users/:id (profil, **pas role**) | ✅ | ✅ | role strippé |
| DELETE /api/admin/users/:id (non-staff) | ✅ | ✅ | staff → 403 dédié |
| GET /api/admin/admins/:id | ✅ | ✅ | inspection staff |
| POST /api/admin/admins | ❌ | ✅ | création admins |
| PUT/DELETE /api/admin/admins/:id | ❌ | ✅ | mutation/suppression staff |
| GET/POST/PUT/DELETE /api/admin/roles, /permissions | ❌ | ✅ | RBAC catalogue |
| GET /api/dashboard/* | ✅ | ✅ staff | inspection |
| GET/PUT /api/superadmin/settings | ❌ | ✅ | config critique |
| POST /api/superadmin/users/:id/role | ❌ | ✅ | mutation rôle |
| CRUD /api/superadmin/admins | ❌ | ✅ | staff management |
| GET /api/superadmin/clients\|partners | ❌ | ✅ | export global |
| activity-logs, login-attempts, blocked-ips | ❌ | ✅ | sécurité globale |
| DELETE activity-logs / login-attempts | ❌ | ✅ | destructive |
| /api/maintenance/* (sauf GET /mode public) | ❌ | ✅ | config plateforme |
| authorize('admin') payouts Wave batch/reverse | ✅ | ✅ héritage staff | finance Ops |
| SMS /send authorize('admin') | ✅ | ✅ staff | comms staff |
| GET /api/reviews (liste globale) | ✅ | ✅ staff | inspection |
| Partner dashboard / product routes | ❌ | ❌ | pas un joker métier |
| /register, /profile, bulk user | ❌ | ❌ | pas de rôle |

Settings whitelist (PUT) : `maintenance.enabled`, `maintenance.banner`, `notification.emailEnabled`, `booking.autoConfirmHours`, `security.passwordMinLength`, `security.sessionMaxHours`, `payment.commissionRate`, `payment.providersEnabled`. Toute autre clé → 400.

## RBAC réel vs cosmétique

| Mécanisme | Utilisé à l’auth HTTP ? |
|---|---|
| `User.role` | **oui** (autorité) |
| `Role` / `Permission` Mongo | **non** (CRUD superadmin only, future) |
| `pickUserSafePatch` | oui (bloque role/password) |

## Audit

`OpsAuditLog` append-only, actions P2-02E : `admin_created`, `admin_disabled`, `admin_deleted`, `role_changed`, `permissions_changed`, `settings_changed` (+ actions P1-07 inchangées).
