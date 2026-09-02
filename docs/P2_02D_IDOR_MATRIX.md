# P2-02D — Matrice ownership (routes authentifiées à ID / fichier)

Source : `backend/src/routes/*` (hors swagger). Staff = `admin` | `superadmin` sauf mention.

Légende tests : **T** = `p2-02-idor.test.js` ; **P** = `p2-02-permissions.test.js` ; **—** = route publique ou sans objet croisé.

## Paiements / PSP

| Route | Auth | Rôle | Ownership | Staff bypass | Test |
|---|---|---|---|---|---|
| POST /api/payments/create-payment-intent | protect | user | reservation.user avant initiatePayment | non | logique controller |
| POST /api/payments/:paymentId/confirm | protect | user | reservation.user **avant** checkPaymentStatus | non | T (status) |
| GET /api/payments/my-payments | protect | user | reservations du user | non | — |
| GET /api/payments/status/:transactionId | protect | user | canAccessPayment **sans** appel PSP | staff via canAccess | T |
| GET /api/payments/cinetpay/verify/:transactionId | protect | user | canAccessPayment **avant** CinetPay | staff via canAccess | T |
| POST /api/payments/:paymentId/refund | protect | user/staff | owner → 501 (pas de PSP) ; étranger 403 ; Stripe **après** admin+paid | admin/superadmin | T |
| Webhooks Stripe/Wave/CinetPay | signature | n/a | HMAC / constructEvent | n/a (provider) | existants |

## Payouts / Wave / CinetPay transfer

| Route | Auth | Rôle | Ownership | Staff bypass | Test |
|---|---|---|---|---|---|
| POST /api/payouts/create/:reservationId | protect | partner+ | reservation.partner | admin | P |
| GET /api/payouts/partner/:partnerId | protect | partner+ | assertPartnerOwnership | admin | P |
| GET /api/payouts/:payoutId | protect | partner+ | payout.partner | admin | P |
| POST /api/payouts/execute/:payoutId | protect | **admin only** | payout chargé puis executePayout | oui (staff) | P |
| GET /api/payouts/stats/:partnerId | protect | partner+ | assertPartnerOwnership | admin | P |
| POST /api/payouts/wave/transfer | protect + canReceivePayout | partner+ | payout_id → load + status ; mobile/net_amount **dérivés** ; **puis** Wave | admin | T |
| GET /api/payouts/wave/transfer/:waveId/status | protect | partner+ | payout local **avant** Wave ; 403 si absent | admin peut interroger Wave | — |
| GET /api/payouts/wave/search | protect | partner+ | payout local **avant** Wave | admin | — |
| POST /api/payouts/wave/batch | protect | **admin** | payout_ids → net_amount/mobile dérivés **puis** Wave | oui | — |
| GET /api/payouts/wave/batch/:batchId/status | protect | **admin** | staff only puis Wave | oui | — |
| POST /api/payouts/wave/transfer/:waveId/reverse | protect | **admin** | staff only puis Wave | oui | — |
| POST /api/payouts/cinetpay/transfer | protect + capability | partner+ | payout_id **avant** sendMoney | admin | T (même loader) |
| GET /api/payouts/cinetpay/transfer/:transferId/status | protect | partner+ | payout local **avant** CinetPay (sauf admin sans local) | admin | — |
| POST /api/payouts/cinetpay/transfer/:transferId/cancel | protect | **admin** | staff | oui | — |
| GET /api/payouts/cinetpay/transfer/history | protect | partner+ | filter.partner = self | admin + partner_id optionnel | — |
| GET /api/payouts/cinetpay/balance | protect | partner+ | compte plateforme (pas ID user) | partner+admin | — |
| POST /api/payouts/reset/:payoutId | protect | **admin** | staff | oui | — |
| Jobs automatic-payout | n/a | système | payout Mongo puis Wave | n/a | — |

## Messages / media / uploads

| Route | Auth | Rôle | Ownership | Staff bypass | Test |
|---|---|---|---|---|---|
| GET/POST conversations, messages, read | protect | user | canAccessConversation | staff | T |
| POST .../attachments | protect | user | participant **avant** multer/Cloudinary | staff | T |
| POST createConversation | protect | user | participants forcés + reservation party | staff | T |
| POST /whatsapp/test | protect | staff, hors prod | pas de toPhone client | staff | T |
| POST .../whatsapp | protect | participant | téléphone co-participant dérivé | staff | T |
| GET /api/media/cloudinary-signature | protect | user | folder assert **avant** signature | staff | T |
| GET /api/media/private/:folder/:filename | protect | user | Partner.documents basename **ou** message attachment **ou** staff | staff | T |
| GET /uploads/* | public sauf | — | documents/messages/quarantine → 401 | — | T |
| POST /api/partners/documents | protect isPartner | partner | self ; 404 si pas discriminator Partner | — | audit script |

## Reviews / ratings / residences

| Route | Auth | Rôle | Ownership | Staff bypass | Test |
|---|---|---|---|---|---|
| POST /api/reviews | protect | user | reservation.user + residence + completed ; 1/résidence | non (partner own → 403) | T |
| GET /api/reviews | protect | **admin** | liste globale | oui | — |
| GET /api/reviews/residence/:residenceId | public | — | avis d’une résidence | — | — |
| POST /api/reviews/:id/respond | protect | partner | review.residence.partner | non | — |
| PUT/DELETE /api/reviews/:id | protect | auteur | review.user ; delete + admin | admin delete | — |
| PUT /api/residences/:id/ratings | protect | **client** | séjour completed → Review | non | T |
| PUT /api/residences/:id | protect partner+ | partner | partner + Joi strip publication/verified | admin | — |
| POST/DELETE images, FAQs, nearby, amenities, payment-methods, videos | protect partner+ | partner | partner (images : 403 **avant** Cloudinary delete) | admin images/deleteVideo | T |
| POST /:id/publish | protect | partner | owner + capability | — | publication tests |
| GET /:id (catalogue) | optional | public | unlisted masqué | owner/staff | T |

## Availability / pricing / calendar

| Route | Auth | Rôle | Ownership | Staff bypass | Test |
|---|---|---|---|---|---|
| PUT /api/availability/pricing | protect | partner+ | canManageResidence ; `$set: { price }` | admin | T |
| PUT block/unblock, external, complete | protect | partner+ | services partner-block / external (P1 figé) | admin | P1 tests |
| GET check/calendar/flutter | public | — | pas d’écriture | — | — |
| GET /api/pricing/partner/:partnerId/stats | protect | partner/admin | partnerId == self | admin 200 | T |
| POST /api/pricing/validate\|simulate | protect | **admin** | n/a | oui | — |
| POST /api/pricing/calculate (public) | non | — | devis, pas d’objet | — | — |

## Réservations / notifications / favoris

| Route | Auth | Rôle | Ownership | Staff bypass | Test |
|---|---|---|---|---|---|
| GET/PATCH /api/reservations/:id* | protect | user | canAccessReservation / partner residence | staff | T |
| GET /residence/:residenceId | protect | partner | residence.partner == self | — | — |
| GET /api/notifications/:id* | protect | user | notification.user == req.user.id | non | — |
| Favorites /:residenceId | protect | user | self favorites | — | — |

## Support / ops / admin

| Route | Auth | Rôle | Ownership | Staff bypass | Test |
|---|---|---|---|---|---|
| /api/support/tickets* | protect | user | **501 NOT_IMPLEMENTED** (pas d’objet) | — | T |
| /api/admin/** /:id | protect | isAdmin | staff only | oui | P2-02E prochain |
| /api/superadmin/admins/:id, /blocked-ips/:ip | protect | superadmin | staff | oui | P2-02E |
| /api/superadmin/settings | protect | isAdmin | **staff settings — hors P2-02D** | oui | P2-02E |
| /api/ops/* | protect | isAdmin | staff + audit | oui | P1 ops tests |
| Devices | protect | user | self | — | — |
| SMS /send | protect | **admin** | to libre staff | oui | T sms |
| SMS /booking | protect | partner+ | reservation.partner **puis** phone dérivé | admin | — |
| Audit / maintenance | protect | staff | staff | oui | — |
| Cancellation GET /:id | public | — | politique catalogue | — | — |
| Cancellation write /:id | protect | admin | staff | oui | — |

## PSP — authorization-before-provider

| Appel | Avant PSP |
|---|---|
| PaymentService.initiatePayment (Stripe/Wave/CinetPay) | reservation.user == currentUser + état |
| PaymentService.checkPaymentStatus (confirm) | reservation.user |
| cinetPayService.checkPaymentStatus (verify) | canAccessPayment |
| stripe.refunds.create (HTTP refund) | admin + paid ; client jamais |
| refund.service Stripe (job Agenda) | claim interne payment Mongo, pas d’ID client |
| wave createPayout / CinetPay sendMoney | loadTransferablePayout |
| wave getPayoutStatus / search | payout local + ownership (sauf admin status/reverse/batch) |
| Webhooks | signature, pas JWT |

**Jobs** `automatic-payout` : source Mongo, pas body utilisateur.

## Uploads — classification

| Dossier | Visibilité |
|---|---|
| residences, profiles | public |
| documents, messages, quarantine | privé (401 static ; streaming auth) |
| autre (découvert par script) | unknown → à traiter comme privé jusqu’à justification |

Streaming authentifié = critère P2-02D (pas d’URL signée obligatoire).

## Discriminator Partner

Fail-closed : `Partner.findById` + document basename. Script `audit-partner-discriminator.js`.
