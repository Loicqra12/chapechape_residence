# 🛡️ Error Handling Sécurisé - Documentation

**Date:** 9 Décembre 2025  
**Version:** 1.0.0  
**Statut:** ✅ Implémenté

---

## 📋 Vue d'Ensemble

Le système de gestion d'erreurs sécurisé empêche les **fuites d'informations sensibles** via les erreurs, tout en fournissant des **logs détaillés** pour le debugging côté serveur.

### Principe de Sécurité

**❌ Problème (Avant):**
```javascript
// Stack trace exposée dans la réponse
{
  "error": "MongoError: connection failed to localhost:27017",
  "stack": "at Connection.connect (/app/node_modules/mongoose/...) \n..."
}
```

**✅ Solution (Après):**
```javascript
// Production - Message générique
{
  "success": false,
  "message": "Une erreur inattendue s'est produite. Nos équipes ont été notifiées.",
  "errorCode": "GENERAL_SERVER_ERROR"
}

// Développement - Plus de détails mais sanitisés
{
  "success": false,
  "message": "MongoError: connection failed",
  "errorCode": "GENERAL_SERVER_ERROR",
  "stack": "[DISPONIBLE AVEC SHOW_STACK=true]"
}
```

---

## 🔧 Configuration

### Variables d'Environnement

```bash
# .env
NODE_ENV=production  # 'production' ou 'development'
SHOW_STACK=false     # Afficher stack traces même en dev (debug avancé)
```

---

## 📊 Types d'Erreurs

### 1️⃣ Erreurs Opérationnelles (Attendues)

**Exemples:**
- Validation échouée (email invalide)
- Ressource non trouvée (404)
- Token expiré (401)
- Permissions insuffisantes (403)

**Traitement:**
```javascript
// Message préservé, détails fournis
{
  "success": false,
  "message": "Email invalide",
  "errorCode": "GENERAL_VALIDATION_ERROR",
  "errors": [{
    "field": "email",
    "message": "Format email invalide"
  }]
}
```

### 2️⃣ Erreurs de Programmation (Bugs)

**Exemples:**
- TypeError, ReferenceError
- Erreurs de connexion DB non gérées
- Null pointer exceptions

**Traitement en Production:**
```javascript
// Message générique - Pas d'infos sensibles
{
  "success": false,
  "message": "Une erreur inattendue s'est produite. Nos équipes ont été notifiées.",
  "errorCode": "GENERAL_SERVER_ERROR"
}

// Log serveur complet pour debug
logger.error('🚨 NON-OPERATIONAL ERROR (BUG):', {
  message: 'Cannot read property "x" of undefined',
  stack: 'TypeError: Cannot read property...',
  name: 'TypeError'
});
```

---

## 🔒 Sanitisation des Messages

### Informations Masquées

```javascript
const { sanitizeMessage } = require('../utils/sanitize-error');

// Avant sanitisation
"Error connecting to /home/user/app/database.js at 192.168.1.100"

// Après sanitisation
"Error connecting to [PATH]/database.js at [IP]"
```

**Patterns masqués:**
- ✅ Chemins fichiers → `[PATH]`
- ✅ Adresses IP → `[IP]`
- ✅ Tokens/secrets (32+ chars hex) → `[TOKEN]`
- ✅ Emails → `[EMAIL]`

---

## 📝 Logs Sécurisés

### Avant (Vulnérable)

```javascript
logger.error(`${err.name}: ${err.message}\n${err.stack}`);
// ❌ Stack trace dans les logs publics
```

### Après (Sécurisé)

```javascript
const safeErrorInfo = extractSafeErrorInfo(err, req);
logger.error('Error occurred:', safeErrorInfo);

// Log structure
{
  name: 'TypeError',
  message: 'Cannot read property...',
  code: 'GENERAL_SERVER_ERROR',
  statusCode: 500,
  timestamp: '2025-12-09T21:00:00.000Z',
  request: {
    method: 'POST',
    path: '/api/auth/login',
    ip: '192.168.1.100',
    userAgent: 'Mozilla/5.0...',
    userId: '507f1f77bcf86cd799439011'
  },
  stack: '[ONLY IN DEV]'
}
```

---

## 🧪 Tests

### Test 1: Erreur Opérationnelle (400)

```javascript
const ApiError = require('./utils/apiError');

// Lancer une erreur validation
throw new ApiError('Email invalide', 400, 'GENERAL_VALIDATION_ERROR');

// Réponse attendue
{
  "success": false,
  "message": "Email invalide",  // ✅ Message préservé
  "errorCode": "GENERAL_VALIDATION_ERROR"
}
```

### Test 2: Erreur Bug (500) - Production

```javascript
// Lancer une erreur non gérée
throw new Error('Database connection failed at localhost:27017');

// Réponse attendue (production)
{
  "success": false,
  "message": "Une erreur inattendue s'est produite. Nos équipes ont été notifiées.",  // ✅ Générique
  "errorCode": "GENERAL_SERVER_ERROR"
}

// Log serveur
{
  message: 'Database connection failed at localhost:27017',  // ✅ Complet
  stack: 'Error: ...',  // ✅ Stack complète
  name: 'Error'
}
```

### Test 3: Stack Trace Contrôlée

```bash
# En développement sans SHOW_STACK
NODE_ENV=development SHOW_STACK=false

# Réponse
{
  "message": "...",
  "stack": undefined  // ✅ Pas de stack même en dev
}

# Avec SHOW_STACK=true (debug avancé)
NODE_ENV=development SHOW_STACK=true

# Réponse
{
  "message": "...",
  "stack": "Error: ..."  // ✅ Stack visible
}
```

---

## 🎯 Codes d'Erreur Structurés

Tous les codes suivent le format `DOMAINE_ACTION_RAISON` :

```javascript
// Exemples
errorCodes.GENERAL.VALIDATION_ERROR       // 'GENERAL_VALIDATION_ERROR'
errorCodes.AUTH.INVALID_CREDENTIALS       // 'AUTH_INVALID_CREDENTIALS'
errorCodes.PAYMENT.CARD_DECLINED          // 'PAYMENT_CARD_DECLINED'
errorCodes.BOOKING.DATE_CONFLICT          // 'BOOKING_DATE_CONFLICT'
```

**Avantages:**
- ✅ **Traçabilité** - Logs faciles à filtrer
- ✅ **i18n** - Traduction côté client
- ✅ **Analytics** - Métriques par type d'erreur
- ✅ **APIs externes** - Codes machines stables

---

## 📊 Monitoring

### Alertes Automatiques

```javascript
// Erreurs 5xx déclenchent alerts (via Sentry/NewRelic)
if (error.statusCode >= 500) {
  Sentry.captureException(error);
}
```

### Métriques Recommandées

| Métrique | Seuil Alerte |
|----------|--------------|
| Taux erreurs 5xx | > 1% |
| Erreurs de programmation | > 0/jour |
| Timeouts DB | > 5/heure |
| Stack traces en prod | 0 (jamais) |

---

## ✅ Checklist Sécurité

- [x] Stack traces supprimées en production
- [x] Messages génériques pour erreurs 5xx (prod)
- [x] Logs complets côté serveur uniquement
- [x] Sanitisation chemins/IPs/tokens/emails
- [x] Codes d'erreur structurés
- [x] Monitoring automatique (Sentry)
- [x] Tests erreurs opérationnelles
- [x] Tests erreurs bugs (5xx)

---

## 🚀 Bonnes Pratiques

### DO ✅

```javascript
// Lancer des erreurs opérationnelles avec codes
throw new ApiError('Resource not found', 404, errorCodes.GENERAL.NOT_FOUND);

// Log avec contexte
logger.error('Payment failed', { userId, amount, provider });

// Vérifier environnement
if (process.env.NODE_ENV === 'production') {
  // Comportement prod
}
```

### DON'T ❌

```javascript
// ❌ Exposer stack traces
res.status(500).json({ error: err.stack });

// ❌ Messages trop détaillés
throw new Error(`DB connection failed at ${dbHost}:${dbPort} with password ${dbPassword}`);

// ❌ Logs sensibles
logger.error('Login failed:', { password: req.body.password });
```

---

**Phase 2B:** ✅ **TERMINÉE**  
**Prochaine phase:** Phase 3 - Timing Attack + Validation
