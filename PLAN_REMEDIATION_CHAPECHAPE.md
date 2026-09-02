# Plan de remédiation — ChapeChape Résidence

**Nature :** registre de tâches phasé (pas encore d’implémentation).  
**Règle :** chaque item a un statut **projet réel** vérifié dans le code.  
**Commit de référence :** `c040258` (`chore: bump version client 1.12.0+30, partner 1.12.0+26`) — branche `master`.  
**Date du registre :** 17 août 2026.

Légende statut projet :

| Statut | Signification |
|--------|----------------|
| **EXISTE** | Implémenté et branché dans le flux vivant |
| **PARTIEL** | Code présent mais incomplet, bypassé, cassé ou non branché |
| **ABSENT** | Pas dans le repo / pas d’effet réel |
| **À FAIRE (Phase 0)** | Mesure baseline, pas une feature métier |

---

## 0. Règles (à respecter pendant toute la remédiation)

- Ne pas réécrire Express / Mongo / Bloc / React / Agenda / Reservation / Availability.
- Ne pas créer de modèle backend `Booking` ni de collection `ReservationHold`.
- Préserver `[checkIn, checkOut)` : 10→15 vs 12→17 = conflit ; 10→15 vs 15→18 = autorisé.
- Préserver day/week/month : txn Mongo + overlap Reservation + unique Availability.
- Pas de mutex Node process-local (PM2 cluster).
- Compat API `https://api.chapechaperesidence.com/api` : adapters, pas breaking brutal.
- Aucune perte de données : scripts idempotents + dry-run si migration.
- P0/P1 = tests unitaires + service + intégration ; concurrence = test concurrent réel.
- **Un patch = une phase / un invariant.** Pas de mega-PR.

### Règles d’or (invariants finaux — non négociables)

**Inventaire.** Pour une unité réservable, deux occupations bloquantes ne se chevauchent jamais : séquentiel, concurrence, multi-processus, retries, webhook tardif, modification, annulation, Partner block, external booking, Agenda.

**Paiement.** Aucun client débité sans réservation valide **ou** procédure automatique explicite de remboursement/résolution.

**Approbation.** `approval_required` : aucun paiement/webhook/Admin/code secondaire ne confirme sans approve Partner.

**États.** Aucun `reservation.status` hors invariants métier. Exceptions techniques documentées (Phase 0 baseline).

**Day déjà correct — NE PAS CASSER :** 10→15 vs 12→17 = REFUSÉ ; 10→15 vs 15→18 = ACCEPTÉ ; day/week/month = txn + overlap + unique Availability.

Priorité d’exécution : Phase 0 → **P0-01 hourly** → **P0-02 late webhook** → reste P0 → P1 → P2 → P3.

À chaque fin de phase : PHASE TERMINÉE / fichiers / tests / migrations / risques / prochaine phase.

---

## 0.7 Ordre des phases (strict)

| Phase | Sujet | Statut global |
|-------|--------|----------------|
| 0 | Sécurité / sauvegarde / baseline | **FAIT** (`PRE_REMEDIATION_BASELINE.md`) |
| 1 | P0 réservation / paiement | **CODE COMPLETE / INFRA SAFE sur MONGODB_URI .env** — P1 calendrier non commencé |
| 2 | P1 réservation / Availability / Partner | **À FAIRE** (spécif. partielle reçue + audit) |
| 3 | Harmonisation cross-app | **À FAIRE** |
| 4 | Tests | **À FAIRE** (quasi ABSENT aujourd’hui) |
| 5 | Corrections générales Backend | **À FAIRE** |
| 6 | Corrections Client | **À FAIRE** |
| 7 | Corrections Partner | **À FAIRE** |
| 8 | Corrections Dashboard | **À FAIRE** (spec complète) |
| 9A | Site web marketing | **À FAIRE** (spec complète) |
| 9B | Infra / PM2 / observabilité | **À FAIRE** (spec complète) |
| 10 | Améliorations produit / architecture | **PLUS TARD** (après P0/P1) |
| 11 | Nettoyage legacy | **PLUS TARD** |
| 12 | Tests E2E + docs + diagnostic | **PLUS TARD** |

---

## 1. Baseline architecturale à préserver — constat projet

| Élément attendu | Statut | Preuve |
|-----------------|--------|--------|
| Flutter Client | EXISTE | `chapechape_client/` |
| Flutter Partner | EXISTE | `chapechape_partner/` |
| React Dashboard (CRA) | EXISTE | `chapechape_dashboard/` |
| Site React/Vite | EXISTE | `chapechape_sitepresentation/` |
| Monolithe Express port 4000 | EXISTE | `backend/src/server.js` (`PORT \|\| 4000`) |
| REST `/api` | EXISTE | `backend/src/app.js` |
| Webhooks (raw body) | EXISTE | `app.js` + `payment.controller.js` |
| Socket.IO même process | EXISTE | `socket.service.js` |
| Agenda in-process | EXISTE | `agenda.service.js` démarré dans `server.js` |
| MongoDB / Mongoose | EXISTE | `config/database.js` |
| Microservices | ABSENT | Intentionnel — à conserver |

Domaines vivants (présents dans `backend/src`) : Auth, Users, Partners, Residences, Reservations, Availability, Payments, Payouts, Reviews, Favorites, Notifications, Messages, Promotions, Media, Dashboard/Admin.

---

## 2. Modèle Reservation — constat projet

| Attendu | Statut | Preuve |
|---------|--------|--------|
| Modèle Mongo `Reservation` | EXISTE | `backend/src/models/reservation.model.js` |
| Modèle Mongo `Booking` | ABSENT | Commentaire `app.js` : `/api/bookings` legacy retiré |
| API canonique `/api/reservations` | EXISTE | `app.use("/api/reservations", …)` |
| Mot Booking côté Client | EXISTE (façade) | `booking_model.dart`, `BookingBloc`, `booking_service.dart` → POST `/reservations` |
| Mot Booking côté Dashboard | EXISTE (façade) | `bookingService.js` → `/reservations` |
| Mot Booking Partner | PARTIEL / legacy | `models/booking/booking.dart` (visite) + adapters |
| `BOOKING_STATUS` constants | PARTIEL / legacy | `backend/src/utils/constants.js` (5 valeurs) ≠ enum modèle |

**À conserver :** une seule source de vérité = `Reservation`. Harmoniser le **parsing** Flutter, pas créer un second domaine.

---

## 3. Machine d’états canonique — constat projet

### Enum `Reservation.status` — EXISTE

`pending | awaiting_approval | payment_pending | confirmed | in_stay | expired | cancelled | completed | refunded`

Fichier : `reservation.model.js`.

### Enum `paymentStatus` — EXISTE

`pending | paid | failed | refunded`

### Graphe officiel `ReservationStateService.ALLOWED_TRANSITIONS` — EXISTE

Fichier : `backend/src/services/reservation-state.service.js` (L19–29).

```
pending            → awaiting_approval, payment_pending, confirmed, cancelled, expired
awaiting_approval  → payment_pending, cancelled
payment_pending    → confirmed, expired, cancelled
confirmed          → in_stay, cancelled, completed, refunded
in_stay            → completed, cancelled
expired            → ∅
cancelled          → refunded
completed          → refunded
refunded           → ∅
```

`PAYMENT_REQUIRED_STATUSES` = `confirmed | in_stay | completed` (filtre `paymentStatus === 'paid'`).

### Tous les chemins passent par ce graphe ? — PARTIEL / NON

| Chemin | Passe par `updateStatus` ? | Fichier |
|--------|----------------------------|---------|
| `PATCH /:id/status` | OUI | `reservation-state.service.js` |
| Create instant / approval | NON (create direct) | `reservation.service.js` |
| Approve → `payment_pending` | NON (`startPaymentTimer`) | `reservation.controller.js` + `payment-timer.service.js` |
| Reject → `cancelled` | NON | `rejectReservation` |
| `applyPaymentPaid` → `confirmed` | NON (`Reservation.updateOne`) | `payment-confirmation.service.js` L144–166 |
| Expire → `expired` | NON | `checkAndExpireReservation` |
| Cancel | NON (`reservation.save`) | `cancelReservation` |
| Check-in / check-out | NON (controller) | `performCheckin` / `performCheckout` |

**Tâche Phase 1–2 :** faire passer **tous** ces chemins par les **mêmes invariants** (paid requis, overlap, inventaire), sans forcément tout router mécaniquement par `updateStatus` si ça casse l’atomicité paiement — mais **interdire** les états incohérents.

**Bypass dangereux confirmé :** `applyPaymentPaid` confirme depuis `awaiting_approval` (filtre L148) alors que le graphe officiel exige `payment_pending` après approve.

---

# PHASE 0 — Baseline avant modification

**Livrable :** `PRE_REMEDIATION_BASELINE.md` — **ABSENT** aujourd’hui.

| Tâche | Statut projet | Action |
|-------|---------------|--------|
| Lancer tous les tests actuels | À FAIRE | `cd backend && npm test` — noter pass/fail |
| Rapport tests existants | PARTIEL | Fichiers : `tests/reservation.test.js`, `payment.test.js`, unit controllers — **obsolètes** (ex. `PATCH /:id/confirm` n’existe plus) |
| Tests overlap / hour / race / expire | ABSENT | Aucun scénario 10→15 vs 12→17, 15→18, double POST, late webhook |
| Version MongoDB prod | À FAIRE (Phase 0) | Non vérifiable depuis le repo seul |
| Replica set prod (txn) | PARTIEL | `DEPLOYMENT.md` dit « Configurer MongoDB en replica set » — **capacité prod à confirmer** |
| Index unique Availability `{ residenceId, date }` | EXISTE (schéma) | `availability.model.js` L86 — **présence réelle en prod à dump `getIndexes()`** |
| Index unique WebhookEvent `{ provider, eventId }` | EXISTE (schéma) | `webhook-event.model.js` L25 |
| Dossier migrations | ABSENT | `package.json` a `"db:migrate": "node scripts/migrations/run.js"` mais **aucun fichier `scripts/migrations/`** |
| Scripts liés résa | EXISTE (ponctuels) | `fix-reservation-policies.js`, `purge-legacy-booking-agenda-jobs.js` |
| Données incohérentes | À FAIRE | Script dry-run : Payment paid + Reservation expired ; Availability reserved sans résa active ; `completed` encore reserved |
| Endpoints sensibles | EXISTE | `/api/reservations`, `/approve|reject|cancel|checkin|checkout`, `/payments/*`, webhooks Wave/CinetPay/Stripe |
| Sauvegarde DB avant patch | À FAIRE | Backup DigitalOcean / `npm run backup` |

**Ne pas commencer la Phase 1 sans ce rapport.**

---

# PHASE 1 — P0 Double booking horaire

### Constat code (confirmé)

| Fait | Statut | Preuve |
|------|--------|--------|
| `updateAvailabilityForReservation` no-op si `hour` | EXISTE (le bug) | `availability.service.js` L472–476 |
| Overlap create `findOne` checkIn `$lt` / checkOut `$gt` | EXISTE | `reservation.service.js` L63–80 — **aussi pour hour** |
| Unique jour `{ residenceId, date }` | EXISTE | Ne couvre **pas** les créneaux intra-journée |
| `checkAvailability` hour | PARTIEL | L26–64 : overlap Reservation **sans `in_stay`** dans le `$in` |
| Mutex Redis / lock ressource+date hour | ABSENT | |
| Inventaire slots horaires | ABSENT | |
| Tests 13:00–17:00 vs 14:00–16:00 | ABSENT | |
| Tests 13:00–15:00 vs 15:00–17:00 | ABSENT | |
| Test 20 créations concurrentes → 1 succès | ABSENT | |

**Objectif :** A 13:00→17:00 et B 14:00→16:00 simultanés = **impossible**.  
13:00→15:00 vs 15:00→17:00 = **autorisé** (même convention half-open).

**Interdit :** mutex mémoire process.

### Stratégies à choisir **avant** le code (Phase 1)

| Option | Dans le projet ? | Avis |
|--------|------------------|------|
| A — Time-slot inventory unique | ABSENT | Plus fidèle à Availability jour, plus de migration |
| B — Lock logique `residenceId + date` dans la txn puis overlap | ABSENT | Plus simple, compatible PM2, pas de nouvelle collection lourde |
| C — autre Mongo correcte | — | Acceptable si exclusion mutuelle mathématique |

**Recommandation registre :** Option B d’abord (document de lock / `findOneAndUpdate` atomique sur une ressource jour), overlap existant **dans la même transaction**. Option A seulement si B ne tient pas aux retries.

### Tâches Phase 1-H

1. Choisir A/B/C et documenter dans le PR.
2. Implémenter sans casser day/week/month (unique date inchangé).
3. Inclure `in_stay` dans les statuts bloquants hour (`checkAvailability` aujourd’hui incomplet).
4. Tests listés + multi-process si possible.

---

# PHASE 1 — P0 Late payment / webhook après expiration

### Constat code (confirmé)

| Fait | Statut | Preuve |
|------|--------|--------|
| Expire `payment_pending` → `expired` + free Availability | EXISTE | `payment-timer.service.js` `checkAndExpireReservation` ; job Agenda `expire reservation` L273 — **uniquement si `status === payment_pending`** |
| Webhooks `allowExpired: true` | EXISTE (dangereux) | Stripe / CinetPay / Wave dans `payment.controller.js` |
| Payment peut passer `paid` si status `expired` | EXISTE | `applyPaymentPaid` L122–124 |
| Reservation **exclut** `expired` du confirm | EXISTE (le trou) | `updateOne` L148 : `pending \| awaiting_approval \| payment_pending \| confirmed` |
| État durable paid + expired + inventory free | POSSIBLE | Combinaison des 3 lignes ci-dessus |
| Réacquisition inventaire post-expire | ABSENT | |
| `refund_required` / refund auto si dates reprises | ABSENT | |
| Idempotence WebhookEvent unique | EXISTE | `claimWebhookEvent` + index unique |
| Wave / CinetPay / Stripe branchés claim | EXISTE | `payment.controller.js` |
| Tests A/B/C (re-lock / refund / 5× webhook) | ABSENT | |

**État interdit à laisser durable :** `Payment.paid` + `Reservation.expired` + Availability free **sans résolution**.

### Politique métier retenue dans ce registre (à implémenter)

Stratégie demandée (recommandée) :

1. Charger Reservation.
2. Si `expired` : tenter **atomiquement** de re-lock l’inventaire.
3. Si dates encore libres → re-lock + `confirmed` + `paid`.
4. Si dates reprises → Payment traité (cohérence financière) + Reservation **reste** `expired` + **refund / refund_required** + **aucun** séjour confirmé.
5. **Jamais** resuscite sans re-check inventaire.
6. Webhooks restent idempotents (`WebhookEvent`).

### Tests obligatoires Phase 1-P

- **A** expired + Availability libre + late pay → confirmed + paid + re-lock  
- **B** expired + B a pris les dates + late pay A → pas de confirm A + refund_required  
- **C** même webhook × 5 → une seule conséquence financière  

---

# PHASE 2 — P1 Expiration `awaiting_approval`

*(spécification utilisateur reçue — suite éventuelle à coller plus tard)*

### Constat code (confirmé)

| Fait | Statut | Preuve |
|------|--------|--------|
| Create `approval_required` → `awaiting_approval` | EXISTE | `reservation.service.js` L260–262 |
| Dates bloquées dès create (non-hour) | EXISTE | `updateAvailabilityForReservation(..., 'reserved')` |
| `hostAcceptTTLMinutes` sur Residence | EXISTE | `residence.model.js` L188–196 (défaut 480 min) |
| Snapshot `ttlSnapshot.hostAcceptTTLMinutes` | EXISTE | `reservation.service.js` L299–302 ; modèle `reservation.model.js` |
| Job Agenda expire `awaiting_approval` | ABSENT | Job `expire reservation` **ignore** tout sauf `payment_pending` (agenda L288) |
| Dates peuvent rester bloquées indéfiniment | VRAI | Tant que Partner n’approve/reject pas |

### Objectif Phase 2 (à détailler si la suite de la spec arrive)

- Job Agenda (ou équivalent persisté) : expire `awaiting_approval` après TTL snapshot.
- Libérer Availability comme pour `payment_pending`.
- Notifs client/partner.
- Tests : TTL dépassé → expired + dates libres ; approve avant TTL → pas d’expire.

---

# PHASE 2 — P1 complémentaires (audit, en attendant la suite de la spec)

À intégrer dans Phase 2 **sauf** si la spec utilisateur les déplace.

| ID | Tâche | Statut projet | Preuve |
|----|--------|---------------|--------|
| P1-AVAIL-COMPLETED | `completed` / checkout ne libère pas Availability | PARTIEL / trou | Overlap n’inclut plus `completed` mais jours peuvent rester `reserved` |
| P1-BLOCK | Block manuel Partner effectif au create | ABSENT / cassé | `blockedDates` écrit par `availability.service.blockDates` ; **champ absent** du schema Residence ; **non lu** par `createReservation` |
| P1-CAL-PARTNER | Calendrier dispo Partner | PARTIEL | API `GET /availability/calendar` EXISTE ; UI Partner « bientôt » |
| P1-APPROVE-PAY | `applyPaymentPaid` depuis `awaiting_approval` | EXISTE (bypass graphe) | `payment-confirmation.service.js` L148 — décision métier à figer |
| P1-HOUR-INSTAY | Hour check sans `in_stay` | PARTIEL | `availability.service.js` L32 |

---

# PHASE 3 — Harmonisation cross-app

| Tâche | Statut projet | Action |
|-------|---------------|--------|
| Backend canonique `payment_pending` | EXISTE | |
| Client lit `pending_payment` (timers) | EXISTE (bug) | `booking_helpers.dart` L427+ ; `reservation_timer_widget.dart` L81 |
| Client `in_progress` / `checked_in` vs `in_stay` | EXISTE (bug) | helpers / badges / QR |
| Partner enum `awaitingApproval` / `paymentPending` / `inStay` | PARTIEL | mapping local |
| Agenda encore `pending_payment` en plus de `payment_pending` | PARTIEL | `agenda.service.js` L163 |
| Adapter parse : accepter ancien, **renvoyer** canonique | ABSENT | Compat apps publiées |
| Rename API status | INTERDIT (breaking) | |

---

# PHASE 4 — Tests

Les tests de Phase 4 **complètent** ceux obligatoires des P0/P1 (qui doivent déjà être dans les PR Phase 1–2).

| Couverture | Statut |
|------------|--------|
| 10→15 vs 12→17 → conflit | ABSENT |
| 10→15 vs 15→18 → autorisé | ABSENT |
| Double POST day concurrent | ABSENT |
| Double POST hour concurrent | ABSENT |
| Expire payment + free | ABSENT |
| Late webhook A/B/C | ABSENT |
| Cancel libère Availability | ABSENT (cancel HTTP basique seulement) |
| Modify / prolongation revalide | ABSENT |
| awaiting_approval TTL | ABSENT |
| Tests reservation.test.js routes actuelles | PARTIEL / cassés vs routes réelles |

---

# PHASE 5 — Backend général

| Tâche | Statut |
|-------|--------|
| Tous chemins d’état = mêmes invariants | PARTIEL |
| `error.middleware.js` riche non monté | PARTIEL (handler inline `app.js`) |
| `jobs/payout-scheduler.job.js` non booté | ABSENT du boot |
| Constants `BOOKING_STATUS` vs `RESERVATION_STATUS` | PARTIEL |
| CSRF / rate-limit (ne pas mélanger à P0) | EXISTE partiel — Phase 9 |

---

# PHASE 6 — Client Flutter (spec complète)

**Versions repo (ne pas supposer) :** `chapechape_client/pubspec.yaml` = **1.12.0+30**.  
Feature flags Client = **locaux / images seulement** (`lib/core/config/feature_flags.dart`) — **pas** de flags Backend pour Wave/CinetPay/QR.

### STATUS

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Canonique backend `payment_pending` | EXISTE | `reservation.model.js` |
| Client timers testent `pending_payment` | EXISTE (bug) | `booking_helpers.dart` L427+ ; `reservation_timer_widget.dart` L81 |
| `in_progress` / `checked_in` vs `in_stay` | EXISTE (bug) | helpers / badges / QR |
| Adapter : accepter ancien + afficher canonique | ABSENT | Compat 1.12.0+30 obligatoire |

### TIMER

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Champ backend `paymentDeadline` | EXISTE | `reservation.model.js` L251 ; set au create instant |
| Champ backend `hostApprovalDeadline` | **ABSENT** | Client parse `hostApprovalDeadline` (`booking_model.dart` L28, L228) — **pas dans le schéma Reservation**. Seulement `ttlSnapshot.hostAcceptTTLMinutes` |
| Timer UI basé uniquement sur backend deadline | PARTIEL | Mélange `pending_payment` local + `hostApprovalDeadline` souvent null |
| Afficher expired depuis status backend | PARTIEL | Labels existent ; timer rate le vrai `payment_pending` |

**Action :** mapper `payment_pending` ; afficher `paymentDeadline` + remaining ; expired = status backend. **Ne pas** inventer un TTL Flutter.

### AVAILABILITY

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| `GET /availability/flutter-check` | EXISTE | `availability.routes.js` |
| Cache local autoritatif | PARTIEL / risque | `availability_cache_service.dart` — à subordonner à l’API |
| Partner block / external / maintenance datée / turnover dans le calendrier Client | ABSENT côté create + UI | Block Partner ineffectif ; external ABSENT ; turnover ABSENT |

### CONFLICT UX

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| POST create → 409 | EXISTE | `reservation.service.js` L79 message « Ces dates viennent d'être réservées… » |
| Code `RESERVATION_DATE_CONFLICT` | **ABSENT** | `errorCodes.BOOKING.DATE_CONFLICT` = `BOOKING_DATE_CONFLICT` ; create **ne passe pas** ce code (ApiError message seul). `RESERVATION` n’a pas `DATE_CONFLICT` |
| UX 409 + refresh availability auto | ABSENT / à vérifier UI | Message spec à brancher + refresh `flutter-check` |

**Action (compat) :** backend peut **ajouter** `RESERVATION_DATE_CONFLICT` tout en gardant 409 + message actuel. Client accepte les deux codes.

### CHECK-IN / QR

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| `QRCodeScreen` | EXISTE fichier | `presentation/screens/qr/qr_code_screen.dart` |
| Route GoRouter | ABSENT | Aucune navigation |
| Anti-replay / expiration QR backend | PARTIEL | Codes générés au create (`reservation.service.js`) — pas de one-time consume vérifié ici |
| Décision produit | **OUVERTE** | Activer (routes + sécu) **ou** flag off / isoler. Interdit : laisser pseudo-fonctionnel |

### PAYMENT

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Wave actif | EXISTE | `payment_screen.dart` — seul sélectionnable |
| OM / MTN / Moov / CinetPay UI | PARTIEL | Affichés « Bientôt disponible » (OK si clairement disabled) |
| Feature flags paiement **depuis Backend** | ABSENT | Flags Flutter = Cloudinary/images seulement |
| Route `/payment-webview` | ABSENT | `cinetpay_service` push une route non montée |

**Règle :** Wave seul utilisable jusqu’à flags Backend + tests. Ne pas présenter CinetPay comme payant.

**Ne pas faire Phase 6 avant Phases 1–3** (statuts / deadlines backend).

---

# PHASE 7 — Partner Flutter (spec complète)

**Version repo :** `chapechape_partner/pubspec.yaml` = **1.12.0+26**.

Priorités spec : calendrier · blocks · external booking · approval timer · status · verification.

### VERIFICATION / RÔLE

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Login stocke `partner.role` réel (peut être `partner_pending`) | EXISTE | `auth_bloc.dart` login |
| Restart `AuthCheckRequested` force `userRole = 'partner'` | EXISTE (bug) | `auth_bloc.dart` ~L141 — **ignore `/auth/me`** |
| Guard `partner_pending` | ABSENT | App utilisable dès signup |

**Action :** respecter `GET /auth/me` ; ne plus écraser le rôle.

### CALENDRIER

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| API `GET /availability/calendar` | EXISTE | `availability.routes.js` |
| UI calendrier dispo | ABSENT | Détail résidence : « Le calendrier sera disponible bientôt » |
| Calendrier **réservations** (pas inventaire) | EXISTE | `reservation_calendar_widget.dart` |
| États visuels available / awaiting / payment_pending / confirmed / in_stay / blocked / external / maintenance | ABSENT UI unifiée | external + maintenance datée **ABSENT** backend |

### APPROVAL TIMER

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Timer UI Partner 24h hardcodé possible | PARTIEL | `reservation_timer_widget.dart` Partner |
| Champ `hostApprovalDeadline` backend | **ABSENT** | Seulement minutes snapshot |
| Approve désactivé si TTL dépassé | ABSENT (pas de job expire non plus — Phase 2) | |

**Action :** exposer `hostApprovalDeadline` (ISO) depuis TTL snapshot + `createdAt` ; UI = ce champ uniquement.

### PUSH / SOCKET

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Events définis `new_reservation_received`, expired, status | EXISTE | `socket.service.js` |
| Branchés UI Partner | PARTIEL | Surtout `new_message` ; résa sockets **non branchés** |
| OneSignal push | EXISTE | `onesignal_service.dart` |
| REST = vérité, socket = accélérateur | PARTIEL | À figer (pas de 2e state machine locale) |

### PAYOUT UX

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Reversements auto (lecture stats) | EXISTE | `GET /payouts/partner/:id` |
| `requestWithdrawal` → `UnsupportedError` | EXISTE (dangereux UX) | `payment_service.dart` |
| Dialog « auto » vs bouton Retirer | PARTIEL | Masquer toute action non fonctionnelle |

### AUTRES

| Tâche | Statut |
|-------|--------|
| External booking Partner | ABSENT |
| Blocks effectifs | ABSENT / cassé (Phase 2) |
| SMS vérif widget | Orphelin |
| Check-in/out UI | API oui, UI non |
| `ReservationApprovalScreen` | Orphelin |

---

# PHASE 8 — Dashboard (spec complète)

### BOOKINGS

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Liste = `GET /reservations/my-reservations` | EXISTE (mauvais) | `bookingService.js` L19–21 TODO |
| `GET /admin/reservations` paginé / filtres | ABSENT | Routes admin résidences/users existent, **pas** catalogue résa global |

**Action :** endpoint admin protégé (`isAdmin`) : pagination, residence, client, partner, status, paymentStatus, dates, conflits potentiels.

### STATUS ADMIN

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| `PATCH /reservations/:id/status` → `ReservationStateService` | EXISTE | Partner owner — Dashboard souvent 403 |
| `reservation.status = req.body.status` sauvage | À interdire partout | Chercher à l’implémentation admin |
| Admin passe par le **même** service métier | PARTIEL | Manque endpoint admin dédié |

### PARTNERS

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Service `PUT/DELETE/verify /admin/partners` | EXISTE | `adminService.js` |
| UI submit / Block / Activate | PARTIEL | TODO / handlers absents |

**Action :** implémenter **ou** disable. Pas de bouton trompeur.

### AMENITIES / PROPERTY TYPES

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| `this.makeRequest` | **ABSENT** (crash) | `adminService.js` L619+ |
| Fallback mock prod | EXISTE (mauvais) | Amenities.js catch → données locales |

**Action :** axios réel **ou** retirer l’écran. Interdit mock silencieux prod.

### PROMOTIONS

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| API backend `/api/promotions` | EXISTE | `promotion.routes.js` monté |
| Dashboard `getPromotions` | MOCK | `marketingService.js` L7–8 TODO |

**Action :** brancher l’API **ou** label « non disponible ».

### SUPPORT

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| `app.use("/api/support")` | EXISTE | `app.js` L470 |
| Implémentation | STUB | `support.routes.js` « STUB - À implémenter » → `data: []` |
| UI Dashboard Support | EXISTE | `SupportPage.jsx` + sidebar |

**Action :** implémenter **ou** masquer UI.

### RBAC

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| `App.js` PrivateRoute = `isAuthenticated()` only | EXISTE (faible) | L43–45 |
| `components/auth/PrivateRoute.js` avec `requiredRole` | EXISTE **non branché** | |
| `checkPermission` | EXISTE **non utilisé** routes | `AuthContext.js` |
| Pages admin gate `isSuperAdmin()` | PARTIEL | UI only — sécu finale = Backend |

### API URL

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Prod fallback `api.chapechaperesidence.com` | EXISTE | `config.js` L6–7 |
| Protocol défaut **http** si `REACT_APP_USE_HTTPS` ≠ true | EXISTE (risque) | `config.js` L10–14 → prod build sans env = **http://api…** |
| `HttpToggle` en UI | EXISTE | `App.js` L54 |

**Action :** prod **https** par défaut. Pas de http API publique.

---

# PHASE 9A — Site web (marketing)

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| Site Vite présentation | EXISTE | `chapechape_sitepresentation/` |
| Booking complet sur le site | ABSENT | **Ne pas ajouter** dans ce chantier |
| Fallback API `http://localhost:4000/api` | EXISTE | `api.service.ts` (analyse existante) |
| Contact / newsletter | EXISTE | `website.routes.js` |
| Blog backend | PARTIEL / mort | `blog.routes.js` **commenté** dans `app.js` L38, L472 |
| Décision blog | **OUVERTE** | Statique **ou** monter `/api/blog` — pas d’API morte |

Corriger seulement : config API, erreurs, endpoints morts, sécu formulaires, contact, newsletter, SEO technique si besoin.

---

# PHASE 9B — Infrastructure / PM2 / observabilité

### Ports 4000 vs 5000 — INCOHÉRENT (confirmé)

| Source | Port |
|--------|------|
| `server.js` / `backend/.env.example` / `ecosystem.config.js` | **4000** |
| `docker-compose.yml` | **4000:4000** |
| `docker-compose.dev.yml` | **5000:5000** |
| `nginx/nginx.conf` (repo) | `backend:5000` |
| `chapechape_dashboard/nginx.conf` | `backend:5000` |
| `backend/nginx.conf` | API 4000 + swagger 5000 |
| `README.md` / `DEPLOYMENT.md` / load-test | **5000** parfois |
| Flutter `.env.example` | 4000 |

**Convention à figer (proposition registre) :** container + host dev + PM2 = **4000**. Nginx prod → 4000. Doc/README/docker-dev alignés. **5000 = interdit** sauf justification écrite.

### PM2

| Tâche | Statut projet | Preuve |
|-------|---------------|--------|
| `exec_mode: 'cluster'` + `instances: 'max'` | EXISTE | `ecosystem.config.js` L4–6 |
| Graceful shutdown SIGTERM | EXISTE | `server.js` Agenda + Mongo |
| Socket.IO Redis adapter | **ABSENT** | Aucun `@socket.io/redis-adapter` |
| Impact cluster | **RISQUE** | Sockets/rooms **par worker** — events peuvent ne pas atteindre le bon process |

**Action :** documenter 1 instance Socket **ou** ajouter Redis adapter avant de scaler.

### OBSERVABILITÉ

Winston/Sentry/New Relic = EXISTE.  
Logs structurés événements métier listés (`RESERVATION_CREATE`, `PAYMENT_LATE`, etc. + ids, **sans** secrets) = **ABSENT** (logs ad hoc `console.log` / logger texte).

Ne jamais logger token / password / PSP sensibles.

---

# PHASE 10 — Améliorations produit (après P0/P1 seulement)

| Tâche | Statut projet | Note |
|-------|---------------|------|
| `turnoverMinutes` / buffer | ABSENT | Ne pas bloquer une journée entière si buffer horaire suffit |
| `defaultCheckInTime` / `defaultCheckOutTime` | ABSENT | Pour ménage tout en gardant 10→15 / 15→18 |
| Multi-unités Property→Unit | ABSENT | **Proposition séparée** — ne pas mélanger aux P0 |
| Inventory quantitative (quantity=12) | ABSENT | Idem |
| Prix Backend autoritatif | PARTIEL | `POST /reservations/calculate-price` EXISTE ; Flutter estime aussi en local |
| CancellationPolicy vs `Residence.type` enums | PARTIEL | Enums **différents** (audit Partie 3) ; `createdBy → Admin` mort |
| Matrice notifs EVENT × CLIENT/PARTNER/ADMIN × email/push/socket | ABSENT doc | Types existent `notification-types.js` — doublons possibles |

**Interdit Phase 10 :** collection ReservationHold ; rewrite moteur.

---

# PHASE 11 — Nettoyage legacy (après stabilisation)

Pour chacun : **KEEP / MIGRATE / DELETE / ARCHIVE** — jamais delete sans usages.

| Élément | Statut projet | Décision (à figer en Phase 11) |
|---------|---------------|--------------------------------|
| Traces coverage `booking.controller` | Artefacts | ARCHIVE/DELETE fichiers coverage |
| `BOOKING_STATUS` constants | EXISTE | MIGRATE vers `RESERVATION_STATUS` |
| `Transaction` model USD/Stripe | EXISTE suspect | KEEP ou ARCHIVE après usages |
| `Stats` / `Action` | EXISTE peu utilisés | Auditer usages |
| `Media` stubs | PARTIEL | |
| Blog routes non montées | PARTIEL | Décision 9A |
| `frontend/` `web/` | À inventorier | |
| QR / Approval / CinetPay / Availability Flutter orphelins | PARTIEL | Brancher **ou** flag/isoler |
| `jobs/payout-scheduler.job.js` | Mort au boot | DELETE ou brancher |
| CSRF middleware doublons | PARTIEL | |
| `error.middleware.js` non monté | PARTIEL | Brancher **ou** fusionner inline |

Code mort Flutter : route ? navigation ? flag ? backend ? → brancher ou isoler.

---

# PHASE 12 — Tests E2E, docs, diagnostic, déploiement

### Versions mobiles à tester (repo actuel)

- Client **1.12.0+30** (`chapechape_client/pubspec.yaml`)
- Partner **1.12.0+26** (`chapechape_partner/pubspec.yaml`)

DTO publiés : parsing rétrocompatible (Phase 3).

### Scénarios E2E (tous ABSENTS aujourd’hui comme suite automatisée)

| Scénario | Dépend de |
|----------|-----------|
| Instant : search → create → payment_pending → Wave → confirmed → checkin → in_stay → checkout → completed | Phases 1, 6, 7 |
| Instant no pay → timeout → expired → free | Phase 1 |
| Approval → approve → pay → confirmed | Phase 2 |
| Approval timeout Partner inactif → free | Phase 2 |
| Partner reject → cancelled + `rejectedByHost` → free | EXISTE code, test ABSENT |
| Concurrent day 20 req → max 1 | Phase 1 |
| Concurrent hour → max 1 | Phase 1 |
| External Partner booking → Client 409 | Phase 7+2 (feature ABSENTE) |
| Partner block maintenance → Client cannot → unblock | Phase 2 (block cassé) |
| Late payment branches A/B/C | Phase 1 |

### Documentation à produire — tous ABSENTS (sauf `DEPLOYMENT.md` partiel)

| Doc | Statut |
|-----|--------|
| `docs/RESERVATION_ARCHITECTURE.md` | ABSENT |
| `docs/RESERVATION_STATUS_SPEC.md` | ABSENT |
| `docs/AVAILABILITY_ARCHITECTURE.md` | ABSENT |
| `docs/PAYMENT_LIFECYCLE.md` | ABSENT |
| `docs/PARTNER_CALENDAR.md` | ABSENT |
| `docs/DEPLOYMENT_CHECKLIST.md` | PARTIEL (`backend/DEPLOYMENT.md`) |
| `docs/INCIDENT_PLAYBOOK_RESERVATION.md` | ABSENT |

Playbook : double booking, late payment, Availability mismatch, paid+expired, confirmed sans Availability, Agenda down, webhook delayed.

### Outils diagnostic

| Tâche | Statut |
|-------|--------|
| `audit-reservation-consistency.js` read-only | ABSENT |
| `--dry-run` par défaut | — |
| Détecter : overlap 2 bloquantes, résa sans Availability, Availability orpheline, paid+expired, confirmed unpaid, awaiting trop vieux, Payment/Availability orphelins | ABSENT |

### Data repair

**Interdit** repair auto prod sans rapport. Flux : report → dry-run → validation → script **idempotent**.

### Déploiement P0

backup Mongo → tests → staging → indexes → deploy Backend → health → smoke → Sentry/NR → logs Reservation → **ensuite** Flutter/Dashboard si besoin.

### Feature flags (risque)

| Flag | Backend | Flutter |
|------|---------|---------|
| hourly booking | ABSENT flag | hour déjà dans create |
| partner calendar | ABSENT | UI bientôt |
| external booking | ABSENT | ABSENT |
| QR check-in | ABSENT | écran orphelin |
| CinetPay | code service EXISTE | UI bientôt |

Ne pas afficher « actif » tant que Backend + UI + tests ne sont pas prêts. Idéalement flags **Backend**.

---

## Chaînes de code (preuves — ne pas casser)

```
Client BookingService.createBooking
  → POST /api/reservations
  → reservation.routes
  → reservation.controller.createReservation
  → reservation.service.createReservation
       txn + isAvailableForDates + overlap findOne
       + Availability.upsertBulk (SAUF hour = no-op)
  → Reservation model

Paiement
  → POST /payments/create-payment-intent | webhooks
  → payment.controller (allowExpired: true)
  → applyPaymentPaid
  → Reservation.updateOne (expired EXCLU)
  → Agenda cancel expire

Dashboard bookings (actuel, à remplacer Phase 8)
  → GET /reservations/my-reservations
```

---

## Décisions encore ouvertes

**Phase 1 (bloquent le code) :**
1. Hour lock : Option A / B / C  
2. Late pay dates prises : refund auto vs `refund_required`  
3. Paiement pendant `awaiting_approval` : interdire vs bypass  

**Phase 6–11 :**
4. QR check-in : activer (sécu replay) **ou** flag off  
5. CinetPay : flags Backend avant UI  
6. Blog site : statique vs monter `/api/blog`  
7. Support Dashboard : implémenter vs masquer  
8. PM2 cluster : Redis Socket adapter **ou** 1 worker sockets  
9. Port canonique : **4000** proposé  

---

## Spec utilisateur

Phases **6–12** ci-dessus = spec collée le 17 août 2026, croisée au code `c040258`.  
Phase 2 utilisateur s’arrête encore à `hostAcceptTTLMinutes` (P1 complémentaires audit conservés plus haut).

