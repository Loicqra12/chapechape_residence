# ADR-005: Architecture de Services Modulaires

**Statut**: Accepté  
**Date**: 2024  
**Décideurs**: Équipe technique ChapeChape  
**Tags**: architecture, services, séparation-concerns

## Contexte

Le backend nécessite une séparation claire entre :
- Contrôleurs (couche API)
- Services (logique métier)
- Modèles (accès données)

Objectifs :
- Réutilisabilité du code
- Testabilité
- Maintenabilité
- Préparation migration microservices

## Décision

Nous avons adopté une **architecture en couches avec services modulaires**.

### Structure

```
Controller (API Layer)
    ↓
Service (Business Logic)
    ↓
Model (Data Access)
    ↓
Database (MongoDB)
```

### Principes

1. **Contrôleurs minces**
   - Validation des entrées
   - Appels aux services
   - Formatage des réponses
   - Gestion des erreurs HTTP

2. **Services épais**
   - Toute la logique métier
   - Orchestration entre modèles
   - Appels à services externes
   - Transactions

3. **Modèles simples**
   - Définition des schémas
   - Méthodes de base (CRUD)
   - Validations Mongoose
   - Pas de logique métier

### Exemple

```javascript
// Controller (mince)
exports.createReservation = asyncHandler(async (req, res) => {
  const reservation = await reservationService.createReservation({
    ...req.body,
    user: req.user._id
  });
  res.status(201).json({ success: true, data: reservation });
});

// Service (épais)
exports.createReservation = async (data) => {
  // Validation métier
  // Vérification disponibilité
  // Calcul prix
  // Création réservation
  // Notification
  // Retour résultat
};
```

## Conséquences

### Avantages

- ✅ **Réutilisabilité** : Services utilisables par plusieurs contrôleurs
- ✅ **Testabilité** : Services testables indépendamment
- ✅ **Maintenabilité** : Logique centralisée
- ✅ **Migration** : Services prêts pour microservices

### Inconvénients

- ⚠️ **Couches supplémentaires** : Légère complexité
- ⚠️ **Coordination** : Nécessite discipline équipe

### Services clés

- `reservation.service.js` - Logique réservations
- `payment.service.js` - Logique paiements
- `pricing.service.js` - Calculs de prix
- `notification.service.js` - Notifications
- `socket.service.js` - WebSocket
- `payout.service.js` - Paiements partenaires

## Alternatives considérées

### Contrôleurs épais
- **Rejeté** : Logique dupliquée, difficile à tester
- **Raison** : Services = meilleure organisation

### Services monolithiques
- **Rejeté** : Services trop gros, faible réutilisabilité
- **Raison** : Services modulaires = meilleure granularité

## Références

- `src/services/` - Tous les services
- `src/controllers/` - Contrôleurs utilisant les services
- `src/models/` - Modèles de données





