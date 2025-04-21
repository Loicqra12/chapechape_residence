/**
 * @swagger
 * tags:
 *   name: Disponibilité
 *   description: Gestion des disponibilités des résidences
 */

/**
 * @swagger
 * /api/availabilities:
 *   get:
 *     summary: Récupérer les disponibilités des résidences
 *     tags: [Disponibilité]
 *     parameters:
 *       - in: query
 *         name: residenceId
 *         schema:
 *           type: string
 *         description: ID de la résidence pour filtrer les disponibilités
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de début pour la recherche (YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de fin pour la recherche (YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: Disponibilités récupérées avec succès
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
 *                       residenceId:
 *                         type: string
 *                         example: "60d21b4667d0d8992e610c90"
 *                       date:
 *                         type: string
 *                         format: date
 *                         example: "2023-07-15"
 *                       isAvailable:
 *                         type: boolean
 *                         example: true
 *                       price:
 *                         type: number
 *                         example: 150
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
 *     summary: Créer ou mettre à jour des disponibilités
 *     tags: [Disponibilité]
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
 *               - dates
 *             properties:
 *               residenceId:
 *                 type: string
 *                 example: "60d21b4667d0d8992e610c90"
 *               dates:
 *                 type: array
 *                 items:
 *                   type: object
 *                   required:
 *                     - date
 *                     - isAvailable
 *                   properties:
 *                     date:
 *                       type: string
 *                       format: date
 *                       example: "2023-07-15"
 *                     isAvailable:
 *                       type: boolean
 *                       example: true
 *                     price:
 *                       type: number
 *                       example: 150
 *     responses:
 *       201:
 *         description: Disponibilités créées ou mises à jour avec succès
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
 *                   example: "Disponibilités mises à jour avec succès"
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       _id:
 *                         type: string
 *                       residenceId:
 *                         type: string
 *                       date:
 *                         type: string
 *                         format: date
 *                       isAvailable:
 *                         type: boolean
 *                       price:
 *                         type: number
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
 * /api/availabilities/bulk:
 *   post:
 *     summary: Mettre à jour plusieurs disponibilités en masse
 *     tags: [Disponibilité]
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
 *               - startDate
 *               - endDate
 *               - isAvailable
 *             properties:
 *               residenceId:
 *                 type: string
 *                 example: "60d21b4667d0d8992e610c90"
 *               startDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-07-15"
 *               endDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-07-30"
 *               isAvailable:
 *                 type: boolean
 *                 example: true
 *               price:
 *                 type: number
 *                 example: 150
 *     responses:
 *       200:
 *         description: Disponibilités mises à jour en masse avec succès
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
 *                   example: "Disponibilités mises à jour avec succès"
 *                 count:
 *                   type: number
 *                   example: 16
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
 * /api/availabilities/residence/{residenceId}:
 *   get:
 *     summary: Récupérer les disponibilités d'une résidence spécifique
 *     tags: [Disponibilité]
 *     parameters:
 *       - in: path
 *         name: residenceId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la résidence
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de début pour la recherche (YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de fin pour la recherche (YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: Disponibilités récupérées avec succès
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
 *                       residenceId:
 *                         type: string
 *                       date:
 *                         type: string
 *                         format: date
 *                       isAvailable:
 *                         type: boolean
 *                       price:
 *                         type: number
 *       404:
 *         description: Résidence non trouvée
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/availabilities/check:
 *   post:
 *     summary: Vérifier la disponibilité d'une résidence pour une période donnée
 *     tags: [Disponibilité]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - residenceId
 *               - startDate
 *               - endDate
 *             properties:
 *               residenceId:
 *                 type: string
 *                 example: "60d21b4667d0d8992e610c90"
 *               startDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-07-15"
 *               endDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-07-20"
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
 *                 isAvailable:
 *                   type: boolean
 *                   example: true
 *                 unavailableDates:
 *                   type: array
 *                   items:
 *                     type: string
 *                     format: date
 *                   example: []
 *                 totalPrice:
 *                   type: number
 *                   example: 750
 *                 nightsCount:
 *                   type: number
 *                   example: 5
 *       400:
 *         description: Données invalides
 *       404:
 *         description: Résidence non trouvée
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/availability/check:
 *   get:
 *     summary: Vérifier la disponibilité d'une résidence pour des dates données
 *     tags: [Availability]
 *     parameters:
 *       - in: query
 *         name: residenceId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la résidence
 *       - in: query
 *         name: startDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de début (YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de fin (YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: Disponibilité vérifiée
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
 *                     isAvailable:
 *                       type: boolean
 *                       example: true
 *       400:
 *         description: Données invalides
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/availability/calendar:
 *   get:
 *     summary: Récupérer le calendrier de disponibilité d'une résidence
 *     tags: [Availability]
 *     parameters:
 *       - in: query
 *         name: residenceId
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la résidence
 *       - in: query
 *         name: startDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de début (YYYY-MM-DD)
 *       - in: query
 *         name: endDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de fin (YYYY-MM-DD)
 *     responses:
 *       200:
 *         description: Calendrier de disponibilité
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
 *                       date:
 *                         type: string
 *                         format: date
 *                         example: "2023-07-01"
 *                       status:
 *                         type: string
 *                         enum: [available, reserved, blocked]
 *                         example: "available"
 *                       price:
 *                         type: number
 *                         example: 120
 *       400:
 *         description: Données invalides
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/availability/block:
 *   put:
 *     summary: Bloquer une plage de dates pour une résidence
 *     tags: [Availability]
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
 *               - startDate
 *               - endDate
 *             properties:
 *               residenceId:
 *                 type: string
 *                 example: "60d21b4667d0d8992e610c70"
 *               startDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-08-01"
 *               endDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-08-15"
 *               reason:
 *                 type: string
 *                 example: "Rénovation de la propriété"
 *     responses:
 *       200:
 *         description: Dates bloquées avec succès
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
 *                     blockedDates:
 *                       type: array
 *                       items:
 *                         type: string
 *                         format: date
 *                         example: "2023-08-01"
 *                     message:
 *                       type: string
 *                       example: "Dates bloquées avec succès"
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/availability/unblock:
 *   put:
 *     summary: Débloquer une plage de dates pour une résidence
 *     tags: [Availability]
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
 *               - startDate
 *               - endDate
 *             properties:
 *               residenceId:
 *                 type: string
 *                 example: "60d21b4667d0d8992e610c70"
 *               startDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-08-01"
 *               endDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-08-15"
 *     responses:
 *       200:
 *         description: Dates débloquées avec succès
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
 *                     unblockedDates:
 *                       type: array
 *                       items:
 *                         type: string
 *                         format: date
 *                         example: "2023-08-01"
 *                     message:
 *                       type: string
 *                       example: "Dates débloquées avec succès"
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/availability/pricing:
 *   put:
 *     summary: Mettre à jour les prix pour une plage de dates
 *     tags: [Availability]
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
 *               - startDate
 *               - endDate
 *               - price
 *             properties:
 *               residenceId:
 *                 type: string
 *                 example: "60d21b4667d0d8992e610c70"
 *               startDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-08-01"
 *               endDate:
 *                 type: string
 *                 format: date
 *                 example: "2023-08-15"
 *               price:
 *                 type: number
 *                 example: 150
 *               applyToWeekends:
 *                 type: boolean
 *                 example: true
 *               applyToWeekdays:
 *                 type: boolean
 *                 example: true
 *     responses:
 *       200:
 *         description: Prix mis à jour avec succès
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
 *                     updatedDates:
 *                       type: array
 *                       items:
 *                         type: string
 *                         format: date
 *                         example: "2023-08-01"
 *                     message:
 *                       type: string
 *                       example: "Prix mis à jour avec succès"
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès interdit
 *       500:
 *         description: Erreur serveur
 */ 