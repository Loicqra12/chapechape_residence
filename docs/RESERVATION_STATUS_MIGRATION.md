# Reservation.status — migration des alias

P1-06 normalise les **valeurs** métier. Aucun renommage cosmétique Booking → Reservation des classes.

## Table

| Legacy | Canonical | Input accepted temporarily? | Persisted? |
|---|---|---|---|
| `pending_payment` | `payment_pending` | OUI (`normalizeReservationStatusInput`) | NON |
| `waiting_payment` | `payment_pending` | OUI | NON |
| `payment_required` | `payment_pending` | OUI | NON |
| `in_progress` | `in_stay` | OUI | NON |
| `checked_in` | `in_stay` | OUI | NON |
| `ongoing` | `in_stay` | OUI | NON |
| `checked_out` | `completed` | OUI | NON |
| `finished` / `complete` | `completed` | OUI | NON |
| `canceled` | `cancelled` | OUI | NON |
| `payment_expired` | `expired` | OUI | NON |
| `rejected` | n'est pas un statut Reservation | NON (endpoint reject dédié → `cancelled` + `rejectedByHost`) | NON |
| `approved` | n'est pas un statut Reservation | NON (événement Socket / vidéo / reviews) | NON |
| `payment_processing` | n'est pas un statut Reservation | NON | NON |
| `BOOKING_STATUS` (enum incomplet) | alias de `RESERVATION_STATUS` | — | — |

Les parsers Flutter Client / Partner / Dashboard appliquent la même table à la lecture (API + cache Hive / SharedPreferences).

L'objet interne est immédiatement canonique. L'API répond toujours canonique.

## Analytics / logs

Les anciens noms peuvent encore apparaître dans Sentry historiques. Les nouveaux événements doivent logger la valeur canonique. Les analytics ne dictent pas le modèle.

## Migration Mongo

Script read-only :

```
cd backend
npm run audit:reservation-status
```

Aucun update automatique dans P1-06.

Si le script trouve des alias persistés :

1. Dry-run d'un `updateMany` par alias → canonique
2. Rejouer l'audit
3. Seulement alors exécuter la migration

`ExternalReservation.status` (`active` / `cancelled` / `completed`) est hors scope.

## Compatibilité apps publiées

Les anciennes apps peuvent encore **envoyer** `pending_payment`, `checked_in`, `checked_out`, `in_progress` sur `PATCH /reservations/:id/status`. Joi + `normalizeReservationStatusInput()` convertissent avant `ReservationStateService`. Rien n'est persisté sous l'alias.

Les événements Socket (`booking_approved`, `booking_rejected`, …) ne sont **pas** renommés.
