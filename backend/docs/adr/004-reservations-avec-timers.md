# ADR-004: Système de Réservations avec Timers

**Statut**: Accepté  
**Date**: 2024  
**Décideurs**: Équipe technique ChapeChape  
**Tags**: réservations, business-logic, timers

## Contexte

Le processus de réservation nécessite :
- Gestion des statuts (pending → approved → confirmed → completed)
- Timers pour paiement (expiration si non payé)
- Timers pour approbation (expiration si non approuvé)
- Blocage des dates pendant le processus

Contraintes :
- Atomicité des opérations
- Gestion des expirations
- Notifications en temps réel
- Rollback en cas d'échec

## Décision

Nous avons implémenté un **système de réservations avec timers** utilisant Agenda.js et des services dédiés.

### Architecture

1. **Service de réservation** (`reservation.service.js`)
   - Logique métier centralisée
   - Validation des transitions de statut
   - Gestion des dates bloquées

2. **Service de timers** (`payment-timer.service.js`)
   - Timers pour paiement (TTL configurable)
   - Timers pour approbation
   - Callbacks d'expiration

3. **Service d'état** (`reservation-state.service.js`)
   - Machine à états pour réservations
   - Validation des transitions
   - Historique des changements

4. **Agenda.js** (Jobs schedulés)
   - Jobs pour expirations
   - Jobs pour notifications
   - Jobs pour nettoyage

### Flux de réservation

```
1. Client crée réservation → status: 'pending'
2. Si approval required:
   - Timer approbation démarre (ex: 24h)
   - Partner doit approuver
3. Si approved:
   - Timer paiement démarre (ex: 30min)
   - Client doit payer
4. Si payé:
   - status: 'confirmed'
   - Dates définitivement bloquées
5. Après check-out:
   - status: 'completed'
   - Payout automatique déclenché
```

### Gestion des expirations

```javascript
// Timer de paiement
await paymentTimerService.startPaymentTimer(reservationId, ttlMinutes);

// Expiration automatique
onExpiration: async (reservationId) => {
  await reservationService.cancelReservation(reservationId, 'system', 'Payment timeout');
}
```

## Conséquences

### Avantages

- ✅ **Automatisation** : Expirations gérées automatiquement
- ✅ **Cohérence** : États gérés de manière centralisée
- ✅ **Fiabilité** : Jobs Agenda garantissent l'exécution
- ✅ **Traçabilité** : Historique complet des changements

### Inconvénients

- ⚠️ **Complexité** : Plusieurs services à coordonner
- ⚠️ **Jobs** : Nécessite Agenda.js en production
- ⚠️ **Debugging** : Flux asynchrone plus difficile à tracer

### Mitigations

- **Documentation** : Diagrammes de flux dans la doc
- **Logs** : Logging détaillé à chaque étape
- **Tests** : Tests d'intégration pour chaque flux

## Alternatives considérées

### Timers simples (setTimeout)
- **Rejeté** : Perdus au redémarrage serveur
- **Raison** : Agenda.js = persistance garantie

### Statuts manuels uniquement
- **Rejeté** : Trop d'interventions manuelles
- **Raison** : Automatisation = meilleure UX

## Références

- `src/services/reservation.service.js` - Service de réservation
- `src/services/payment-timer.service.js` - Gestion des timers
- `src/services/reservation-state.service.js` - Machine à états
- `src/services/agenda.service.js` - Jobs schedulés
- `src/controllers/reservation/reservation.controller.js` - API réservations





