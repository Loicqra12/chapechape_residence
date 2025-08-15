/**
 * Définitions Swagger pour les modèles liés aux réservations
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Reservation:
 *       type: object
 *       required:
 *         - residence
 *         - user
 *         - partner
 *         - checkIn
 *         - checkOut
 *         - numberOfGuests
 *         - totalPrice
 *         - cancellationPolicy
 *       properties:
 *         _id:
 *           type: string
 *           description: ID unique de la réservation
 *         residence:
 *           type: string
 *           description: ID de la résidence réservée
 *         user:
 *           type: string
 *           description: ID de l'utilisateur qui a fait la réservation
 *         partner:
 *           type: string
 *           description: ID du partenaire propriétaire de la résidence
 *         checkIn:
 *           type: string
 *           format: date
 *           description: Date d'arrivée
 *         checkOut:
 *           type: string
 *           format: date
 *           description: Date de départ
 *         numberOfGuests:
 *           type: integer
 *           minimum: 1
 *           description: Nombre de personnes
 *         totalPrice:
 *           type: number
 *           description: Prix total de la réservation
 *         status:
 *           type: string
 *           enum: [pending, awaiting_approval, payment_pending, confirmed, in_stay, cancelled, completed, expired, refunded]
 *           default: pending
 *           description: Statut actuel de la réservation
 *         paymentStatus:
 *           type: string
 *           enum: [pending, paid, failed, refunded]
 *           default: pending
 *           description: Statut du paiement
 *         cancellationPolicy:
 *           type: string
 *           description: ID de la politique d'annulation
 *         notes:
 *           type: string
 *           description: Notes additionnelles pour la réservation
 *         visitDate:
 *           type: string
 *           format: date
 *           description: Date de visite (pour les visites programmées)
 *         visitTime:
 *           type: string
 *           description: Heure de visite (pour les visites programmées)
 *         messagingEnabled:
 *           type: boolean
 *           default: false
 *           description: Indique si la messagerie est activée pour cette réservation
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: Date de création de la réservation
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           description: Date de dernière mise à jour
 *       example:
 *         _id: "60d21b4667d0d8992e610c85"
 *         residence: "60d21b4667d0d8992e610c86"
 *         user: "60d21b4667d0d8992e610c87"
 *         partner: "60d21b4667d0d8992e610c88"
 *         checkIn: "2023-07-01"
 *         checkOut: "2023-07-07"
 *         numberOfGuests: 2
 *         totalPrice: 350000
 *         status: "confirmed"
 *         paymentStatus: "paid"
 *         cancellationPolicy: "60d21b4667d0d8992e610c89"
 *         notes: "Arrivée prévue vers 14h"
 *         createdAt: "2023-01-01T12:00:00Z"
 *         updatedAt: "2023-01-02T09:30:00Z"
 *
 *     ReservationWithVirtuals:
 *       allOf:
 *         - $ref: '#/components/schemas/Reservation'
 *         - type: object
 *           properties:
 *             residence:
 *               type: object
 *               properties:
 *                 _id:
 *                   type: string
 *                   description: ID de la résidence
 *                 name:
 *                   type: string
 *                   description: Nom de la résidence
 *                 imageUrl:
 *                   type: string
 *                   description: URL de la première image ou image par défaut
 *                 title:
 *                   type: string
 *                   description: Alias pour le nom de la résidence
 *                 status:
 *                   type: string
 *                   enum: [available, unavailable]
 *                   description: Disponibilité de la résidence
 *                 hasPool:
 *                   type: boolean
 *                   description: Si la résidence a une piscine
 *                 isVacationResidence:
 *                   type: boolean
 *                   description: Si c'est une résidence de vacances
 *                 isSpecialResidence:
 *                   type: boolean
 *                   description: Si c'est une résidence spéciale
 *                 location:
 *                   type: object
 *                   properties:
 *                     displayAddress:
 *                       type: string
 *                       description: Adresse formatée pour l'affichage
 *           example:
 *             residence:
 *               _id: "60d21b4667d0d8992e610c86"
 *               name: "Villa Paradis"
 *               imageUrl: "https://example.com/image.jpg"
 *               title: "Villa Paradis"
 *               status: "available"
 *               hasPool: true
 *               isVacationResidence: true
 *               isSpecialResidence: false
 *               location:
 *                 displayAddress: "123 Rue des Palmiers, Abidjan, Côte d'Ivoire"
 *
 *     CancellationPolicy:
 *       type: object
 *       required:
 *         - name
 *         - description
 *         - rules
 *         - createdBy
 *       properties:
 *         _id:
 *           type: string
 *           description: ID unique de la politique d'annulation
 *         name:
 *           type: string
 *           description: Nom de la politique
 *         description:
 *           type: string
 *           description: Description de la politique
 *         rules:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               timeBeforeCheckIn:
 *                 type: number
 *                 description: Temps avant le check-in en heures
 *               refundPercentage:
 *                 type: number
 *                 description: Pourcentage de remboursement
 *               description:
 *                 type: string
 *                 description: Description de la règle
 *         createdBy:
 *           type: string
 *           description: ID de l'administrateur qui a créé la politique
 *         isActive:
 *           type: boolean
 *           default: true
 *           description: Si la politique est active
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: Date de création
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           description: Date de dernière mise à jour
 *       example:
 *         _id: "60d21b4667d0d8992e610c89"
 *         name: "Politique standard"
 *         description: "Politique standard de remboursement"
 *         rules:
 *           - timeBeforeCheckIn: 48
 *             refundPercentage: 50
 *             description: "Remboursement de 50% si annulation 48h avant"
 *         createdBy: "60d21b4667d0d8992e610c90"
 *         isActive: true
 *         createdAt: "2023-01-01T12:00:00Z"
 *         updatedAt: "2023-01-01T12:00:00Z"
 */
