const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const {
    createPromotion,
    getPromotions,
    getActivePromotions,
    getExclusivePromotions,
    getResidencePromotions,
    getPromotion,
    updatePromotion,
    deletePromotion
} = require('../controllers/promotion/promotion.controller');

/**
 * @swagger
 * tags:
 *   name: Promotions
 *   description: API pour gérer les promotions et offres exclusives
 */

/**
 * @swagger
 * /api/promotions:
 *   get:
 *     summary: Récupère toutes les promotions
 *     tags: [Promotions]
 *     parameters:
 *       - in: query
 *         name: type
 *         schema:
 *           type: string
 *           enum: [discount, flash, seasonal, bundle, exclusive, newUser]
 *         description: Filtrer par type de promotion
 *       - in: query
 *         name: exclusive
 *         schema:
 *           type: boolean
 *         description: Filtrer par promotions exclusives
 *       - in: query
 *         name: residence
 *         schema:
 *           type: string
 *         description: Filtrer par ID de résidence
 *       - in: query
 *         name: active
 *         schema:
 *           type: boolean
 *         description: Filtrer par promotions actives uniquement
 *       - in: query
 *         name: sort
 *         schema:
 *           type: string
 *         description: Champ de tri (prefix - pour ordre décroissant)
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Page à afficher
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Nombre d'éléments par page
 *     responses:
 *       200:
 *         description: Liste des promotions
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 pagination:
 *                   type: object
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Promotion'
 *   post:
 *     summary: Créer une nouvelle promotion
 *     tags: [Promotions]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Promotion'
 *     responses:
 *       201:
 *         description: Promotion créée
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Promotion'
 */
router.route('/')
    .get(getPromotions)
    .post(protect, authorize('admin', 'partner'), createPromotion);

/**
 * @swagger
 * /api/promotions/active:
 *   get:
 *     summary: Récupère les promotions actives
 *     tags: [Promotions]
 *     responses:
 *       200:
 *         description: Liste des promotions actives
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Promotion'
 */
router.get('/active', getActivePromotions);

/**
 * @swagger
 * /api/promotions/exclusive:
 *   get:
 *     summary: Récupère les promotions exclusives
 *     tags: [Promotions]
 *     responses:
 *       200:
 *         description: Liste des promotions exclusives
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Promotion'
 */
router.get('/exclusive', getExclusivePromotions);

/**
 * @swagger
 * /api/promotions/residence/{id}:
 *   get:
 *     summary: Récupère les promotions pour une résidence spécifique
 *     tags: [Promotions]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID de la résidence
 *     responses:
 *       200:
 *         description: Liste des promotions pour la résidence
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 count:
 *                   type: integer
 *                 data:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Promotion'
 */
router.get('/residence/:id', getResidencePromotions);

/**
 * @swagger
 * /api/promotions/{id}:
 *   get:
 *     summary: Récupère une promotion par son ID
 *     tags: [Promotions]
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID de la promotion
 *     responses:
 *       200:
 *         description: Détails de la promotion
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Promotion'
 *       404:
 *         description: Promotion non trouvée
 *   put:
 *     summary: Mettre à jour une promotion
 *     tags: [Promotions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID de la promotion
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/Promotion'
 *     responses:
 *       200:
 *         description: Promotion mise à jour
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   $ref: '#/components/schemas/Promotion'
 *       404:
 *         description: Promotion non trouvée
 *   delete:
 *     summary: Supprimer une promotion
 *     tags: [Promotions]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID de la promotion
 *     responses:
 *       200:
 *         description: Promotion supprimée
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *       404:
 *         description: Promotion non trouvée
 */
router.route('/:id')
    .get(getPromotion)
    .put(protect, authorize('admin', 'partner'), updatePromotion)
    .delete(protect, authorize('admin', 'partner'), deletePromotion);

// Route de test simple
router.get('/test', (req, res) => {
  res.status(200).json({
    success: true,
    message: 'Le routeur de promotions fonctionne correctement!'
  });
});

module.exports = router;
