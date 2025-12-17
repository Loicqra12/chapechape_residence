# 🔐 Authentification Mobile HMAC - Guide d'Implémentation

**Date:** 9 Décembre 2025  
**Version:** 1.0.0  
**Statut:** ✅ Implémenté

---

## 📋 Vue d'Ensemble

Le backend ChapeChape utilise des **signatures HMAC-SHA256** pour authentifier les requêtes des applications mobiles (Flutter/React Native) au lieu du système CSRF traditionnel.

### Pourquoi HMAC ?

- ✅ **Plus sécurisé** que User-Agent ou Content-Type (facilement forgeable)
- ✅ **Empêche les attaques CSRF** sur les apps mobiles
- ✅ **Vérifie l'intégrité** de la requête
- ✅ **Timestamp** pour éviter replay attacks

---

## 🔧 Configuration Backend

### 1. Variable d'Environnement

Ajouter dans `.env` :

```bash
# Secret partagé pour signer les requêtes mobiles
MOBILE_APP_SECRET=your-super-secret-key-min-32-chars-recommended

# Exemple pour générer un secret sécurisé:
# node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

⚠️ **IMPORTANT:** Ce secret doit être identique dans le backend et les apps mobiles !

---

## 📱 Implémentation Flutter (Client & Partner Apps)

### 1. Créer le Service HMAC

**Fichier:** `lib/services/hmac_service.dart`

```dart
import 'dart:convert';
import 'package:crypto/crypto.dart';

class HMACService {
  // ⚠️ SECRET: Doit correspondre à MOBILE_APP_SECRET du backend
  static const String _secret = 'your-super-secret-key-min-32-chars-recommended';
  
  // Clé API unique pour l'app
  static const String apiKey = 'chapechape-client-v1.3.1';
  
  /// Génère une signature HMAC-SHA256
  /// Format: HMAC-SHA256(apiKey:path:timestamp, secret)
  static String generateSignature(String path, String timestamp) {
    final payload = '$apiKey:$path:$timestamp';
    final key = utf8.encode(_secret);
    final bytes = utf8.encode(payload);
    
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    
    return digest.toString();
  }
  
  /// Génère les headers d'authentification mobile
  static Map<String, String> getAuthHeaders(String path) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final signature = generateSignature(path, timestamp);
    
    return {
      'X-API-Key': apiKey,
      'X-Mobile-Signature': signature,
      'X-Timestamp': timestamp,
    };
  }
}
```

### 2. Installation de la dépendance

**Fichier:** `pubspec.yaml`

```yaml
dependencies:
  crypto: ^3.0.3  # Pour HMAC-SHA256
```

```bash
flutter pub get
```

### 3. Utiliser dans les Requêtes HTTP

**Exemple avec Dio:**

```dart
import 'package:dio/dio.dart';
import '../services/hmac_service.dart';

class ApiService {
  final Dio _dio = Dio();
  
  Future<Response> post(String path, dynamic data) async {
    // Ajouter les headers HMAC
    final headers = HMACService.getAuthHeaders(path);
    
    return await _dio.post(
      'https://api.chapechaperesidence.com$path',
      data: data,
      options: Options(headers: headers),
    );
  }
  
  // Exemple: Login
  Future<void> login(String email, String password) async {
    final response = await post('/api/auth/login', {
      'email': email,
      'password': password,
    });
    
    // ✅ Requête authentifiée via HMAC, CSRF bypass autorisé
  }
}
```

**Exemple avec http package:**

```dart
import 'package:http/http.dart' as http;
import '../services/hmac_service.dart';

Future<http.Response> authenticatedPost(String path, Map<String, dynamic> body) async {
  final headers = HMACService.getAuthHeaders(path);
  headers['Content-Type'] = 'application/json';
  
  return await http.post(
    Uri.parse('https://api.chapechaperesidence.com$path'),
    headers: headers,
    body: jsonEncode(body),
  );
}
```

---

## 🧪 Tests d'Intégration

### Test 1: Signature Valide

```dart
void main() async {
  final service = HMACService();
  final path = '/api/auth/login';
  final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
  
  final signature = HMACService.generateSignature(path, timestamp);
  
  print('✅ Signature générée: $signature');
  print('✅ API Key: ${HMACService.apiKey}');
  print('✅ Timestamp: $timestamp');
  
  // Test requête
  final response = await authenticatedPost(path, {
    'email': 'test@test.com',
    'password': 'password123',
  });
  
  print('Status: ${response.statusCode}'); // Devrait être 200 ou 401 (pas 403 CSRF)
}
```

### Test 2: Signature Invalide (Devrait échouer)

```dart
final badHeaders = {
  'X-API-Key': 'wrong-key',
  'X-Mobile-Signature': 'invalid-signature',
  'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
};

// Devrait retourner 401 Unauthorized
```

### Test 3: Timestamp Expiré (Devrait échouer)

```dart
final oldTimestamp = (DateTime.now().millisecondsSinceEpoch - 6 * 60 * 1000).toString(); // 6 min ago
final headers = HMACService.getAuthHeaders('/api/auth/login');
headers['X-Timestamp'] = oldTimestamp; // Override avec ancien timestamp

// Devrait retourner 401 (signature expirée > 5min)
```

---

## 🔒 Sécurité

### Protection Timestamp (Anti-Replay)

- ✅ Signature valide **maximum 5 minutes**
- ✅ Empêche la réutilisation d'anciennes requêtes
- ✅ Clock skew toléré (abs diff)

### Timing-Safe Comparison

Le backend utilise `crypto.timingSafeEqual()` pour éviter les **timing attacks** lors de la vérification des signatures.

### Secret Management

**⚠️ NE JAMAIS:**
- Commit le secret dans Git
- Hardcoder le secret en production
- Exposer le secret dans les logs

**✅ RECOMMANDÉ:**
- Utiliser des variables d'environnement
- Rotation régulière du secret (tous les 6 mois)
- Secrets différents par environnement (dev/staging/prod)

---

## 📊 Logs Backend

### Authentification Réussie

```
info: Mobile app authenticated {
  "apiKey": "chapechape-client-v1.3.1",
  "path": "/api/auth/login",
  "method": "POST"
}
```

### Authentification Échouée

```
warn: Invalid mobile signature {
  "apiKey": "chapechape-client-v1.3.1",
  "path": "/api/auth/login",
  "ip": "192.168.1.100",
  "userAgent": "Dart/3.2 (dart:io)"
}
```

### Signature Expirée

```
warn: Signature expired {
  "now": 1702148640000,
  "requestTime": 1702148300000,
  "diff": 340000
}
```

---

## 🚀 Migration des Apps Existantes

### Étape 1: Ajouter le Service HMAC

Créer `hmac_service.dart` comme ci-dessus.

### Étape 2: Wrapper les Requêtes API

```dart
// Avant
http.post('/api/auth/login', ...);

// Après
authenticatedPost('/api/auth/login', ...);
```

### Étape 3: Tester en Développement

```bash
# Vérifier les logs backend
npm run dev

# Logs attendus:
# ✅ "Mobile app authenticated"
```

### Étape 4: Déployer

1. Mettre à jour le backend avec `MOBILE_APP_SECRET`
2. Déployer la nouvelle version des apps
3. Forcer la mise à jour (optionnel mais recommandé)

---

## ❓ FAQ

### Q: Que se passe-t-il si je change le secret ?

R: ⚠️ **Toutes les apps actuelles seront déconnectées** jusqu'à mise à jour avec le nouveau secret. Planifier une rotation progressive:

1. Maintenir l'ancien secret pendant 2 semaines
2. Forcer la mise à jour des apps
3. Après 2 semaines, supprimer l'ancien secret

### Q: Puis-je avoir plusieurs API Keys ?

R: ✅ Oui ! Différentes versions ou apps peuvent avoir des clés différentes:

```dart
// Client App
static const String apiKey = 'chapechape-client-v1.3.1';

// Partner App
static const String apiKey = 'chapechape-partner-v1.3.1';
```

### Q: Comment déboguer les erreurs de signature ?

R: Vérifier dans l'ordre:

1. ✅ Secret identique backend/app
2. ✅ Path exact (inclut `/api/...`)
3. ✅ Timestamp récent (< 5min)
4. ✅ Format hexadécimal de la signature

### Q: Performance impact ?

R: ⚡ **Négligeable** - HMAC-SHA256 prend ~1ms

---

## ✅ Checklist Déploiement

- [ ] Variable `MOBILE_APP_SECRET` configurée en production
- [ ] Service HMAC implémenté dans app Flutter
- [ ] Tests d'intégration passent
- [ ] Logs backend fonctionnels
- [ ] Documentation partagée avec équipe mobile
- [ ] Plan de migration défini
- [ ] Backup de l'ancien système (si migration)

---

**Prochaine étape:** Implémenter dans les apps mobiles et tester !
