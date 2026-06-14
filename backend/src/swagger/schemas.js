/**
 * Définitions des schémas Swagger pour l'API ChapeChape
 * Ces schémas servent de référence pour la documentation des endpoints
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     User:
 *       type: object
 *       required:
 *         - email
 *         - password
 *         - firstName
 *         - lastName
 *         - role
 *       properties:
 *         _id:
 *           type: string
 *           description: ID unique de l'utilisateur
 *         email:
 *           type: string
 *           format: email
 *           description: Email de l'utilisateur
 *         firstName:
 *           type: string
 *           description: Prénom de l'utilisateur
 *         lastName:
 *           type: string
 *           description: Nom de famille de l'utilisateur
 *         role:
 *           type: string
 *           enum: [client, partner, admin]
 *           description: Rôle de l'utilisateur dans le système
 *         profileImage:
 *           type: string
 *           description: URL de l'image de profil
 *         phone:
 *           type: string
 *           description: Numéro de téléphone
 *         isVerified:
 *           type: boolean
 *           description: Indique si l'email a été vérifié
 *         isActive:
 *           type: boolean
 *           description: Indique si le compte est actif
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: Date de création du compte
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           description: Date de dernière mise à jour
 *       example:
 *         _id: "60d21b4667d0d8992e610c85"
 *         email: "utilisateur@exemple.com"
 *         firstName: "Jean"
 *         lastName: "Dupont"
 *         role: "client"
 *         profileImage: "https://example.com/image.jpg"
 *         phone: "+33612345678"
 *         isVerified: true
 *         isActive: true
 *         createdAt: "2023-01-01T12:00:00Z"
 *         updatedAt: "2023-01-02T12:00:00Z"
 *
 *     Residence:
 *       type: object
 *       required:
 *         - title
 *         - description
 *         - price
 *         - address
 *         - city
 *         - partner
 *         - bedrooms
 *         - bathrooms
 *         - area
 *         - type
 *       properties:
 *         _id:
 *           type: string
 *           description: ID unique de la résidence
 *         title:
 *           type: string
 *           description: Titre de la résidence
 *         description:
 *           type: string
 *           description: Description détaillée de la résidence
 *         price:
 *           type: number
 *           description: Prix de base
 *         pricePeriod:
 *           type: string
 *           enum: [hour, day, week, month]
 *           default: month
 *           description: Période de tarification
 *         address:
 *           type: string
 *           description: Adresse complète
 *         city:
 *           type: string
 *           description: Ville
 *         images:
 *           type: array
 *           items:
 *             type: string
 *           description: URLs des images (Cloudinary)
 *         bedrooms:
 *           type: integer
 *           description: Nombre de chambres
 *         bathrooms:
 *           type: integer
 *           description: Nombre de salles de bain
 *         area:
 *           type: number
 *           description: Surface en m²
 *         type:
 *           type: string
 *           enum: [apartment, house, villa, studio, room, appartement_meuble, studio_meuble, villa_meublee, hotel, bungalow, other]
 *           description: Type de propriété
 *         status:
 *           type: string
 *           enum: [available, unavailable, maintenance]
 *           default: available
 *         reservationMode:
 *           type: string
 *           enum: [instant, approval_required]
 *           default: instant
 *           description: Mode de réservation — instant ou avec approbation partenaire
 *         paymentTTLMinutes:
 *           type: integer
 *           default: 60
 *           description: Délai de paiement en minutes (5-1440)
 *         partner:
 *           type: string
 *           description: ID du partenaire propriétaire
 *         amenities:
 *           type: array
 *           items:
 *             type: string
 *           description: Liste des équipements (wifi, parking, pool, etc.)
 *         rating:
 *           type: object
 *           properties:
 *             overall:
 *               type: number
 *             cleanliness:
 *               type: number
 *             comfort:
 *               type: number
 *             facilities:
 *               type: number
 *             reviewCount:
 *               type: integer
 *         stars:
 *           type: integer
 *           minimum: 0
 *           maximum: 5
 *         locationData:
 *           type: object
 *           properties:
 *             coordinates:
 *               type: object
 *               properties:
 *                 latitude:
 *                   type: number
 *                 longitude:
 *                   type: number
 *             commune:
 *               type: string
 *             quartier:
 *               type: string
 *         isFurnished:
 *           type: boolean
 *         deleted:
 *           type: boolean
 *           default: false
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *       example:
 *         _id: "60d21b4667d0d8992e610c86"
 *         title: "Villa Paradise Cocody"
 *         description: "Magnifique villa meublée avec piscine à Cocody"
 *         price: 150000
 *         pricePeriod: "month"
 *         address: "Rue des Jardins, Cocody"
 *         city: "Abidjan"
 *         images: ["https://res.cloudinary.com/chapechape/image1.jpg"]
 *         bedrooms: 3
 *         bathrooms: 2
 *         area: 120
 *         type: "villa_meublee"
 *         status: "available"
 *         reservationMode: "instant"
 *         paymentTTLMinutes: 60
 *         partner: "60d21b4667d0d8992e610c85"
 *         amenities: ["wifi", "pool", "parking", "air_conditioning"]
 *         rating:
 *           overall: 4.8
 *           reviewCount: 12
 *         stars: 4
 *         isFurnished: true
 *
 *     Booking:
 *       type: object
 *       required:
 *         - residence
 *         - client
 *         - partner
 *         - checkIn
 *         - checkOut
 *         - visitDate
 *         - visitTime
 *         - status
 *       properties:
 *         _id:
 *           type: string
 *           description: ID unique de la réservation
 *         residence:
 *           type: string
 *           description: ID de la résidence réservée
 *         client:
 *           type: string
 *           description: ID du client qui a fait la réservation
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
 *         visitDate:
 *           type: string
 *           format: date
 *           description: Date de la visite
 *         visitTime:
 *           type: string
 *           description: Heure de la visite
 *         status:
 *           type: string
 *           enum: [pending, confirmed, cancelled, completed, refunded]
 *           description: Statut de la réservation
 *         price:
 *           type: number
 *           description: Prix total de la réservation
 *         guestCount:
 *           type: number
 *           description: Nombre de personnes
 *         notes:
 *           type: string
 *           description: Notes additionnelles pour la réservation
 *         cancellationReason:
 *           type: string
 *           description: Raison de l'annulation (si applicable)
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: Date de création de la réservation
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           description: Date de dernière mise à jour
 *       example:
 *         _id: "60d21b4667d0d8992e610c87"
 *         residence: "60d21b4667d0d8992e610c86"
 *         client: "60d21b4667d0d8992e610c85"
 *         partner: "60d21b4667d0d8992e610c88"
 *         checkIn: "2023-07-01"
 *         checkOut: "2023-07-08"
 *         visitDate: "2023-06-15"
 *         visitTime: "14:00"
 *         status: "confirmed"
 *         price: 1050
 *         guestCount: 4
 *         notes: "Arrivée prévue vers 14h"
 *         createdAt: "2023-05-15T12:00:00Z"
 *         updatedAt: "2023-05-16T10:30:00Z"
 *
 *     Payment:
 *       type: object
 *       required:
 *         - booking
 *         - amount
 *         - method
 *         - status
 *       properties:
 *         _id:
 *           type: string
 *           description: ID unique du paiement
 *         booking:
 *           type: string
 *           description: ID de la réservation associée
 *         user:
 *           type: string
 *           description: ID de l'utilisateur qui a effectué le paiement
 *         amount:
 *           type: number
 *           description: Montant du paiement
 *         method:
 *           type: string
 *           enum: [card, paypal, transfer, cash]
 *           description: Méthode de paiement
 *         status:
 *           type: string
 *           enum: [pending, completed, failed, refunded]
 *           description: Statut du paiement
 *         transactionId:
 *           type: string
 *           description: Identifiant de transaction externe
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: Date de création du paiement
 *       example:
 *         _id: "60d21b4667d0d8992e610c89"
 *         booking: "60d21b4667d0d8992e610c87"
 *         user: "60d21b4667d0d8992e610c85"
 *         amount: 1050
 *         method: "card"
 *         status: "completed"
 *         transactionId: "tx_123456789"
 *         createdAt: "2023-05-15T12:05:00Z"
 *
 *     ApiError:
 *       type: object
 *       properties:
 *         success:
 *           type: boolean
 *           description: Indique si la requête a réussi
 *         message:
 *           type: string
 *           description: Message d'erreur lisible
 *         errorCode:
 *           type: string
 *           description: Code d'erreur spécifique
 *         errors:
 *           type: array
 *           items:
 *             type: object
 *             properties:
 *               field:
 *                 type: string
 *                 description: Champ concerné par l'erreur
 *               message:
 *                 type: string
 *                 description: Message d'erreur spécifique au champ
 *           description: Liste des erreurs détaillées
 *         data:
 *           type: object
 *           description: Données supplémentaires liées à l'erreur
 *       example:
 *         success: false
 *         message: "La réservation n'a pas pu être confirmée"
 *         errorCode: "BOOKING_INVALID_STATUS_CHANGE"
 *         errors: [
 *           {
 *             field: "status",
 *             message: "Impossible de changer le statut de 'cancelled' à 'confirmed'"
 *           }
 *         ]
 *         data: {
 *           bookingId: "60d21b4667d0d8992e610c87",
 *           currentStatus: "cancelled",
 *           targetStatus: "confirmed"
 *         }
 *
 *     ApiResponse:
 *       type: object
 *       properties:
 *         success:
 *           type: boolean
 *           description: Indique si la requête a réussi
 *         message:
 *           type: string
 *           description: Message de confirmation
 *         data:
 *           type: object
 *           description: Données retournées par l'API
 *       example:
 *         success: true
 *         message: "Réservation créée avec succès"
 *         data: {
 *           _id: "60d21b4667d0d8992e610c87",
 *           status: "pending"
 *         }
 *
 *     PaginatedResponse:
 *       type: object
 *       properties:
 *         success:
 *           type: boolean
 *           description: Indique si la requête a réussi
 *         data:
 *           type: array
 *           items:
 *             type: object
 *           description: Liste des éléments
 *         pagination:
 *           type: object
 *           properties:
 *             total:
 *               type: number
 *               description: Nombre total d'éléments
 *             pages:
 *               type: number
 *               description: Nombre total de pages
 *             page:
 *               type: number
 *               description: Page courante
 *             limit:
 *               type: number
 *               description: Nombre d'éléments par page
 *       example:
 *         success: true
 *         data: [
 *           {
 *             _id: "60d21b4667d0d8992e610c87",
 *             status: "pending"
 *           }
 *         ]
 *         pagination:
 *           total: 100
 *           pages: 10
 *           page: 1
 *           limit: 10
 */

// Ce fichier sert uniquement à documenter les schémas pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
