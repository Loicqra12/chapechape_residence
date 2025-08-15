/**
 * Définitions Swagger pour les modèles liés aux paiements
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     Payment:
 *       type: object
 *       required:
 *         - reservation
 *         - amount
 *         - paymentMethod
 *         - paymentProvider
 *       properties:
 *         _id:
 *           type: string
 *           description: ID unique du paiement
 *         reservation:
 *           type: string
 *           description: ID de la réservation associée
 *         amount:
 *           type: number
 *           description: Montant du paiement
 *         currency:
 *           type: string
 *           default: XOF
 *           description: Devise du paiement
 *         status:
 *           type: string
 *           enum: [pending, paid, failed, cancelled, refunded]
 *           default: pending
 *           description: Statut du paiement
 *         paymentMethod:
 *           type: string
 *           enum: [card, orange_money, mtn_money, moov_money, wave, djamo]
 *           description: Méthode de paiement utilisée
 *         paymentProvider:
 *           type: string
 *           enum: [stripe, orange, mtn, moov, wave, djamo]
 *           description: Fournisseur de service de paiement
 *         transactionId:
 *           type: string
 *           description: ID de transaction fourni par le prestataire de paiement
 *         phoneNumber:
 *           type: string
 *           description: Numéro de téléphone (pour les paiements mobiles)
 *         firstName:
 *           type: string
 *           description: Prénom du payeur
 *         lastName:
 *           type: string
 *           description: Nom du payeur
 *         refundAmount:
 *           type: number
 *           description: Montant remboursé, le cas échéant
 *         refundReason:
 *           type: string
 *           description: Raison du remboursement
 *         metadata:
 *           type: object
 *           description: Données supplémentaires associées au paiement
 *         paymentDetails:
 *           type: object
 *           properties:
 *             otp:
 *               type: string
 *               description: Code OTP pour les paiements mobiles
 *             reference:
 *               type: string
 *               description: Référence du paiement
 *             providerResponse:
 *               type: object
 *               description: Réponse brute du fournisseur de paiement
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: Date de création du paiement
 *         updatedAt:
 *           type: string
 *           format: date-time
 *           description: Date de dernière mise à jour
 *       example:
 *         _id: "60d21b4667d0d8992e610c85"
 *         reservation: "60d21b4667d0d8992e610c86"
 *         amount: 50000
 *         currency: "XOF"
 *         status: "paid"
 *         paymentMethod: "orange_money"
 *         paymentProvider: "orange"
 *         transactionId: "tx_123456789"
 *         phoneNumber: "0123456789"
 *         firstName: "Jean"
 *         lastName: "Dupont"
 *         metadata: {}
 *         paymentDetails:
 *           reference: "REF-12345"
 *         createdAt: "2023-01-01T12:00:00Z"
 *         updatedAt: "2023-01-01T12:05:00Z"
 */
