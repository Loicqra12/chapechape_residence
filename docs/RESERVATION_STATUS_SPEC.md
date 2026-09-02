# Reservation.status — spécification canonique

Source de vérité : Backend `Reservation.status` (`backend/src/constants/reservation-status.js`).

Ne pas confondre avec :

| Champ | Entité | Valeurs |
|---|---|---|
| `Reservation.status` | Reservation | ce document |
| `Reservation.paymentStatus` | Reservation | `pending`, `paid`, `failed`, `refunded` |
| `Payment.status` | Payment | cycle prestataire |
| `ExternalReservation.status` | ExternalReservation | `active`, `cancelled`, `completed` — **lifecycle distinct, valide** |
| `AvailabilityBlock.status` | AvailabilityBlock | propre lifecycle |
| Socket `booking_approved` | événement | n'est **pas** un statut Reservation |
| Notification `partner_booking_canceled` | type d'événement | n'est **pas** un statut Reservation |

Timezone métier : `Africa/Abidjan`. Inventaire : `[checkIn, checkOut)`.

## Machine à états (inchangée P1-06)

```
pending            → awaiting_approval, payment_pending, confirmed, cancelled, expired
awaiting_approval  → payment_pending, cancelled, expired
payment_pending    → confirmed, expired, cancelled
confirmed          → in_stay, cancelled, completed, refunded
in_stay            → completed, cancelled
expired            → (terminal)
cancelled          → refunded
completed          → refunded
refunded           → (terminal)
```

`confirmed`, `in_stay` et `completed` exigent `paymentStatus === paid`.

## Statuts

### pending

- Meaning : état initial / compatible, avant orientation instant vs approval.
- Inventory blocking : YES
- Payment : `pending` typiquement
- Who can enter : création Reservation
- Previous : —
- Next : `awaiting_approval`, `payment_pending`, `confirmed`, `cancelled`, `expired`
- Terminal : NO
- Client : En attente
- Partner : En attente
- Admin : En attente

### awaiting_approval

- Meaning : demande à valider par le Partner (TTL `hostApprovalDeadline`)
- Inventory blocking : YES
- Payment : pas encore requis
- Who can enter : création en mode `approval_required`
- Previous : `pending`
- Next : `payment_pending` (approve), `cancelled` / `expired` (reject / TTL)
- Terminal : NO
- Client : En attente d'approbation
- Partner : En attente d'approbation
- Admin : En attente d'approbation

### payment_pending

- Meaning : réservation acceptée, paiement Client en cours (timer Backend)
- Inventory blocking : YES
- Payment : `pending`
- Who can enter : approve Partner, ou création instant
- Previous : `pending`, `awaiting_approval`
- Next : `confirmed`, `expired`, `cancelled`
- Terminal : NO
- Client : Paiement en attente
- Partner : En attente de paiement
- Admin : Paiement en attente

### confirmed

- Meaning : payée, séjour à venir
- Inventory blocking : YES
- Payment : `paid`
- Who can enter : confirmation paiement
- Previous : `payment_pending` (et chemins instant depuis `pending` si payé)
- Next : `in_stay`, `cancelled`, `completed`, `refunded`
- Terminal : NO
- Client : Confirmée
- Partner : Confirmée
- Admin : Confirmé

### in_stay

- Meaning : check-in effectué, séjour en cours. **Pas** `checked_in`.
- Inventory blocking : YES
- Payment : `paid`
- Who can enter : Partner / Admin check-in
- Previous : `confirmed`
- Next : `completed`, `cancelled`
- Terminal : NO
- Client : Séjour en cours
- Partner : Séjour en cours
- Admin : Séjour en cours
- UI labels autorisés : « Client arrivé », « Check-in effectué » — valeur persistée : `in_stay`

### expired

- Meaning : TTL paiement ou approbation dépassé
- Inventory blocking : NO
- Payment : inchangé / non capturé
- Previous : `pending`, `awaiting_approval`, `payment_pending`
- Next : —
- Terminal : YES
- Client / Partner / Admin : Expirée

### cancelled

- Meaning : annulée (Client, Partner, Admin). Un rejet hôte est `cancelled` + `cancellationDetails.rejectedByHost`.
- Inventory blocking : NO
- Previous : la plupart des non-terminaux
- Next : `refunded`
- Terminal : quasi (sauf refund)
- Client / Partner / Admin : Annulée
- UI Partner « Rejetée » : overlay, pas un statut persisté

### completed

- Meaning : check-out / séjour terminé. **Pas** `checked_out`.
- Inventory blocking : NO
- Payment : `paid`
- Previous : `in_stay` (aussi `confirmed` dans le graphe)
- Next : `refunded`
- Terminal : quasi
- Client / Partner / Admin : Terminée
- UI labels autorisés : « Séjour terminé », « Check-out effectué »

### refunded

- Meaning : remboursement effectué
- Inventory blocking : NO
- Payment : `refunded`
- Previous : `cancelled`, `completed`, `confirmed`
- Terminal : YES
- Client / Partner / Admin : Remboursée

## Sous-ensembles métier

`RESERVATION_STATUS` = les 9 valeurs.

`ACTIVE_BLOCKING_STATUSES` = `pending | awaiting_approval | payment_pending | confirmed | in_stay`.

Ne pas fusionner les deux listes.

## Catégories UI (Client)

`upcoming` / `past` / `active` sont des **filtres d'écran**, pas des `Reservation.status`.

## Socket vs statut

| Event | payload.status typique |
|---|---|
| `booking_approved` | `payment_pending` ou `confirmed` |
| `booking_rejected` | `cancelled` |
| `partner_reservation_status_changed` | valeur canonique |
| `reservation_expired` | `expired` |

Les noms d'événements restent stables pour les apps déjà publiées.
