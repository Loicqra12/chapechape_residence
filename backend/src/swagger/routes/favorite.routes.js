/**
 * Documentation Swagger pour les endpoints de favoris
 * 
 * @swagger
 * tags:
 *   name: Favoris
 *   description: Gestion des résidences favorites des utilisateurs
 */

/**
 * @swagger
 * /api/favorites:
 *   post:
 *     summary: Ajouter une résidence aux favoris
 *     tags: [Favoris]
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
 *                 description: ID de la résidence à ajouter aux favoris
 *     responses:
 *       201:
 *         description: Résidence ajoutée aux favoris
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Favorite'
 *       400:
 *         description: Résidence déjà dans les favoris
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       404:
 *         description: Résidence non trouvée
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *
 *   get:
 *     summary: Voir mes résidences favorites
 *     tags: [Favoris]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Liste des résidences favorites
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 count:
 *                   type: integer
 *                   example: 3
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       _id:
 *                         type: string
 *                         description: ID du favori
 *                       user:
 *                         type: string
 *                         description: ID de l'utilisateur
 *                       residence:
 *                         $ref: '#/components/schemas/Residence'
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                         description: Date d'ajout aux favoris
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

/**
 * @swagger
 * /api/favorites/check/{residenceId}:
 *   get:
 *     summary: Vérifier si une résidence est dans vos favoris
 *     tags: [Favoris]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: residenceId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID de la résidence à vérifier
 *     responses:
 *       200:
 *         description: Résultat de la vérification
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 isFavorite:
 *                   type: boolean
 *                   description: Indique si la résidence est dans les favoris
 *                   example: true
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

/**
 * @swagger
 * /api/favorites/{residenceId}:
 *   delete:
 *     summary: Supprimer une résidence des favoris
 *     tags: [Favoris]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: residenceId
 *         schema:
 *           type: string
 *         required: true
 *         description: ID de la résidence à supprimer des favoris
 *     responses:
 *       200:
 *         description: Résidence supprimée des favoris
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: object
 *                   example: {}
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       404:
 *         description: Favori non trouvé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

/**
 * @swagger
 * /api/favorites/stats:
 *   get:
 *     summary: Obtenir les statistiques des favoris
 *     tags: [Favoris]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistiques des favoris
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       _id:
 *                         type: string
 *                         description: ID de la résidence
 *                       count:
 *                         type: integer
 *                         description: Nombre de fois où la résidence a été ajoutée aux favoris
 *                       residence:
 *                         type: object
 *                         properties:
 *                           title:
 *                             type: string
 *                             description: Titre de la résidence
 *                           location:
 *                             type: object
 *                             description: Localisation de la résidence
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès interdit (réservé aux administrateurs)
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */ 