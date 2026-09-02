const express = require('express');
const router = express.Router();
const healthController = require('../controllers/health.controller');

/**
 * @swagger
 * /api/health:
 *   get:
 *     summary: Vérification générale de l'état du serveur
 *     description: Récupère l'état général du serveur et de la base de données
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: Serveur en bonne santé
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 message:
 *                   type: string
 *                   example: Server is running
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                 database:
 *                   type: string
 *                   example: connected
 *                 environment:
 *                   type: string
 *                   example: development
 */
router.get('/', healthController.getGeneralHealth);
router.get('/ready', healthController.getReadiness);
router.get('/live', healthController.getLiveness);

/**
 * @swagger
 * /api/health/payment-services:
 *   get:
 *     summary: Vérification de l'état des services de paiement
 *     description: Récupère l'état des différents services de paiement (Wave, CinetPay, CinetPay Transfer)
 *     tags: [Health, Payment]
 *     responses:
 *       200:
 *         description: Tous les services de paiement sont opérationnels
 *       207:
 *         description: Certains services de paiement sont dégradés
 *       503:
 *         description: Les services de paiement sont indisponibles
 */
router.get('/payment-services', healthController.getPaymentServicesHealth);

/**
 * @swagger
 * /api/health/payment-timer:
 *   get:
 *     summary: Vérification de l'état du service payment timer
 *     description: Récupère l'état du service de timer de paiement
 *     tags: [Health, Payment]
 *     responses:
 *       200:
 *         description: Le service payment timer est opérationnel
 *       409:
 *         description: Le service payment timer est mal configuré
 *       503:
 *         description: Le service payment timer est indisponible
 */
router.get('/payment-timer', healthController.getPaymentTimerHealth);

module.exports = router;
