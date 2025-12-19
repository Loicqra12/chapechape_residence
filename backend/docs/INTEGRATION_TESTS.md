# 🧪 Guide des Tests d'Intégration Sécurité

**Date:** 9 Décembre 2025  
**Version:** 1.0.0

---

## 📋 Vue d'Ensemble

Suite de tests d'intégration complète pour valider toutes les améliorations de sécurité implémentées dans le backend ChapeChape.

## 🚀 Exécution des Tests

### Installation des dépendances

```bash
npm install --save-dev supertest
```

### Lancer tous les tests

```bash
node tests/integration/security.test.js
```

Ou avec npm:

```bash
npm test
```

---

## 📊 Suites de Tests

### Suite 1: Rate Limiting (3 tests)

**Tests:**
1. ✅ Global rate limit headers présents
2. ✅ Auth rate limit strict (5 échecs/15min)
3. ✅ Rate limit headers correctement définis

**Validation:**
- Limite globale: 100 req/15min
- Limite auth: 5 échecs/15min
- Headers: `RateLimit-Limit`, `RateLimit-Remaining`, `RateLimit-Reset`

---

### Suite 2: CSRF Protection (4 tests)

**Tests:**
1. ✅ CSRF token requis pour routes sensibles
2. ✅ Bypass Content-Type supprimé (vulnérabilité corrigée)
3. ✅ Mobile auth HMAC accepté avec signature valide
4. ✅ Signature HMAC expirée rejetée (> 5min)

**Validation:**
- Routes protégées retournent 403 sans CSRF
- Content-Type ne bypass plus CSRF
- HMAC valide autorisé
- HMAC expiré (> 5min) rejeté avec 401

---

### Suite 3: Error Handling (3 tests)

**Tests:**
1. ✅ Stack trace supprimée des réponses
2. ✅ Messages génériques en production
3. ✅ Codes d'erreur structurés (format: DOMAINE_ACTION_RAISON)

**Validation:**
- Pas de stack trace dans réponses HTTP
- Messages génériques si NODE_ENV=production
- Tous les codes au format standardisé

---

### Suite 4: Timing Attack Prevention (2 tests)

**Tests:**
1. ✅ Temps de réponse constant (user existe vs non)
2. ✅ Délai aléatoire appliqué (50-150ms)

**Validation:**
- Différence timing < 100ms
- Délai minimum 50ms observé
- Pas d'énumération des comptes possible

---

### Suite 5: Input Validation (3 tests)

**Tests:**
1. ✅ Email validation accepte TLDs modernes (.technology, .museum, .info)
2. ✅ Email normalisation (lowercase, trim)
3. ✅ Emails invalides rejetés

**Validation:**
- TLDs > 3 caractères acceptés
- Emails normalisés automatiquement
- Emails malformés rejetés
avec 400

---

## 📈 Résultats Attendus

```
==============================================================
🔒 TESTS D'INTÉGRATION SÉCURITÉ BACKEND
==============================================================

📊 TEST SUITE 1: Rate Limiting

🧪 Global rate limit (100 req/15min)
✅ PASS: Global rate limit (100 req/15min)

🧪 Auth rate limit (5 échecs/15min)
✅ PASS: Auth rate limit (5 échecs/15min)

🧪 Rate limit headers correctement définis
✅ PASS: Rate limit headers correctement définis


📊 TEST SUITE 2: CSRF Protection

🧪 CSRF token requis (sans mobile auth)
✅ PASS: CSRF token requis (sans mobile auth)

🧪 Bypass Content-Type supprimé (vulnérabilité corrigée)
✅ PASS: Bypass Content-Type supprimé (vulnérabilité corrigée)

🧪 Mobile auth HMAC accepté
✅ PASS: Mobile auth HMAC accepté

🧪 Signature HMAC expirée rejetée (> 5min)
✅ PASS: Signature HMAC expirée rejetée (> 5min)


📊 TEST SUITE 3: Error Handling

🧪 Stack trace supprimée des réponses
✅ PASS: Stack trace supprimée des réponses

🧪 Messages d'erreur génériques en production
✅ PASS: Messages d'erreur génériques en production

🧪 Codes d'erreur structurés présents
✅ PASS: Codes d'erreur structurés présents


📊 TEST SUITE 4: Timing Attack Prevention

🧪 Temps réponse constant (user existe vs non)
✅ PASS: Temps réponse constant (user existe vs non)

🧪 Délai aléatoire appliqué (50-150ms)
✅ PASS: Délai aléatoire appliqué (50-150ms)


📊 TEST SUITE 5: Input Validation

🧪 Email validation accepte TLDs modernes
✅ PASS: Email validation accepte TLDs modernes

🧪 Email normalisation (lowercase, trim)
✅ PASS: Email normalisation (lowercase, trim)

🧪 Emails invalides rejetés
✅ PASS: Emails invalides rejetés


==============================================================
📊 RÉSUMÉ DES TESTS
==============================================================
Total: 15
Passés: 15
Échoués: 0
Taux de réussite: 100.0%
==============================================================
```

---

## 🔧 Troubleshooting

### Erreur: "Cannot find module 'supertest'"

```bash
npm install --save-dev supertest
```

### Tests timeout

Augmenter le timeout dans le script:

```javascript
jest.setTimeout(10000); // 10 secondes
```

### Rate limit atteint pendant tests

Attendre 15 minutes ou redémarrer le serveur pour réinitialiser les compteurs.

### HMAC signature fails

Vérifier que `MOBILE_APP_SECRET` est défini dans `.env`:

```bash
MOBILE_APP_SECRET=test-secret-key
```

---

## 📝 Ajouter de Nouveaux Tests

### Template de test

```javascript
await runTest('Description du test', async () => {
  const response = await request(app)
    .get('/api/endpoint')
    .expect(200);
  
  if (!response.body.expectedField) {
    throw new Error('Validation failed');
  }
});
```

### Nouvelle suite de tests

```javascript
async function testNewFeature() {
  log.info('\n📊 TEST SUITE X: New Feature\n');
  
  await runTest('Test 1', async () => {
    // Test logic
  });
  
  await runTest('Test 2', async () => {
    // Test logic
  });
}

// Ajouter dans runAllTests()
await testNewFeature();
```

---

## ✅ Checklist Pré-Production

- [ ] Tous les tests passent (15/15)
- [ ] Taux de réussite: 100%
- [ ] Aucun warning critique
- [ ] Tests timing attacks < 100ms diff
- [ ] HMAC signatures validées
- [ ] Rate limiting fonctionnel
- [ ] Error handling sécurisé

---

**Tests:** 15  
**Couverture:** Rate Limiting, CSRF, Error Handling, Timing Attacks, Input Validation  
**Statut:** ✅ Production-Ready
