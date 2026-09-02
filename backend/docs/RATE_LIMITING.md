> **P2-02F** : politiques à jour dans [`docs/P2_02F_RATE_LIMIT_POLICY.md`](../../docs/P2_02F_RATE_LIMIT_POLICY.md) (trust proxy, clés IP vs userId, Redis, fail-open/closed). Les chiffres ci-dessous (100/5/3) sont **obsolètes**.

**Date:** 9 Décembre 2025  
**Version:** 1.0.0  
**Statut:** ✅ Implémenté et Fonctionnel

---

## 📋 Vue d'Ensemble

Le backend ChapeChape utilise un **système de rate limiting multi-niveaux** pour protéger l'API contre :
- 🚫 Attaques par force brute (login, etc.)
- 🚫 Abus de paiements
- 🚫 Surcharge serveur (DoS)
- 🚫 Scraping massif de données

### Architecture

```
                    ┌─────────────────────┐
                    │   Client Request    │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Global Limiter     │
                    │   100 req/15min     │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
         ┌──────────┤  Route Spécifique   ├──────────┐
         │          └─────────────────────┘          │
         │                                            │
┌────────▼────────┐  ┌──────────────┐  ┌────────────▼────────┐
│  Auth Limiter   │  │ User Limiter │  │  Payment Limiter    │
│   5 req/15min   │  │ 100req/15min │  │    3 req/1min       │
└─────────────────┘  └──────────────┘  └─────────────────────┘
```

---

## 🎯 Les 5 Rate Limiters

### 1️⃣ **Global Limiter** (Toutes les routes)

**Limite:** 100 requêtes / 15 minutes par IP  
**Routes:** `/api/*` (toutes les routes sauf health checks)

```javascript
// Appliqué automatiquement à toutes les routes
GET  /api/residences      ✅ Comptabilisé
POST /api/bookings        ✅ Comptabilisé
GET  /api/health          ⛔ Exclu (health check)
GET  /api/ping            ⛔ Exclu (monitoring)
```

**Réponse si dépassé:**
```json
{
  "success": false,
  "message": "Trop de requêtes, veuillez réessayer dans 15 minutes",
  "retryAfter": 900
}
```

---

### 2️⃣ **Auth Limiter** (Authentification)

**Limite:** 5 requêtes / 15 minutes par IP  
**Routes:**
- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/register-partner`

**Comportement:**
- ✅ Ne compte QUE les **échecs** (`skipSuccessfulRequests: true`)
- ❌ 5 tentatives échouées = blocage 15min
- ✅ Connexion réussie = compteur réinitialisé

**Exemple:**
```javascript
// Tentative 1-5 avec mauvais mot de passe
POST /api/auth/login  ❌ (compteur: 1, 2, 3, 4, 5)

// Tentative 6
POST /api/auth/login  🚫 429 Too Many Requests

// 15 minutes plus tard
POST /api/auth/login  ✅ Autorisé à nouveau
```

---

### 3️⃣ **Payment Limiter** (Paiements)

**Limite:** 3 requêtes / 1 minute par IP  
**Routes:** `/api/payments/*`

**Raison:** Très strict pour éviter :
- Tentatives de fraude
- Double/triple paiement
- Abus de gateway de paiement

**Réponse si dépassé:**
```json
{
  "success": false,
  "message": "Trop de tentatives de paiement. Veuillez patienter 1 minute.",
  "retryAfter": 60
}
```

---

### 4️⃣ **User Limiter** (Par utilisateur)

**Limite:** 100 requêtes / 15 minutes  
**Clé:** User ID si authentifié, sinon IP

**Différence avec Global:**
- ✅ Global = limite par IP (tous utilisateurs confondus)
- ✅ User = limite par utilisateur authentifié

**Exemple:**
```javascript
// 3 utilisateurs sur même IP (bureau, WiFi public)
User A (ID: 123) → 100 req/15min ✅
User B (ID: 456) → 100 req/15min ✅
User C (ID: 789) → 100 req/15min ✅
Total sur IP → 300 req/15min (mais ✅ OK car 3 users différents)

// Sans auth (même IP)
Anonymous → 100 req/15min ✅ (basé sur IP)
```

---

### 5️⃣ **Upload Limiter** (Fichiers)

**Limite:** 10 uploads / 15 minutes  
**Routes:** Routes d'upload de fichiers

**Protection contre:**
- Spam d'images
- Saturation storage
- Abus de bande passante

---

## 🔧 Configuration Technique

### Store Redis (Production)

```javascript
// En production, utilise Redis pour partage entre instances
const store = new RedisStore({
  client: redisClient,
  prefix: 'rl:global:',
  sendCommand: (...args) => redisClient.call(...args)
});
```

**Avantages:**
- ✅ Partage des compteurs entre toutes les instances PM2
- ✅ Persistance en cas de redémarrage
- ✅ Performance élevée

### Memory Store (Développement)

```javascript
// En dev, utilise mémoire (Redis Mock)
store: undefined  // express-rate-limit utilise MemoryStore
```

**Logs visibles:**
```
info: Rate limiter "global" using memory store (dev mode)
info: Rate limiter "auth" using memory store (dev mode)
```

---

## 🧪 Tests

### Test 1: Global Rate Limit

```bash
# Faire 101 requêtes rapides
for i in {1..101}; do
  curl http://localhost:5000/api/residences
done

# Requête 101 devrait retourner 429
```

### Test 2: Auth Rate Limit

```bash
# 6 tentatives login échouées
for i in {1..6}; do
  curl -X POST http://localhost:5000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"wrong"}'
done

# 6ème devrait retourner 429
```

### Test 3: Payment Rate Limit

```bash
# 4 requêtes paiement en 1 minute
for i in {1..4}; do
  curl -X POST http://localhost:5000/api/payments \
    -H "Authorization: Bearer TOKEN"
done

# 4ème devrait retourner 429
```

---

## 📊 Monitoring

### Logs Générés

```javascript
// Violation de rate limit
warn: Global rate limit exceeded: 192.168.1.100 - GET /api/residences

warn: Auth rate limit exceeded: 192.168.1.100 - POST /api/auth/login

warn: Payment rate limit exceeded: 192.168.1.100 - POST /api/payments
```

### Headers HTTP

Toutes les réponses incluent:
```
RateLimit-Limit: 100
RateLimit-Remaining: 87
RateLimit-Reset: 1702148520
```

---

## 🔐 Sécurité

### Bypass Protection

⚠️ **Les rate limiters NE SONT PAS bypassables via:**
- Headers User-Agent
- Content-Type
- X-Forwarded-For (IP source = req.ip de Express)

✅ **Seules exceptions:**
- Health checks (`/api/health`, `/api/ping`)
- Uniquement pour monitoring, pas pour API métier

---

## 🚀 Déploiement

### Variables d'Environnement

```bash
# Production - Utiliser vrai Redis
NODE_ENV=production
REDIS_URL=redis://localhost:6379

# Développement - Utiliser Redis Mock
NODE_ENV=development
```

### PM2 Cluster Mode

```javascript
// ecosystem.config.js
instances: 4  // ✅ Rate limiting fonctionne avec Redis partagé
```

Tous les workers PM2 partagent les mêmes compteurs via Redis.

---

## 📈 Ajustements Futurs

### Si trop de 429 en production

```javascript
// Augmenter les limites dans rate-limit.middleware.js
const globalLimiter = rateLimit({
  max: 200  // Au lieu de 100
});
```

### Whitelist IPs

```javascript
const globalLimiter = rateLimit({
  skip: (req) => {
    const whitelist = ['192.168.1.1', '10.0.0.1'];
    return whitelist.includes(req.ip);
  }
});
```

---

## ✅ Checklist Validation

- [x] Middleware créé et testé
- [x] 5 limiters configurés
- [x] Fallback mémoire en dev
- [x] Redis prêt pour production
- [x] Logs de violations
- [x] Headers standards
- [x] Documentation complète
- [ ] Tests load testing
- [ ] Monitoring dashboard

---

**Prochaine étape:** Tests avec serveur live et ajustements si nécessaire.
