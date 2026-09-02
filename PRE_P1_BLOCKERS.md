# Pré-P1 — classification (read-only)

**Date :** 17 août 2026  
**Cible auditée :** `MONGODB_URI` de `backend/.env`  
**Empreinte canonique :** `hash(host SRV | database)` = `efebb871c934cf3c`  
**Host URI :** `cluster0.ian2p.mongodb.net` · **database :** `test`  
**Aucune donnée n’a été corrigée.**

Statut global : **P0 CODE COMPLETE — PROD VERIFICATION PENDING**

---

## 1. Mongo — ce qui est SAFE vs ce qui reste PENDING

### Vérifié sur l’URI `.env` (read-only)

| Check | Résultat |
|--------|----------|
| Replica set | `atlas-7wo1js-shard-0` |
| Transactions | oui (replica set) |
| MongoDB | 8.0.29 |
| `InventoryLock.key` UNIQUE | oui |
| Availability `{residenceId, date}` UNIQUE | oui |
| **RESULT** | **SAFE** |

Le health public `https://api.chapechaperesidence.com/api/health` répond `environment: production` mais `database: disconnected`. C’est un **faux négatif** : il lisait `req.app.locals.dbConnection`, jamais alimenté. Ce n’est **pas** une preuve que l’API n’a pas Mongo.

`ecosystem.config.js` n’injecte **pas** `MONGODB_URI` (seulement `NODE_ENV` / `PORT`). Le process PM2 `chapechape-residences-api` hérite donc de l’env machine / `.env` droplet.

### Comparaison API prod vs `.env` — encore à faire sur le droplet

Sans SSH, on ne peut pas affirmer que `api.chapechaperesidence.com` pointe vers le même cluster.

Procédure ops (aucun mot de passe dans les logs) :

```bash
# Sur le droplet, dans le répertoire backend de l’API
node scripts/fingerprint-mongo-env.js
# ou, après déploiement du health fingerprint :
curl -s https://api.chapechaperesidence.com/api/health
```

Comparer `fingerprint(host|database)` à `efebb871c934cf3c`.

- **Match** → cette audit Atlas **est** la prod. Indexes/transactions déjà SAFE.
- **Mismatch** → relancer `npm run verify:inventory` **avec l’URI du process PM2**, pas celle du laptop.

Après déploiement, `GET /api/health` expose `mongoFingerprint` (hash seul) et le vrai `database: connected|disconnected` via `mongoose.connection.readyState`.

---

## 2. Les « 5 overlaps » = 5 documents, 4 paires uniques

Trois holds se chevauchent sur **la voine** (clique de 3) + une paire sur **Adobe**.  
Tous : même client, même partner, `payment_pending`, deadlines dépassées (27 mars 2026), séjours **déjà passés** au 17 août 2026. **Aucun Payment `paid`.** Pas de client débité côté Mongo.

**Danger immédiat séjour en cours :** non.  
**Action :** ne pas auto-cancel en bloc. Vérifier côté Wave les `transactionId` pending (checkout non capturé probable), puis plan de remédiation : passer en `expired` un par un.

### Paire Adobe — `6855a832c32107186fa93940`

| | A | B |
|--|--|--|
| Reservation | `69c6e11968e4ea2f27f24188` | `69c6a012398a9f76e8eeacc2` |
| Client | ONLOUTOU PUB / `pubonloutou@gmail.com` | **même** |
| Partner | jordy melyer / `jordymelyer15@gmail.com` | **même** |
| checkIn / checkOut | 2026-03-28 19:51 → 03-30 19:51 | 2026-03-28 10:00 → 03-29 10:00 |
| status / paymentStatus | payment_pending / pending | payment_pending / pending |
| bookingType | day | day |
| createdAt | 2026-03-27 19:57 | 2026-03-27 15:19 |
| paymentDeadline | 2026-03-27 20:27 | 2026-03-27 15:49 |
| Payments | aucun | aucun |
| Availability | 2 | 0 |
| Classification | hold abandonné / timer non expiré | hold abandonné |

### Clique « la voine » — `6855a8c8c32107186fa9395d` (3 documents → 3 paires)

Même client / partner. Tous `day`, `payment_pending`, 2026-03-28 10:00 → 03-29 10:00.

| Reservation | createdAt | deadline | Payments | Availability |
|--|--|--|--|--|
| `69c6a133398a9f76e8eeacf5` | 15:24 | 15:49 | aucun | 0 |
| `69c6a963398a9f76e8eead35` | 15:59 | 16:29 | Wave `pending` `cos-23vwtc9xg2y02` 15225 | 0 |
| `69c6b1a2398a9f76e8eead74` | 16:34 | 17:04 | Wave `expired` `cos-23vvsjr08296e` + Wave `pending` `cos-23vw7dc5r2254` | 1 |

Classification : **holds payment_pending sans capture Mongo**. Wave pending = checkout ouvert, pas un débit confirmé. Ops : confirmer l’absence de capture Wave avant expiration manuelle.

---

## 3. 24 actives sans Availability — ventilation

**Aucune n’est `hour`.** L’absence n’est donc **pas** un artefact de l’ancien design horaire.

| bookingType | count |
|--|--|
| `(unset)` | 15 |
| `day` | 9 |
| week / month / hour | 0 |

| status | count |
|--|--|
| pending | 12 |
| payment_pending | 9 |
| confirmed | 3 |
| awaiting_approval / in_stay | 0 |

**checkOut encore dans le futur (17 août 2026) : 0.**  
Aucune de ces 24 ne bloque un séjour à venir. Ce sont des statuts bloquants **zombifiés** sur des dates passées.

### 15 `(unset)` — legacy pré-bookingType (2024–2025)

Statuts `pending` (12) + `confirmed` (3). Dates 2024-01 → 2025-06. Schéma ancien, pas de `location`/Availability journalière attendue à l’époque.

Les 3 confirmed sans Availability :

| id | pay | dates |
|--|--|--|
| `67646740747d547e3c937959` | pending | 2024-01-10 → 01-15 — **aussi Cas B unpaid** |
| `67646fa6747d547e3c9379a9` | paid | 2024-03-10 → 03-15 — séjour fini, champ Availability manquant seulement |
| `67d89a4d55c13239637d4995` | pending | 2025-05-16 → 05-17 — **aussi Cas B unpaid** |

Les 12 `pending` `(unset)` : dates 2024-03 → 2025-06, `paymentStatus=pending`. Probable **données de test / parcours jamais payés**, pas des clients en séjour.

### 9 `day` `payment_pending` — dont les 5 overlaps

| id | dates | note |
|--|--|--|
| `68b5e49bc57aace1f8b817e7` | 2025-09-02 → 09-04 | hold expiré, hors overlaps |
| `69b6f29c912cf88a40325e81` | 2026-03-16 → 03-18 | hold expiré |
| `69b6f658912cf88a40325ebd` | 2026-03-16 → 03-18 | hold expiré |
| `69c6a012398a9f76e8eeacc2` | 2026-03-28 → 03-29 | overlap Adobe |
| `69c6a133398a9f76e8eeacf5` | 2026-03-28 → 03-29 | overlap voine |
| `69c6a963398a9f76e8eead35` | 2026-03-28 → 03-29 | overlap voine + Wave pending |
| `69c6b1a2398a9f76e8eead74` | 2026-03-28 → 03-29 | overlap voine + Wave expired/pending |
| `69c6e11968e4ea2f27f24188` | 2026-03-28 → 03-30 | overlap Adobe (a 2 Availability) |
| `6a0535c33fba85156a518f0c` | 2026-05-15 → 05-16 | hold expiré |

---

## 4. Les 2 confirmed + paymentStatus ≠ paid — Cas B tous les deux

Pas de Cas A (Payment `paid` + champ Reservation désync). Les deux : **aucun Payment**, séjour **passé**, même client.

### `67646740747d547e3c937959`

- Client : adams diaby / `adamsdiaby@gmail.com`
- Partner : null
- Résidence : `6764511bbe35037b5a623fdf`
- 2024-01-10 → 2024-01-15 · createdAt 2024-12-19 (création **après** le séjour — seed / donnée de démo probable)
- Pas de paymentDeadline, pas de Payment, 0 Availability
- **Pas un client en séjour.** Arbitrage : reclasse en cancelled/expired **après** confirmation métier que ce n’est pas une dette.

### `67d89a4d55c13239637d4995`

- Même client
- Partner : jordy melyer
- Résidence : `67cb2f6acb3b4423a99c32c8`
- 2025-05-16 → 2025-05-17 · createdAt 2025-03-17
- Pas de Payment, 0 Availability
- **Grave au modèle** (confirmed sans paiement) mais **pas un danger immédiat**. Même traitement : pas d’auto-fix, ticket ops individuel.

---

## 5. Verdict danger immédiat

| Question | Réponse |
|--|--|
| Client en séjour (`in_stay`) incohérent ? | Non |
| Overlap sur dates **futures** ? | Non |
| Active sans Availability avec checkOut futur ? | 0 |
| Client débité (Payment `paid`) coincé sur overlap ? | Non |
| Confirmed sans Payment sur dates futures ? | Non |

**Aucune réservation client active réelle n’est en danger immédiat.**  
Les incohérences sont de l’héritage (holds non expirés, seeds 2024, confirmed fantômes). Plan de remédiation **ensuite**, pas un patch prod aujourd’hui.

---

## 6. Suite Jest (hors tests critiques déjà verts)

Correctifs pré-P1 :

- `NODE_ENV=test` → MemoryStore rate-limit (plus de RedisStore + ioredis-mock)
- Agenda : noop si `NODE_ENV=test` ; `startAgenda()` reste dans `server.js`
- Fixtures Residence : `locationData.city` / `address`
- `jest.config.js` : `NODE_ENV=test` dès le load ; coverage désactivée sur `npm test` (`npm run test:coverage` inchangé)

`npm test` **termine** (plus de crash RedisStore / Agenda buffer / import).  
Résultat 17 août 2026 : **32 suites, 92 passed, 191 failed, 1 skipped**.

**Aucune REGRESSION_CAUSED_BY_REMEDIATION identifiée.** Les 191 failures existent déjà vs API/schéma divergents.

### Signal CI

- `npm run test:critical` — 21 invariants P0 (gate dur)
- `npm run test:ci` — suites stables : p0 + csrf + security middleware
- `npm test` / `npm run test:legacy` — catalogue de dette, pas un gate

### Classification des 28 suites rouges

| Classe | Suites | Motif |
|--|--|--|
| **OBSOLETE routes/auth** | `auth.test.js`, `unit/auth.test.js`, `auth.controller.test.js`, `payment*.test.js`, `residence*.test.js`, `favorite`, `review`, `geo`, `superadmin`, `cleanup`, `security` (intégration), `middleware`, `transaction` | attendus 200/201, reçus 401/400/500 (CSRF, validation, routes) |
| **OBSOLETE seeds schéma** | `reservation*.test.js`, `performance.test.js`, `extensions.test.js` | `cancellationPolicy` requis ; performance sans fixture Residence |
| **OBSOLETE enums** | payment controller | `status: completed` n’est plus un enum |
| **OBSOLETE types Booking** | `error.service.test.js` | `BookingError.*` n’est plus un constructeur |
| **OBSOLETE Joi** | `validation-schemas.test.js`, `validations/*` | prénom / `location` required |
| **ENVIRONMENT mocks** | `redis-cache`, `cache*`, `redis.test.js` | spies Redis cassés / logger mock vs singleton |
