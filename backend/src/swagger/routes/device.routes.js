/**
 * @swagger
 * tags:
 *   name: Device
 *   description: Gestion des appareils et préférences de notification
 */

/**
 * @swagger
 * /api/devices/register:
 *   post:
 *     summary: Enregistrer un nouvel appareil pour les notifications
 *     tags: [Device]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - deviceToken
 *               - platform
 *             properties:
 *               deviceToken:
 *                 type: string
 *                 description: Token unique de l'appareil pour les notifications push
 *               platform:
 *                 type: string
 *                 enum: [ios, android, web]
 *                 description: Plateforme de l'appareil
 *               deviceInfo:
 *                 type: object
 *                 properties:
 *                   model:
 *                     type: string
 *                     description: Modèle de l'appareil
 *                   version:
 *                     type: string
 *                     description: Version du système d'exploitation
 *                   appVersion:
 *                     type: string
 *                     description: Version de l'application
 *     responses:
 *       200:
 *         description: Appareil enregistré avec succès
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
 *                   example: "Appareil enregistré avec succès"
 *                 data:
 *                   type: object
 *                   properties:
 *                     deviceId:
 *                       type: string
 *                       description: ID unique de l'appareil enregistré
 *       400:
 *         description: Données invalides
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
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

/**
 * @swagger
 * /api/devices/unregister:
 *   delete:
 *     summary: Désinscrire un appareil des notifications
 *     tags: [Device]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - deviceToken
 *             properties:
 *               deviceToken:
 *                 type: string
 *                 description: Token de l'appareil à désinscrire
 *     responses:
 *       200:
 *         description: Appareil désinscrit avec succès
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
 *                   example: "Appareil désinscrit avec succès"
 *       400:
 *         description: Données invalides
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
 *         description: Appareil non trouvé
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
 * /api/devices/preferences:
 *   get:
 *     summary: Récupérer les préférences de notification de l'utilisateur
 *     tags: [Device]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Préférences de notification récupérées
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
 *                     bookingUpdates:
 *                       type: boolean
 *                       description: Notifications pour les mises à jour de réservation
 *                     promotions:
 *                       type: boolean
 *                       description: Notifications pour les promotions
 *                     messages:
 *                       type: boolean
 *                       description: Notifications pour les nouveaux messages
 *                     reminders:
 *                       type: boolean
 *                       description: Rappels de réservation
 *                     marketing:
 *                       type: boolean
 *                       description: Communications marketing
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
 *   put:
 *     summary: Mettre à jour les préférences de notification
 *     tags: [Device]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               bookingUpdates:
 *                 type: boolean
 *                 description: Activer/désactiver les notifications de réservation
 *               promotions:
 *                 type: boolean
 *                 description: Activer/désactiver les notifications de promotions
 *               messages:
 *                 type: boolean
 *                 description: Activer/désactiver les notifications de messages
 *               reminders:
 *                 type: boolean
 *                 description: Activer/désactiver les rappels
 *               marketing:
 *                 type: boolean
 *                 description: Activer/désactiver les communications marketing
 *     responses:
 *       200:
 *         description: Préférences mises à jour avec succès
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
 *                   example: "Préférences mises à jour avec succès"
 *                 data:
 *                   type: object
 *                   properties:
 *                     bookingUpdates:
 *                       type: boolean
 *                     promotions:
 *                       type: boolean
 *                     messages:
 *                       type: boolean
 *                     reminders:
 *                       type: boolean
 *                     marketing:
 *                       type: boolean
 *       400:
 *         description: Données invalides
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
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
