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
 *           enum: [system, new_message, general, partner_new_booking, partner_booking_modified, partner_booking_canceled, partner_booking_expired, partner_payment_received, partner_deposit_received, partner_monthly_stats, partner_new_review, partner_payout_initiated, partner_payout_success, partner_payout_failed, partner_transfer_initiated, partner_transfer_success, partner_transfer_failed, partner_phone_changed, partner_verification_sent, partner_verification_success, partner_verification_failed, partner_security_alert, partner_login_alert, partner_pending_digest, client_booking_confirmed, client_arrival_reminder, client_departure_reminder, client_special_offer, client_discount, client_popular_residence, client_limited_availability, client_nearby_residence, client_payment_pending, client_awaiting_approval, client_booking_approved, client_booking_rejected, client_payment_expired, reservation_request_expired, client_checkin_ready, client_checkout_reminder, client_phone_changed, client_verification_sent, client_verification_success, client_verification_failed, client_security_alert, client_login_alert, client_reengage, client_review_request, client_abandoned_search, client_payment_refund, favorite_added, favorite_price_changed, favorite_status_changed, booking_confirmed, booking_cancelled, booking_reminder, booking_update, payment_received, payment_failed, payment_refunded, payment_required, system_maintenance, account_update]
 *           description: Type de notification (source canonique notification-types.js)
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
 *         type: "client_booking_confirmed"
 *         message: "Votre réservation a été confirmée"
 *         data:
 *           bookingId: "60d21b4667d0d8992e610c87"
 *           residenceName: "Villa Paradise"
 *         read: false
 *         createdAt: "2023-01-01T12:00:00Z"
*/
