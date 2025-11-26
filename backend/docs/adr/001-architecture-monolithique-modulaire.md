# ADR-001: Architecture Monolithique Modulaire

**Statut**: Accepté  
**Date**: 2024  
**Décideurs**: Équipe technique ChapeChape  
**Tags**: architecture, structure, organisation

## Contexte

ChapeChape Residence est une plateforme de réservation de logements nécessitant :
- Gestion des utilisateurs (clients, partenaires, admins)
- Gestion des résidences et disponibilités
- Système de réservations et paiements
- Notifications en temps réel
- Analytics et reporting

Au démarrage, nous devions choisir entre :
1. Architecture microservices complète
2. Architecture monolithique modulaire
3. Architecture hybride

## Décision

Nous avons choisi une **architecture monolithique modulaire** avec une structure organisée par domaines métier.

### Structure adoptée

```
backend/
├── src/
│   ├── controllers/     # Contrôleurs organisés par domaine
│   │   ├── auth/
│   │   ├── residence/
│   │   ├── reservation/
│   │   ├── payment/
│   │   └── partner/
│   ├── models/          # Modèles MongoDB
│   ├── services/        # Logique métier isolée
│   ├── routes/          # Routes Express
│   ├── middlewares/     # Middleware réutilisables
│   ├── validations/     # Schémas de validation Joi
│   └── utils/           # Utilitaires partagés
```

### Principes

1. **Séparation des responsabilités** : Chaque couche a un rôle clair
2. **Services réutilisables** : Logique métier isolée dans des services
3. **Modularité** : Organisation par domaines métier
4. **Évolutivité** : Structure prête pour une migration vers microservices

## Conséquences

### Avantages

- ✅ **Simplicité de déploiement** : Un seul service à déployer
- ✅ **Développement rapide** : Pas de complexité réseau inter-services
- ✅ **Transactions ACID** : MongoDB garantit la cohérence
- ✅ **Debugging facilité** : Tout le code au même endroit
- ✅ **Performance** : Pas de latence réseau entre services

### Inconvénients

- ⚠️ **Scalabilité limitée** : Un seul point de montée en charge
- ⚠️ **Couplage** : Services partagent la même base de données
- ⚠️ **Déploiement** : Un changement nécessite le redéploiement complet

### Migration future

La structure modulaire facilite une migration future vers microservices :
- Services déjà isolés dans `src/services/`
- Contrôleurs organisés par domaine
- Interfaces claires entre modules

## Alternatives considérées

### Microservices
- **Rejeté** : Complexité trop élevée pour la phase initiale
- **Raison** : Équipe petite, besoin de rapidité de développement

### Monolithique simple
- **Rejeté** : Pas de séparation claire des responsabilités
- **Raison** : Difficulté de maintenance à long terme

## Références

- [MICROSERVICES_STRATEGY.md](../../MICROSERVICES_STRATEGY.md) - Stratégie de migration future
- [README.md](../../README.md) - Documentation générale





