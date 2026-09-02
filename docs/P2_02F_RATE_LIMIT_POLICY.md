# P2-02F — Politique rate limiting / trust proxy

Aucune secret n’est documenté ici. Les plafonds sont overridables via `RATE_LIMIT_*`.

## Topologie

```
Internet → Nginx / proxy autorisé → Express trust proxy (hops/CIDR, jamais true aveugle)
  → auth → rate-limit contextualisé → controller
```

- `TRUST_PROXY=0|false` : connexion directe, `req.ip` = socket. `X-Forwarded-For` ne change pas la clé.
- `TRUST_PROXY_HOPS` (défaut `1`) : un hop (Nginx).
- `TRUST_PROXY=10.0.0.0/8,...` : CIDR.
- `TRUST_PROXY=true` est refusé sauf `TRUST_PROXY_ALLOW_TRUE=1` (réseau entièrement privé).

Gate production : vérifier le nombre de hops réel (DigitalOcean / Nginx). Le code est configurable.

## Store

| Env | Store | Effet |
|---|---|---|
| `NODE_ENV=test` ou `RATE_LIMIT_USE_MEMORY=true` | MemoryStore | Isolé par process (OK tests) |
| Production Redis disponible | `rate-limit-redis` préfixe `rl:` | Limite globale multi-worker |
| Redis indisponible | MemoryStore + log | Voir fail policy par catégorie |

## Fail policy (panne store / Redis)

Cela concerne **uniquement le rate limiter HTTP**, jamais l’authentification.

| Catégorie | Politique | Signification | Ce que ce n’est pas |
|---|---|---|---|
| PUBLIC, AUTHENTICATED, ADMIN, UPLOAD, MESSAGE, SMS | **RATE-LIMITER fail-open** | Redis down → la requête n’est pas 429/503 à cause du limiter (log `RATE_LIMIT_STORE_ERROR`) | — |
| AUTH login / register / forgot | **AUTH RATE-LIMITER: fail-open** | Redis down → le *limiter* login ne bloque pas | JWT / credentials / `protect` restent exigés. Redis down ≠ session ouverte |
| OTP send/verify, FINANCIAL, STAFF_MUTATION | **RATE-LIMITER fail-closed** `503 RATE_LIMIT_UNAVAILABLE` | Redis down → action coûteuse refusée | — |

`authentication fail-open` n’existe pas : un token invalide reste 401, un rôle insuffisant reste 403.

Le rate limit n’est **jamais** une autorisation ni une protection anti-double-paiement (idempotence + ownership + state machine restent obligatoires).

## IPv6

Clé = préfixe `/64` (4 hextets, `RATE_LIMIT_IPV6_SUBNET`). Une adresse complète par requête permettrait de saturer un bucket par rotation dans le même préfixe.

## Réponse 429

```json
{ "success": false, "code": "RATE_LIMIT_EXCEEDED", "message": "...", "retryAfter": 42 }
```

Header `Retry-After`. Pas d’OTP / mot de passe dans les logs. Événements : `RATE_LIMIT_HIT`, `AUTH_RATE_LIMIT_HIT`, `OTP_RATE_LIMIT_HIT`, `PAYMENT_RATE_LIMIT_HIT`, `SUSPICIOUS_FORWARDED_IP` (hash IP, route, userId, requestId).

`x-mobile-app` ne skippe aucune policy.

## Policies

| Groupe | Routes (indicatif) | Clé | Fenêtre | Max défaut | Redis | Fail |
|---|---|---|---|---|---|---|
| PUBLIC | `/api/*` catalogue, search, calendar, flutter-check | IP | 15 min | 600 | oui | open |
| AUTH_LOGIN_IP | `POST /api/auth/login` | IP | 15 min | 25 | oui | open |
| AUTH_LOGIN_ACCOUNT | login | email normalisé | 15 min | 8 | oui | open |
| AUTH_REGISTER | register + register-partner | IP | 15 min | 40 | oui | open |
| AUTH_FORGOT_IP + ACCOUNT | forgot-password ; reset-password (IP) | IP + email | 15 min | 8 / 4 | oui | open |
| OTP_SEND_PHONE | request/resend verification | E.164 | 15 min | 4 | oui | closed |
| OTP_SEND_IP | idem | IP (plus large) | 15 min | 20 | oui | closed |
| OTP_VERIFY | verify-code | E.164 | 15 min | 12 | oui | closed |
| AUTHENTICATED | favorites, notifications | userId (IP si anonyme) | 15 min | 400 | oui | open |
| FINANCIAL | `/api/payments`, `/api/payouts` hors webhook | userId+IP | 1 min | 20 | oui | closed |
| ADMIN | `/api/admin`, dashboard, GET superadmin | userId+IP | 15 min | 400 | oui | open |
| STAFF_MUTATION | create/delete admin, role, PUT settings | userId+IP | 15 min | 30 | oui | closed |
| UPLOAD | `/api/media`, pièces jointes messages | userId+IP | 15 min | 40 | oui | open |
| MESSAGE_SEND | POST messages | userId+IP | 1 min | 30 | oui | open |
| SMS_SEND | POST `/api/sms/send` | userId+IP | 1 h | 40 | oui | open |

Webhooks PSP (`/api/payments/webhook`, Wave, CinetPay, payouts) : montés **avant** json + skip limiter utilisateur. Protection = signature / HMAC + idempotence. Pas de bucket login.

OTP métier (en plus du HTTP) : expiration 10 min, compteur 3 tentatives, rejet si déjà `isVerified`, message SMS uniforme (anti-énumération).
