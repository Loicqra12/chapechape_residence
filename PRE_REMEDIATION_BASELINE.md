# PRE_REMEDIATION_BASELINE

**Commit :** `c040258`  
**Branche :** `master`  
**Date :** 17 août 2026  
**Portée :** Phase 0 — avant P0-01 / P0-02

## Git

- HEAD : `c040258 chore: bump version client 1.12.0+30, partner 1.12.0+26`
- Apps publiées visées : Client `1.12.0+30`, Partner `1.12.0+26` (`pubspec.yaml`)

## Tests existants (avant nouveaux tests P0)

Commande : `cd backend && npm test`

- Suite actuelle : CRUD auth/payment/reservation **souvent obsolète** vs routes réelles (`PATCH /:id/confirm` n’existe plus).
- **Aucun** test overlap 10→15 vs 12→17 / 15→18.
- **Aucun** test concurrence hour/day.
- **Aucun** test late webhook.
- Jest `setupTests.js` : MongoMemoryServer **standalone** → les **transactions Mongo n’étaient pas réellement exercées**.

Résultat d’exécution Phase 0 : Jest memory → ReplSet. Suite CRUD globale **non relancée** (obsolète). Tests P0 dédiés : 8/8 OK après P0-01/P0-02.

## Mongo capabilities

| Item | Repo | Prod |
|------|------|------|
| Transactions dans le code | OUI (`createReservation`, `cancel`, `modify`, expire) | **À vérifier** replica set DigitalOcean |
| `DEPLOYMENT.md` replica set | Mentionné | Non vérifiable depuis le laptop seul |
| Tests Jest avant ce chantier | Standalone memory | N/A |

## Indexes (schéma — dump prod à faire)

| Index | Fichier | Unique |
|-------|---------|--------|
| Availability `{ residenceId, date }` | `availability.model.js` | OUI |
| WebhookEvent `{ provider, eventId }` | `webhook-event.model.js` | OUI |
| Payment `transactionId` sparse | `payment.model.js` | OUI |
| InventoryLock `{ key }` | **ajouté P0-01** | OUI |

## Migrations

- `npm run db:migrate` pointe `scripts/migrations/run.js` — **fichier ABSENT**.
- Scripts ponctuels : `fix-reservation-policies.js`, `purge-legacy-booking-agenda-jobs.js`.

## Anomalies données (à auditer en prod, dry-run)

- Payment `paid` + Reservation `expired`
- Availability `reserved` sans Reservation bloquante
- `completed` + jours Availability encore `reserved`
- `awaiting_approval` ancien (pas de TTL job)

## Endpoints sensibles

`POST /api/reservations` · `PATCH .../approve|reject|cancel|checkin|checkout|status` · `POST /payments/create-payment-intent` · webhooks Wave/CinetPay/Stripe · `PUT /availability/block`

## Usages `reservation.status` (audit règle d’or des états)

| Fichier | Mécanisme | Légitime ? | Note |
|---------|-----------|------------|------|
| `reservation-state.service.js` | `findOneAndUpdate` filtre sources | OUI | Graphe officiel |
| `reservation.service.js` create | `Reservation.create` status initial | OUI | Instant / approval |
| `reservation.service.js` cancel | `reservation.status = 'cancelled'` | PARTIEL | Même txn + free Availability ; pas `updateStatus` |
| `payment-timer.service.js` startTimer | `findByIdAndUpdate` → `payment_pending` | PARTIEL | **Pas de filtre** statut source |
| `payment-timer.service.js` expire | `findByIdAndUpdate` → `expired` | OUI métier | Libère Availability |
| `payment-confirmation.service.js` | `Reservation.updateOne` / `findOneAndUpdate` → `confirmed` | EXCEPTION | Filtre `pending\|payment_pending\|confirmed` ; `expired`+`allowExpired` → re-lock ; `awaiting_approval` → `refund_required` |
| `reservation.controller.js` reject | `reservation.status = 'cancelled'` | PARTIEL | |
| `reservation.controller.js` checkin/out | `status = in_stay / completed` | PARTIEL | Hors `updateStatus` |
| `payment.controller.js` `updateReservationStatus` | `status = confirmed \| refunded` | **NON** | Bypass graphe — P2 à isoler |

## Décisions P0 retenues

- **P0-01 :** Option B — lock Mongo `residenceId + jour calendaire` dans la txn, puis overlap existant. Pas de mutex process. Compatible PM2. Day unique Availability **inchangé**.
- **P0-02 :** Late pay : re-lock atomique si inventaire libre → confirmed ; sinon Payment paid + Reservation expired + `metadata.refund_required`. Idempotence WebhookEvent conservée.

## Exécution tests Phase 0

- Suite CRUD globale `npm test` : **non relancée** (routes obsolètes, bruit).
- Jest : `MongoMemoryReplSet` (transactions réelles), `launchTimeout: 120000`.

## P0-01 / P0-02 — résultat

Commande : `npx jest tests/unit/services/reservation-inventory.p0.test.js --coverage=false --forceExit --testTimeout=180000`

**8 passed / 8 total** (~29 s).

- Day 10→15 vs 12→17 REFUSÉ (400 Availability)
- Day 10→15 vs 15→18 ACCEPTÉ
- Hour overlap REFUSÉ / back-to-back ACCEPTÉ
- 20 creates concurrents hour → 1 succès / 19 × 409
- Late pay inventaire libre → confirmed + paid
- Late pay dates reprises → refund_required, A non confirmée
- Idempotence 5× applyPaymentPaid → une seule confirmation financière

Exception états : `payment-confirmation.service.js` peut écrire `confirmed` avec filtre source (paiement) ; re-lock si `expired`.

Risques P0 restants : `modifyReservation` sans retry txn ; `payment.controller.js` `updateReservationStatus` (refund) assigne `confirmed`/`refunded` hors graphe.

## P0-03 / P0-04 — résultat (17 août 2026)

- Couche unique : `backend/src/services/inventory.service.js` (`guardSlot` + `withRetry`).
- create / modify / reacquire / cancel / expire / `blockDates` passent par lock + overlap.
- Retry épuisé → **503** `GENERAL_SERVICE_UNAVAILABLE`, pas 409.
- Jours UTC ; plage 22 23:00→23 02:00 verrouille 22 et 23, clés triées.
- `approval_required` : webhook, `ReservationStateService`, `confirmPayment`, helper refund payment.controller.
- Tests : 16/16 `reservation-inventory.p0.test.js`.
- Index test ReplSet : unique `InventoryLock.key` OK. **Prod non vérifiée** — script `backend/scripts/verify-inventory-indexes.js`.
- P0-05 refund automatique : **non fait**.
## P0-05 / Mongo cible / CI — 17 août 2026

- Refund : `refund.service.js` + champ `Payment.refundStatus` + job Agenda `process payment refund`.
- Wave/CinetPay : **pas** de faux refunded → `refundOpsRequired` (queue ops).
- Stripe : refund auto idempotent (`idempotencyKey` + claim atomique).
- Mongo `MONGODB_URI` (.env laptop) : Atlas 8.0.29, replica set, indexes unique InventoryLock + Availability → script **SAFE** (read-only).
- Audit dry-run : overlaps `payment_pending` historiques, 2 confirmed unpaid, 0 paid+expired.
- CI : job `backend-critical-tests` + `npm run test:critical` (sans `|| true`).
- `npm test` global : exécuté, **non vert** (Redis mock, seeds Residence, Agenda) — classification dans le rapport de phase.
