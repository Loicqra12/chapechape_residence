const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const favoriteController = require('../controllers/favorite.controller');

/**
 * @swagger
 * components:
 *   schemas:
 *     Favorite:
 *       type: object
 *       required:
 *         - user
 *         - residence
 *       properties:
 *         user:
 *           type: string
 *           description: ID of the user
 *         residence:
 *           type: string
 *           description: ID of the favorited residence
 *         createdAt:
 *           type: string
 *           format: date-time
 */

/**
 * @swagger
 * /api/favorites:
 *   post:
 *     summary: Add a residence to favorites
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - residenceId
 *             properties:
 *               residenceId:
 *                 type: string
 *     responses:
 *       201:
 *         description: Residence added to favorites
 *       400:
 *         description: Residence already in favorites
 *       401:
 *         description: Not authenticated
 */
router.post('/', protect, favoriteController.addToFavorites);

/**
 * @swagger
 * /api/favorites:
 *   get:
 *     summary: Get user's favorite residences
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of favorite residences
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Favorite'
 */
router.get('/', protect, favoriteController.getFavorites);

/**
 * @swagger
 * /api/favorites/check/{residenceId}:
 *   get:
 *     summary: Check if a residence is in user's favorites
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: residenceId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Check result
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 isFavorite:
 *                   type: boolean
 */
router.get('/check/:residenceId', protect, favoriteController.checkFavorite);

/**
 * @swagger
 * /api/favorites/{residenceId}:
 *   delete:
 *     summary: Remove a residence from favorites
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: residenceId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Residence removed from favorites
 *       404:
 *         description: Favorite not found
 */
router.delete('/:residenceId', protect, favoriteController.removeFromFavorites);

/**
 * @swagger
 * /api/favorites/stats:
 *   get:
 *     summary: Get favorite statistics
 *     tags: [Favorites]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Favorite statistics
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 totalFavorites:
 *                   type: number
 *                 mostFavorited:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       residence:
 *                         type: object
 *                       count:
 *                         type: number
 */
router.get('/stats', protect, authorize('admin'), favoriteController.getFavoriteStats);

module.exports = router;
