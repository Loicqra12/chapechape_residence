# P2-03 — Audit des tests legacy

P1 et P2-02 restent **FROZEN**. Les contrats canoniques priment sur les attentes Jest anciennes.

Issue unique par fichier quarantiné :

`REPAIRED` | `REWRITTEN` | `DUPLICATE` | `OBSOLETE PRODUCT CONTRACT` | `PROVIDER_CONTRACT_OBSOLETE` | `NOT A JEST TEST`

## Métriques

| Vague | Supported suites | Supported tests | Quarantine | Skipped | Legacy failing | Deleted obsolete cumul. |
|---|---|---|---|---|---|---|
| Wave 1 | 16 | 221 pass | 28 | 1 | 28 | 0 |
| Wave 2 | 21 | 244 pass / 1 skip | 21 | 1 | 21 | 3 |
| Wave 3 | **24** | **263 pass / 1 skip** | **15** | 1 | **15** fail / **24** pass / **39** suites | **6** |
| Wave 4 | **25** | **280 pass / 1 skip** | **12** | 1 | **12** fail / **25** pass / **37** suites | **8** |
| Wave 5 | **29** | **298 pass / 1 skip** | **4** | 1 | **4** fail / **29** pass / **33** suites | **12** |
| Wave 6 | **29** | **299 pass / 1 skip** | **0** | 1 | **0** fail / **29** pass / **29** suites | **16** |

Garde : `WAVE_BASELINE === 0`. `SKIP_CEILING = 1`. Le plafond 28 reste un filet historique.

## Skips (`it.skip`)

| Fichier | Test | Raison | Réactivation |
|---|---|---|---|
| `unit/middleware/csrf.test.js` | CSRF valide sur POST /reservations | Fixture résidence + CSRF live incomplets ; **pas** un contrat 429/JWT | Factory CSRF + résidence `[start,end)` ; alors le 401 CSRF vs 400 métier est testable |

Pas d’autre `describe.skip` / `test.skip` dans `backend/tests`.

## Décisions + Removal condition

| Suite | Wave 2 | Catégorie | Décision | Remplacement | Removal condition |
|---|---|---|---|---|---|
| P0/P1/P2-02 `test:ci` | KEEP | F | Gate merge | — | Jamais retirer de `test:ci` sans gel produit |
| `loginAttempt.test.js` | KEEP | — | Vert | — | — |
| `p2-03-quarantine-guard.test.js` | KEEP | — | Garde volume quarantine | — | Quand quarantine = 0 |
| `security.test.js` | **REPAIRED** | B→actuel | 429 machine contract ; LoginAttempt audit ; pas d’auto-block IP | p2-02-rate-limit + ce fichier | Sorti quarantine |
| `auth.test.js` | **REPAIRED** | D | `src/app` + `token` racine + password policy actuelle | — | Sorti quarantine |
| `validations/auth.validation.test.js` | **REWRITTEN** | B | Login identifiant ≠ email RFC ; register firstName/lastName/phone ; pas de `role` public | — | Sorti quarantine |
| `unit/services/error.service.test.js` | **REWRITTEN** | C | BookingError retiré des tests | ApiError + sanitize auth | Sorti quarantine |
| `superadmin.test.js` | **DELETED** | G+F | Routes mortes + reste = duplicate P2-02E | `p2-02-staff.test.js` | Fichier supprimé |
| `unit/models/extensions.test.js` | **DELETED** | B | Virtual `imageUrl` mongoose inexistant | Client/Partner : `images[]` / getter Dart | Fichier supprimé |
| `integration/security.test.js` | **NOT A JEST TEST** | D | Déplacé | `tests/manual/security-probe.js` + `npm run test:manual:security` | Plus dans Jest |
| Controllers payment/reservation/residence, payment, transaction, reservation, residence, review, favorite, geo, cleanup, performance, middleware, unit/auth, auth.controller, redis, cache*, validation-schemas, residence.validation | QUARANTINE | D/E/H | Vague 2D / 2C restante | Voir lots | **REPAIRED** avec factories **ou** DELETE + preuve |

### Superadmin — routes mortes (preuve)

| Ancien test | Router actuel `superadmin.routes.js` | Dashboard | Décision |
|---|---|---|---|
| `GET /api/superadmin/security/logs` | Absent ; logs = `GET /activity-logs` | Pas de hit `superadmin/security` | **OBSOLETE_ROUTE** |
| `POST /api/superadmin/security/block-ip` | Absent ; block = `POST /blocked-ips` | idem | **OBSOLETE_ROUTE** |
| `GET /api/superadmin/reports/system` | Absent | idem | **OBSOLETE_ROUTE** |
| `GET /api/superadmin/reports/security` | Absent | idem | **OBSOLETE_ROUTE** |
| GET/PUT settings, CRUD admins | Présents | Couvert P2-02E | **DUPLICATE** → staff tests |

Settings : whitelist P2-02E déjà dans `p2-02-staff.test.js`. JWT claim ignoré : même fichier, `rôle JWT spoofé ignoré`.

### imageUrl mongoose

- `Residence` model : **pas** de virtual `imageUrl`
- Front : `images[]` / getters Dart (`residence_model.dart`, `residence_extensions.dart`)
- Backend : `images[0]` local dans controllers/notifications
- **Pas** de serializer API `imageUrl` sur Residence
- Suppression du test virtual **validée** — pas de recreation mongoose

### BookingError

- `src/utils/domainErrors/bookingErrors.js` n’est plus exercé par les tests
- Types Flutter `BookingError` = état BLoC client, hors ce Jest
- Tests Jest Booking* **supprimés** ; `logBookingError` produit non retiré (hors scope freeze)

### IP auto-block après 5 logins

**OBSOLETE PRODUCT CONTRACT** : plus d’auto-403 « IP bloquée » sur login. Block IP = `POST /api/superadmin/blocked-ips` (staff). Test retiré de `security.test.js`.

## Wave 2 lots

- **2A** : 429 `RATE_LIMIT_EXCEEDED` + `Retry-After` ; JWT factories / rôle Mongo ; settings déjà P2-02E
- **2B** : routes superadmin mortes ; BookingError tests ; virtual imageUrl ; script non-Jest
- **2C** : Joi auth actuel réintégré (Wave 2) ; résidence + duplicate schemas → Wave 3
- **2D** : cache app.js Wave 3 ; PSP **Wave 4**

## Wave 3 — Residence Joi + schemas + Redis/cache

| Fichier | Issue | Preuve |
|---|---|---|
| `validations/residence.validation.test.js` | **REWRITTEN** | Schéma `src/validations/residence.validation.js` (routes residence). `publicationStatus`/`verified` = `Joi.any().strip()`. PUT seul `publicationStatus` → objet vide → `.min(1)` → rejeté. HTTP publish toujours `POST /:id/publish` (P2-02C). |
| `validation-schemas.test.js` | **DUPLICATE** / **DELETED** | Login RFC + `name` register + résidence plate = déjà `auth.validation.test.js` + residence Joi. |
| `unit/config/redis.test.js` | **REWRITTEN** | `ioredis-mock` réel (`isMock`, SET EX, TTL, DEL). Pas `localhost:6379`. Pas de mock `get/set` plat. |
| `unit/middleware/cache.middleware.test.js` | **REWRITTEN** | Middleware **monté dans `app.js`**. `getClient()`. Hit/miss/`EX`. **fail-open** get throw → `next()`. |
| `unit/middleware/cache.test.js` | **DELETED** | Testait `middlewares/cache.js` (callbacks) **non monté** dans `app.js`. |
| `unit/middleware/redis-cache.test.js` | **DELETED** | `redis-cache.js` seulement `examples/` + `cache-config` ; pas `app.js`. |
| `src/utils/validation.js` | **DEAD** (code) | Aucun `require` repo-wide. Non supprimé dans Wave 3 (hors tests). Ne plus écrire de tests dessus. |

Fail-open/closed rate-limit : assertions `POLICIES.*.failClosed` dans `p2-02-rate-limit.test.js` (pas une 2e suite Redis). OTP/finance/staff = fail-closed ; PUBLIC/AUTH limiter = fail-open.

Quarantine restante : **0**.

## Wave 5 — HTTP métier

| Fichier | Issue | Preuve |
|---|---|---|
| `review.test.js` | **REWRITTEN** | `reservationId` + séjour `completed` + owner ; Partner 403 ; 1 review/user+résidence 409 ; GET `data.reviews` ; update/delete IDOR. |
| `favorite.test.js` | **REWRITTEN** | user courant uniquement ; GET ne fuit pas le tiers ; stats admin-only. DELETE `:residenceId` vs `req.params.id` **non corrigé** (hors scope, pas un nouveau service). |
| `geo.test.js` | **REWRITTEN** | `GET /api/maps/nearby` Mongo local. Pas Google. Lat Joi reste `residence.validation.test.js`. |
| `unit/auth.test.js` | **DUPLICATE** / **DELETED** | 2e MongoMemoryServer + register/login déjà `auth.test.js`. |
| `unit/controllers/auth.controller.test.js` | **DUPLICATE** / **DELETED** | LoginAttempt déjà `security.test.js`. |
| `middleware.test.js` | **DUPLICATE** / **DELETED** | 2e Mongo + `/api/auth/profile` `/api/upload` `/api/test-error` morts ; fichiers déjà `unit/middleware/security.test.js`. |
| `performance.test.js` | **MOVE** | `tests/manual/performance-probe.js` + `npm run test:manual:performance`. Pas de seuil ms dans Jest. |
| `cleanup.test.js` | **OBSOLETE** HTTP / **REWRITTEN** util | `/residences/upload` et `/maintenance/cleanup` morts. `tests/unit/utils/cleanup.test.js` sur `cleanupTempFiles`. |

Catégorie A (1 ligne) : `maps.controller.js` chargeait `../services/residence-publication.service` depuis `controllers/maps/` → 500 systématique sur `/api/maps/nearby`. Corrigé en `../../services/...`. Pas de nouvelle couche.

Residence/Reservation HTTP : **volontairement encore quarantinés** (risque P0/P1 / publicationStatus).

### Condition de sortie Wave 5

- [x] Review/Favorite ownership actuel
- [x] Geo sans Google
- [x] Auth/middleware duplicates supprimés
- [x] performance hors `npm test`
- [x] quarantine **4 < 12** (cible 6–8 dépassée par suppressions légitimes, pas par mock)
- [x] skipped **= 1**
- [x] `npm test` vert (29 / 298 / 1 skip)
- [x] `test:ci` vert (16 / 221 / 1 skip)
- [x] aucune nouvelle route/status/service
- [x] Residence/Reservation non forcés au vert

## Wave 6 — fermeture (Residence/Reservation + Favorite A)

| Fichier | Issue | Preuve |
|---|---|---|
| `residence.test.js` | **DUPLICATE** / **OBSOLETE** / **DELETED** | POST admin + `images[]` objet + `availability` ; GET/PUT/DELETE déjà P2-02C (create draft, catalogue, PUT strip publication, publish dédié). |
| `unit/controllers/residence.controller.test.js` | **OBSOLETE** / **DELETED** | Rôle `owner`, `data.owner`, `price.perNight`, filtre `location.city`. |
| `reservation.test.js` | **OBSOLETE** / **DELETED** | `GET /api/reservations`, `PATCH /:id/confirm` → `confirmed` (bypass paiement/inventaire), `generateToken` jwt. Routes actuelles : `/my-reservations`, `PATCH /:id/cancel`, `/:id/status`. |
| `unit/controllers/reservation.controller.test.js` | **OBSOLETE** / **DELETED** | `startDate`/`endDate`, PATCH status `confirmed`, DELETE `/:id`. Concurrence/transitions = P0/P1 `test:ci`. |
| Favorite DELETE | **A réparé** | Router `:residenceId` ; controller lisait `req.params.id`. Aligné `findOne({ residence, user })`. Test HTTP owner 200 + GET vide ; tiers 404. |

Pas de 5e suite Reservation HTTP : les façades utiles sont dans `p2-02-publication` / `p2-02-idor` / P0-P1.

### Condition de sortie Wave 6 / P2-03

- [x] `npm test` vert (29 / 299 pass / 1 skip)
- [x] `test:ci` vert (16 / 221 / 1 skip)
- [x] `test:legacy` vert = supporté (29 / 299 / 1 skip)
- [x] `WAVE_BASELINE = 0`
- [x] skip = 1 (`csrf.test.js` CSRF POST reservations — documenté)
- [x] aucun PSP / Maps Google / Redis réel dans Jest standard
- [ ] open handles : `forceExit` encore dans `jest.config.js` (dette harness, hors P2-03 métier)
- [x] catégorie A Favorite DELETE fermée
- [x] aucune nouvelle route/status/service Reservation/Residence

**P2-03 TESTS / CI = DONE / FROZEN.**

## Wave 4 — PSP / payment / transaction

Règle : mock **client/provider** (Wave, CinetPay, Stripe SDK), jamais `payment.service` / `payout.service` / `refund.service`. 403 IDOR ⇒ **0 appel provider**. Webhooks **sans JWT**.

| Fichier | Issue | Preuve |
|---|---|---|
| `unit/controllers/payment.controller.test.js` | **REWRITTEN** | Routes actuelles : `create-payment-intent`, confirm, refund staff, my-payments, verify CinetPay, webhooks. Amount = `Reservation.totalPrice` / `Payment.amount`. `body.amount` intent = Joi forbidden. Stripe mock SDK ; spies `wave.service` / `cinetpay.service`. |
| `payment.test.js` | **OBSOLETE PRODUCT CONTRACT** / **DELETED** | `POST /api/payments`, `GET /api/payments`, `method`, amount body, `refund_pending`, réservation sans snapshots. Routes absentes de `payment.routes.js`. |
| `transaction.test.js` | **PROVIDER_CONTRACT_OBSOLETE** / **DELETED** | `/api/payments/intent`, `/history`, `/transactions/:id`, `stripePaymentIntentId`, USD, refund client → `refunded`. Model `Transaction` sans router. Couverture Stripe/history = suite réécrite + P2-02D. |

Payout Wave IDOR + 0 `createPayout` : déjà `p2-02-idor.test.js` (**DUPLICATE**, conservé dans `test:ci`). Refund client 403/501 : idem + suite Wave 4.

Aucun `PaymentServiceV2`, aucune nouvelle route/status.

### Condition de sortie Wave 4

- [x] aucun PSP réel appelé
- [x] providers mockés au boundary
- [x] ownership testé avant provider
- [x] montants dérivés backend
- [x] cross-user = 0 provider call
- [x] webhooks séparés des routes JWT
- [x] idempotence intent + webhook duplicate
- [x] vieux contrats PSP supprimés/documentés
- [x] quarantine **12 < 15**
- [x] skipped **= 1**
- [x] `npm test` vert (25 / 280 / 1 skip)
- [x] `test:ci` vert (16 / 221 pass / 1 skip)
- [x] aucune régression P0/P1/P2-02 (produit inchangé)

`npm test` / `npm run test:legacy` passent par `scripts/run-jest-supported.js` et `run-jest-legacy.js` pour que `P2_03_INCLUDE_QUARANTINE` ne fuite plus d’un run à l’autre.

### Condition de sortie Wave 3

- [x] residence Joi aligné au modèle actuel
- [x] publicationStatus impossible à mass-assign (strip + min 1)
- [x] validation schemas vivants identifiés (auth, residence, reservation, payment, availability, message, maintenance, device)
- [x] dead schemas : `validation-schemas.test.js` supprimé ; `src/utils/validation.js` DEAD documenté (pas de require)
- [x] cache tests sans Redis réel (`ioredis-mock`)
- [x] Redis failure semantics : cache fail-open ; rate-limit P2-02F non dupliqué
- [x] anciens rate-limit Redis dupliqués non réintroduits
- [x] quarantine **15 < 21**
- [x] skipped **= 1**
- [x] `npm test` vert
- [x] `test:ci` vert (16 / 221 pass / 1 skip)
- [x] `test:legacy` failures en baisse (21 → 15 suites)
- [x] aucune régression P0/P1/P2-02 (produit inchangé pour Jest)

## Condition de sortie P2-03

- [x] `npm test` termine
- [ ] open handles sans forceExit
- [x] Mongo replset
- [x] providers mockés au boundary (Wave 4 payments ; payout déjà P2-02D)
- [x] Booking classifié
- [x] 429/JWT/staff alignés P2-02
- [x] factories + `authHeaderWithJwtRole`
- [x] dates déterministes (factories / P0-P1 ; plus de suite Reservation quarantinée)
- [x] `test:ci` + garde quarantine
- [x] quarantine **0**
- [x] `test:legacy` = suite supportée (plus de fichiers ignorés)
