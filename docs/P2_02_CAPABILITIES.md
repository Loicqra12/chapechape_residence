# P2-02 — Rôles, vérification, capabilities

`role` ≠ Partner vérifié. `not verified` ≠ bloqué du produit.

## Alias `partner_pending`

Les comptes historiques `role=partner_pending` ont le **même accès produit** que `partner`.
Aucun nouveau compte n’est créé avec ce rôle. Pas de migration Mongo obligatoire.

## Matrice

| ROLE | VERIFICATION | CAPABILITY | ACTION |
|---|---|---|---|
| partner / partner_pending | (aucune) | `canAccessPartnerApp`, `canEditProfile` | App, profil |
| partner / partner_pending | (aucune, identity ≠ rejected) | `canCreateResidence`, `canEditResidence`, `canManageCalendar`, `canCreateBlocks`, `canCreateExternalBooking` | Créer/éditer résidence, photos, vidéos, prix, calendrier, blocks, résa externe |
| partner / partner_pending | **phone = verified** | `canPublishResidence` | `POST /api/residences/:id/publish` → `draft` → `pending_review` |
| partner / partner_pending | **phone = verified** | `canReceiveBookings` | Distinct de la publication (même règle téléphone aujourd’hui) |
| partner / partner_pending | phone + payout (`verified` **ou** legacy `not_configured`) | `canReceivePayout` | Reversements. `not_configured` ≠ `verified` |
| admin / superadmin | n/a | toutes true | RBAC staff, pas les capabilities Partner |
| client | n/a | toutes false | Pas de publication |

## Publication Residence (P2-02C)

Cycle **distinct** de `status` (`available` / `unavailable` / `maintenance` = occupation).

| Chemin | Acteur | Transition | Gate capability |
|---|---|---|---|
| `POST /residences` | Partner | → `publicationStatus=draft` | NON |
| `PUT /residences/:id` | Partner owner | draft → draft (champs métier) | NON. `publicationStatus` / `verified` strippés |
| photos / vidéos / pricing / calendar / blocks / external | Partner owner | préparation | NON |
| `POST /residences/:id/publish` | Partner owner | draft → `pending_review` | **OUI `canPublishResidence`** |
| `PUT /admin/residences/:id/verify` | Admin | → `published` + `verified` | NON (RBAC admin) |

Legacy : absence de `publicationStatus` = déjà au catalogue. **Aucune dépublication automatique.**

Refus publication :

```json
{
  "success": false,
  "code": "CAPABILITY_REQUIRED",
  "errorCode": "CAPABILITY_REQUIRED",
  "message": "Vérifiez votre numéro de téléphone pour publier cette résidence.",
  "details": {
    "capability": "canPublishResidence",
    "verification": "phone"
  }
}
```

`isPhoneVerified` et `capabilities` ne sont pas éditables via profil. Seul l’OTP backend les change.

## P2-02D IDOR (en cours)

Principe : un token **valide** ne donne accès qu’aux ressources dont l’utilisateur est partie (ou staff explicite).

Corrigé dans cette passe :
- messages : `getMessages` / `markAsRead` / `send` / attachments / createConversation (participants non fiables)
- paiements : `GET /cinetpay/verify/:transactionId` ownership **avant** appel PSP ; plus de fuite `cinetpayData`
- `GET /payments/status/:transactionId` : client owner **ou** partner de la résa **ou** staff
- Cloudinary documents : pas un autre userId ; clients exclus
- `POST /sms/send` : admin only
- `POST /messages/whatsapp/test` : staff hors production ; WhatsApp conv = téléphone du co-participant seulement

Reste : Wave transfer free-form, fichiers `GET /uploads` statiques, ratings résidence, `POST /reviews` reservationId, `PUT /availability/pricing`.

