/**
 * @swagger
 * components:
 *   schemas:
 *     Notification:
 *       type: object
 *       required:
 *         - user
 *         - type
 *         - message
 *       properties:
 *         _id:
 *           type: string
 *           description: ID unique de la notification
 *         user:
 *           type: string
 *           description: ID de l'utilisateur concerné par la notification
 *         type:
 *           type: string
 *           enum: [favorite_added, favorite_price_changed, favorite_status_changed, booking_confirmed, booking_cancelled, booking_reminder, payment_received, payment_failed, payment_refunded, system_maintenance, account_update]
 *           description: Type de notification
 *         message:
 *           type: string
 *           description: Message de la notification
 *         data:
 *           type: object
 *           description: Données supplémentaires liées à la notification
 *         read:
 *           type: boolean
 *           description: Indique si la notification a été lue
 *           default: false
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: Date de création de la notification
 *       example:
 *         _id: "60d21b4667d0d8992e610c86"
 *         user: "60d21b4667d0d8992e610c85"
 *         type: "booking_confirmed"
 *         message: "Votre réservation a été confirmée"
 *         data:
 *           bookingId: "60d21b4667d0d8992e610c87"
 *           residenceName: "Villa Paradise"
 *         read: false
 *         createdAt: "2023-01-01T12:00:00Z"
*/ 