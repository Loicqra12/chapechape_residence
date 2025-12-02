# ADR-002: Authentification JWT avec Refresh Tokens

**Statut**: Accepté  
**Date**: 2024  
**Décideurs**: Équipe technique ChapeChape  
**Tags**: sécurité, authentification, jwt

## Contexte

Le système nécessite une authentification sécurisée pour :
- Clients mobiles (Flutter)
- Partenaires (Flutter)
- Dashboard web (React)
- API REST

Les contraintes :
- Pas de sessions serveur (stateless)
- Support multi-plateformes
- Sécurité renforcée
- Rotation des clés

## Décision

Nous avons implémenté un système d'authentification **JWT avec refresh tokens** et **rotation des clés**.

### Architecture

1. **Access Token (JWT)**
   - Durée de vie courte (configurable, défaut: 1h)
   - Contient : `id`, `role`
   - Stocké côté client (localStorage/memory)
   - Inclus dans header `Authorization: Bearer <token>`

2. **Refresh Token**
   - Durée de vie longue (configurable, défaut: 7 jours)
   - Stocké côté client (secure storage)
   - Utilisé uniquement pour obtenir un nouveau access token

3. **Rotation des clés**
   - Système de rotation automatique des secrets JWT
   - Support des clés actives et précédentes (transition)
   - Gestion via `keyRotation.js`

### Implémentation

```javascript
// Génération des tokens
const accessToken = jwt.generateAccessToken(userId, role);
const refreshToken = jwt.generateRefreshToken(userId);

// Vérification avec support rotation
const decoded = jwt.verifyToken(token, 'JWT_SECRET');
```

### Middleware de protection

```javascript
// Protection des routes
router.get('/protected', protect, authorize('admin'), controller);
```

## Conséquences

### Avantages

- ✅ **Stateless** : Pas de session serveur, scalable
- ✅ **Sécurité** : Tokens signés, expiration automatique
- ✅ **Multi-plateformes** : Compatible mobile et web
- ✅ **Rotation des clés** : Sécurité renforcée
- ✅ **Refresh automatique** : Expérience utilisateur fluide

### Inconvénients

- ⚠️ **Révocation difficile** : Tokens valides jusqu'à expiration
- ⚠️ **Taille des tokens** : Payload limité
- ⚠️ **Complexité** : Gestion de deux types de tokens

### Mitigations

- **Révocation** : Blacklist Redis pour tokens révoqués (optionnel)
- **Taille** : Payload minimal (id + role uniquement)
- **Complexité** : Utilitaires centralisés dans `utils/jwt.js`

## Alternatives considérées

### Sessions classiques
- **Rejeté** : Nécessite stockage serveur, moins scalable
- **Raison** : Architecture stateless préférée

### OAuth 2.0 complet
- **Rejeté** : Complexité trop élevée pour nos besoins
- **Raison** : JWT simple suffit pour notre cas d'usage

### JWT simple (sans refresh)
- **Rejeté** : Tokens longs = risque sécurité, tokens courts = UX dégradée
- **Raison** : Refresh tokens = meilleur compromis

## Références

- `src/utils/jwt.js` - Implémentation JWT
- `src/utils/keyRotation.js` - Rotation des clés
- `src/middlewares/auth.middleware.js` - Middleware d'authentification
- `src/controllers/auth/auth.controller.js` - Endpoints d'authentification






