const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');

// Rate limiting spécifique pour les pings (beaucoup plus permissif)
const pingLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 200, // 200 requêtes par minute (au lieu de 20)
  message: {
    success: false,
    message: 'Trop de requêtes ping, veuillez réessayer plus tard',
    retryAfter: 60
  },
  standardHeaders: true,
  legacyHeaders: false,
  skip: (req) => {
    // Skip rate limiting en développement
    return process.env.NODE_ENV === 'development';
  }
});

/**
 * @swagger
 * /api/ping:
 *   get:
 *     summary: Ping simple pour vérifier la connectivité
 *     description: Endpoint léger pour vérifier que le serveur répond
 *     tags: [Health]
 *     responses:
 *       200:
 *         description: Serveur accessible
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
 *                   example: pong
 *                 timestamp:
 *                   type: string
 *                   format: date-time
 *                 server:
 *                   type: string
 *                   example: chapechape-api
 *       429:
 *         description: Trop de requêtes
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: false
 *                 message:
 *                   type: string
 *                   example: Trop de requêtes ping, veuillez réessayer plus tard
 *                 retryAfter:
 *                   type: number
 *                   example: 60
 */
router.get('/', pingLimiter, (req, res) => {
  res.status(200).json({
    success: true,
    message: 'pong',
    timestamp: new Date().toISOString(),
    server: 'chapechape-api',
    version: process.env.npm_package_version || '1.0.0'
  });
});

module.exports = router;








