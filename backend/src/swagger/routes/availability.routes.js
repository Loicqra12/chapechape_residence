/**
 * @swagger
 * tags:
 *   - name: Availability
 *     description: Gestion des disponibilités des résidences
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
 *       - in: query
 *         name: bookingType
 *         schema:
 *           type: string
 *           enum: [hour, day, week, month]
 *           default: day
 *         description: Type de réservation
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
 *                 data:
 *                   type: object
 *                   properties:
 *                     available:
 *                       type: boolean
 *                     unavailableDates:
 *                       type: array
 *                       items:
 *                         type: string
 *                         format: date
 *                     priceDetails:
 *                       type: object
 *       400:
 *         description: Paramètres invalides
 *       500:
 *         description: Erreur serveur
 *
 * /api/availability/flutter-check:
 *   get:
 *     summary: Vérifier la disponibilité — endpoint dédié app Flutter (sans authentification)
 *     tags: [Availability]
 *     parameters:
 *       - in: query
 *         name: residenceId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: startDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: endDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: bookingType
 *         schema:
 *           type: string
 *           enum: [hour, day, week, month]
 *           default: day
 *     responses:
 *       200:
 *         description: Disponibilité vérifiée
 *       400:
 *         description: Paramètres invalides
 *       500:
 *         description: Erreur serveur
 *
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
 *       - in: query
 *         name: startDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *       - in: query
 *         name: endDate
 *         required: true
 *         schema:
 *           type: string
 *           format: date
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
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       date:
 *                         type: string
 *                         format: date
 *                       status:
 *                         type: string
 *                         enum: [available, reserved, blocked]
 *                       price:
 *                         type: number
 *       400:
 *         description: Paramètres invalides
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/availability/block:
 *   put:
 *     summary: Bloquer une plage de dates pour une résidence (partenaire/admin)
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
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               reason:
 *                 type: string
 *                 description: Raison du blocage (optionnel)
 *     responses:
 *       200:
 *         description: Dates bloquées avec succès
 *       400:
 *         description: Données invalides ou conflit avec réservation existante
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires et admins
 *       500:
 *         description: Erreur serveur
 *
 * /api/availability/unblock:
 *   put:
 *     summary: Débloquer une plage de dates pour une résidence (partenaire/admin)
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
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *     responses:
 *       200:
 *         description: Dates débloquées avec succès
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires et admins
 *       500:
 *         description: Erreur serveur
 *
 * /api/availability/pricing:
 *   put:
 *     summary: Mettre à jour les prix pour une plage de dates (partenaire/admin)
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
 *               startDate:
 *                 type: string
 *                 format: date
 *               endDate:
 *                 type: string
 *                 format: date
 *               price:
 *                 type: number
 *                 description: Prix en XOF
 *     responses:
 *       200:
 *         description: Prix mis à jour avec succès
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Réservé aux partenaires et admins
 *       500:
 *         description: Erreur serveur
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
