/**
 * @swagger
 * tags:
 *   name: Politique d'annulation
 *   description: Gestion des politiques d'annulation pour les résidences
 */

/**
 * @swagger
 * /api/cancellation-policies:
 *   get:
 *     summary: Récupérer toutes les politiques d'annulation
 *     tags: [Politique d'annulation]
 *     responses:
 *       200:
 *         description: Liste des politiques d'annulation
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
 *                         example: "60d21b4667d0d8992e610c85"
 *                       name:
 *                         type: string
 *                         example: "Flexible"
 *                       description:
 *                         type: string
 *                         example: "Annulation gratuite jusqu'à 48h avant l'arrivée"
 *                       refundRules:
 *                         type: array
 *                         items:
 *                           type: object
 *                           properties:
 *                             daysBeforeArrival:
 *                               type: number
 *                               example: 48
 *                             refundPercentage:
 *                               type: number
 *                               example: 100
 *                       isDefault:
 *                         type: boolean
 *                         example: true
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                       updatedAt:
 *                         type: string
 *                         format: date-time
 *       500:
 *         description: Erreur serveur
 * 
 *   post:
 *     summary: Créer une nouvelle politique d'annulation
 *     tags: [Politique d'annulation]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - description
 *               - refundRules
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Stricte"
 *               description:
 *                 type: string
 *                 example: "Annulation avec remboursement partiel jusqu'à 7 jours avant l'arrivée"
 *               refundRules:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - daysBeforeArrival
 *                     - refundPercentage
 *                   properties:
 *                     daysBeforeArrival:
 *                       type: number
 *                       example: 7
 *                     refundPercentage:
 *                       type: number
 *                       example: 50
 *               isDefault:
 *                 type: boolean
 *                 example: false
 *     responses:
 *       201:
 *         description: Politique d'annulation créée avec succès
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
 *                   properties:
 *                     _id:
 *                       type: string
 *                     name:
 *                       type: string
 *                     description:
 *                       type: string
 *                     refundRules:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           daysBeforeArrival:
 *                             type: number
 *                           refundPercentage:
 *                             type: number
 *                     isDefault:
 *                       type: boolean
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/cancellation-policies/{id}:
 *   get:
 *     summary: Récupérer une politique d'annulation par ID
 *     tags: [Politique d'annulation]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la politique d'annulation
 *     responses:
 *       200:
 *         description: Politique d'annulation récupérée avec succès
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
 *                   properties:
 *                     _id:
 *                       type: string
 *                     name:
 *                       type: string
 *                     description:
 *                       type: string
 *                     refundRules:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           daysBeforeArrival:
 *                             type: number
 *                           refundPercentage:
 *                             type: number
 *                     isDefault:
 *                       type: boolean
 *       404:
 *         description: Politique d'annulation non trouvée
 *       500:
 *         description: Erreur serveur
 * 
 *   put:
 *     summary: Mettre à jour une politique d'annulation
 *     tags: [Politique d'annulation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la politique d'annulation
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               description:
 *                 type: string
 *               refundRules:
 *                 type: array
 *                 items:
 *                   type: object
 *                   properties:
 *                     daysBeforeArrival:
 *                       type: number
 *                     refundPercentage:
 *                       type: number
 *               isDefault:
 *                 type: boolean
 *     responses:
 *       200:
 *         description: Politique d'annulation mise à jour avec succès
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
 *                   properties:
 *                     _id:
 *                       type: string
 *                     name:
 *                       type: string
 *                     description:
 *                       type: string
 *                     refundRules:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           daysBeforeArrival:
 *                             type: number
 *                           refundPercentage:
 *                             type: number
 *                     isDefault:
 *                       type: boolean
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé
 *       404:
 *         description: Politique d'annulation non trouvée
 *       500:
 *         description: Erreur serveur
 * 
 *   delete:
 *     summary: Supprimer une politique d'annulation
 *     tags: [Politique d'annulation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la politique d'annulation
 *     responses:
 *       200:
 *         description: Politique d'annulation supprimée avec succès
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
 *                   example: "Politique d'annulation supprimée avec succès"
 *       400:
 *         description: Impossible de supprimer la politique par défaut
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé
 *       404:
 *         description: Politique d'annulation non trouvée
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/cancellation-policies/default:
 *   get:
 *     summary: Récupérer la politique d'annulation par défaut
 *     tags: [Politique d'annulation]
 *     responses:
 *       200:
 *         description: Politique d'annulation par défaut
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
 *                   properties:
 *                     _id:
 *                       type: string
 *                     name:
 *                       type: string
 *                     description:
 *                       type: string
 *                     refundRules:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           daysBeforeArrival:
 *                             type: number
 *                           refundPercentage:
 *                             type: number
 *                     isDefault:
 *                       type: boolean
 *                       example: true
 *       404:
 *         description: Aucune politique d'annulation par défaut trouvée
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/cancellation-policies/{id}/set-default:
 *   put:
 *     summary: Définir une politique d'annulation comme politique par défaut
 *     tags: [Politique d'annulation]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la politique d'annulation
 *     responses:
 *       200:
 *         description: Politique d'annulation définie comme par défaut avec succès
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
 *                   example: "Politique d'annulation définie comme par défaut avec succès"
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès refusé
 *       404:
 *         description: Politique d'annulation non trouvée
 *       500:
 *         description: Erreur serveur
 */ 