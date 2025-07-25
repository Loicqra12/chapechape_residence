/**
 * @swagger
 * tags:
 *   name: Maps
 *   description: Services de géolocalisation et cartographie
 */

/**
 * @swagger
 * /api/maps/nearby:
 *   get:
 *     summary: Récupérer les résidences à proximité d'une position
 *     tags: [Maps]
 *     parameters:
 *       - in: query
 *         name: latitude
 *         required: true
 *         schema:
 *           type: number
 *           format: float
 *         description: Latitude de la position de référence
 *       - in: query
 *         name: longitude
 *         required: true
 *         schema:
 *           type: number
 *           format: float
 *         description: Longitude de la position de référence
 *       - in: query
 *         name: radius
 *         schema:
 *           type: number
 *           default: 10
 *         description: Rayon de recherche en kilomètres
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 20
 *         description: Nombre maximum de résidences à retourner
 *     responses:
 *       200:
 *         description: Liste des résidences à proximité
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
 *                       name:
 *                         type: string
 *                         description: Nom de la résidence
 *                       location:
 *                         type: object
 *                         properties:
 *                           coordinates:
 *                             type: array
 *                             items:
 *                               type: number
 *                             description: Coordonnées [longitude, latitude]
 *                           address:
 *                             type: string
 *                             description: Adresse complète
 *                       distance:
 *                         type: number
 *                         description: Distance en kilomètres
 *                       price:
 *                         type: number
 *                         description: Prix par nuit
 *       400:
 *         description: Paramètres invalides
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
 * /api/maps/autocomplete:
 *   get:
 *     summary: Autocomplétion d'adresses
 *     tags: [Maps]
 *     parameters:
 *       - in: query
 *         name: input
 *         required: true
 *         schema:
 *           type: string
 *         description: Texte de recherche pour l'autocomplétion
 *       - in: query
 *         name: types
 *         schema:
 *           type: string
 *           enum: [address, establishment, geocode]
 *           default: address
 *         description: Type de lieu à rechercher
 *       - in: query
 *         name: country
 *         schema:
 *           type: string
 *         description: Code pays pour limiter la recherche (ex. FR, CI)
 *     responses:
 *       200:
 *         description: Suggestions d'adresses
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
 *                       place_id:
 *                         type: string
 *                         description: ID unique du lieu
 *                       description:
 *                         type: string
 *                         description: Description complète du lieu
 *                       structured_formatting:
 *                         type: object
 *                         properties:
 *                           main_text:
 *                             type: string
 *                             description: Texte principal
 *                           secondary_text:
 *                             type: string
 *                             description: Texte secondaire
 *       400:
 *         description: Paramètre de recherche manquant
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
 * /api/maps/geocode:
 *   post:
 *     summary: Convertir une adresse en coordonnées GPS
 *     tags: [Maps]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - address
 *             properties:
 *               address:
 *                 type: string
 *                 description: Adresse à géocoder
 *               region:
 *                 type: string
 *                 description: Région pour améliorer la précision
 *     responses:
 *       200:
 *         description: Coordonnées GPS de l'adresse
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
 *                     latitude:
 *                       type: number
 *                       format: float
 *                       description: Latitude
 *                     longitude:
 *                       type: number
 *                       format: float
 *                       description: Longitude
 *                     formatted_address:
 *                       type: string
 *                       description: Adresse formatée
 *                     place_id:
 *                       type: string
 *                       description: ID unique du lieu
 *       400:
 *         description: Adresse invalide ou manquante
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
 *         description: Adresse non trouvée
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
 * /api/maps/reverse-geocode:
 *   post:
 *     summary: Convertir des coordonnées GPS en adresse
 *     tags: [Maps]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - latitude
 *               - longitude
 *             properties:
 *               latitude:
 *                 type: number
 *                 format: float
 *                 description: Latitude
 *               longitude:
 *                 type: number
 *                 format: float
 *                 description: Longitude
 *     responses:
 *       200:
 *         description: Adresse correspondant aux coordonnées
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
 *                     formatted_address:
 *                       type: string
 *                       description: Adresse complète formatée
 *                     address_components:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           long_name:
 *                             type: string
 *                           short_name:
 *                             type: string
 *                           types:
 *                             type: array
 *                             items:
 *                               type: string
 *                       description: Composants détaillés de l'adresse
 *                     place_id:
 *                       type: string
 *                       description: ID unique du lieu
 *       400:
 *         description: Coordonnées invalides
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
 *         description: Aucune adresse trouvée pour ces coordonnées
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
