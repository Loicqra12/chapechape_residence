# ADR-003: Gestion des Paiements Multi-Providers

**Statut**: Accepté  
**Date**: 2024  
**Décideurs**: Équipe technique ChapeChape  
**Tags**: paiements, intégration, architecture

## Contexte

Le marché ivoirien nécessite le support de plusieurs méthodes de paiement :
- Mobile Money (MTN, Orange, Moov)
- Wave
- Cartes bancaires (Stripe)
- Cash (sur place)

Contraintes :
- Différentes APIs et formats
- Webhooks asynchrones
- Gestion des échecs et retries
- Conformité PCI-DSS

## Décision

Nous avons implémenté une **architecture de paiements multi-providers** avec une couche d'abstraction.

### Architecture

```
Payment Service (Abstraction)
    ├── CinetPay Service (Mobile Money)
    ├── Wave Service
    ├── Stripe Service
    └── Payment Controller (API)
```

### Implémentation

1. **Service de paiement unifié** (`payment.service.js`)
   - Interface commune pour tous les providers
   - Normalisation des réponses
   - Gestion des erreurs

2. **Services spécialisés**
   - `cinetpay.service.js` - Mobile Money (MTN, Orange, Moov)
   - `wave.service.js` - Wave payments
   - `payment.service.js` - Stripe (cartes bancaires)

3. **Modèle de paiement unifié**
   - Statuts normalisés : `pending`, `processing`, `paid`, `failed`, `refunded`
   - Métadonnées provider dans `paymentDetails`

### Flux de paiement

```
1. Client initie paiement → createPaymentIntent()
2. Service sélectionne provider selon méthode
3. Provider traite paiement (async)
4. Webhook notifie résultat
5. Système met à jour réservation
```

## Conséquences

### Avantages

- ✅ **Flexibilité** : Ajout facile de nouveaux providers
- ✅ **Normalisation** : Interface unique pour tous les paiements
- ✅ **Résilience** : Un provider en panne n'affecte pas les autres
- ✅ **Maintenabilité** : Code isolé par provider

### Inconvénients

- ⚠️ **Complexité** : Plusieurs intégrations à maintenir
- ⚠️ **Tests** : Nécessite mocks pour chaque provider
- ⚠️ **Webhooks** : Gestion asynchrone complexe

### Mitigations

- **Tests** : Services mockés dans les tests unitaires
- **Webhooks** : Idempotence et retry logic
- **Monitoring** : Logs détaillés pour chaque provider

## Alternatives considérées

### Provider unique
- **Rejeté** : Aucun provider ne couvre tous les besoins
- **Raison** : Besoin de flexibilité marché ivoirien

### Gateway de paiement tiers
- **Rejeté** : Coûts supplémentaires, moins de contrôle
- **Raison** : Intégration directe = meilleure expérience

## Références

- `src/services/payment.service.js` - Service de paiement unifié
- `src/services/cinetpay.service.js` - Intégration CinetPay
- `src/services/wave.service.js` - Intégration Wave
- `src/controllers/payment/payment.controller.js` - API paiements
- `src/models/payment.model.js` - Modèle de données






