/**
 * Documentation Swagger pour les endpoints de résidences
 * 
 * @swagger
 * tags:
 *   name: Résidences
 *   description: Gestion des résidences et propriétés
 */

/**
 * @swagger
 * /api/residences:
 *   get:
 *     summary: Récupérer toutes les résidences disponibles
 *     tags: [Résidences]
 *     parameters:
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
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Terme de recherche
 *       - in: query
 *         name: minPrice
 *         schema:
 *           type: number
 *         description: Prix minimum
 *       - in: query
 *         name: maxPrice
 *         schema:
 *           type: number
 *         description: Prix maximum
 *       - in: query
 *         name: city
 *         schema:
 *           type: string
 *         description: Ville
 *       - in: query
 *         name: hasPool
 *         schema:
 *           type: boolean
 *         description: Propriétés avec piscine
 *       - in: query
 *         name: isVacationResidence
 *         schema:
 *           type: boolean
 *         description: Résidences de vacances
 *       - in: query
 *         name: isSpecialResidence
 *         schema:
 *           type: boolean
 *         description: Résidences spéciales
 *       - in: query
 *         name: minBedrooms
 *         schema:
 *           type: integer
 *         description: Nombre minimum de chambres
 *       - in: query
 *         name: minCapacity
 *         schema:
 *           type: integer
 *         description: Capacité minimum
 *     responses:
 *       200:
 *         description: Liste paginée des résidences
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/PaginatedResponse'
 *       500:
 *         description: Erreur serveur
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 * 
 *   post:
 *     summary: Créer une nouvelle résidence
 *     tags: [Résidences]
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
 *               - location
 *               - price
 *             properties:
 *               name:
 *                 type: string
 *                 description: Nom de la résidence
 *               description:
 *                 type: string
 *                 description: Description détaillée
 *               location:
 *                 type: object
 *                 properties:
 *                   address:
 *                     type: string
 *                     description: Adresse complète
 *                   city:
 *                     type: string
 *                     description: Ville
 *                   country:
 *                     type: string
 *                     description: Pays
 *                   coordinates:
 *                     type: array
 *                     items:
 *                       type: number
 *                     description: Coordonnées [longitude, latitude]
 *               price:
 *                 type: number
 *                 description: Prix par nuit
 *               capacity:
 *                 type: integer
 *                 description: Nombre de personnes
 *               bedrooms:
 *                 type: integer
 *                 description: Nombre de chambres
 *               bathrooms:
 *                 type: integer
 *                 description: Nombre de salles de bain
 *               amenities:
 *                 type: array
 *                 items:
 *                   type: string
 *                 description: Liste des équipements
 *               isAvailable:
 *                 type: boolean
 *                 description: Disponibilité
 *               hasPool:
 *                 type: boolean
 *                 description: Présence d'une piscine
 *               isVacationResidence:
 *                 type: boolean
 *                 description: Résidence de vacances
 *               isSpecialResidence:
 *                 type: boolean
 *                 description: Résidence spéciale
 *     responses:
 *       201:
 *         description: Résidence créée
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Residence'
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
 * /api/residences/{id}:
 *   get:
 *     summary: Récupérer les détails d'une résidence
 *     tags: [Résidences]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la résidence
 *     responses:
 *       200:
 *         description: Détails de la résidence
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Residence'
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
 *   put:
 *     summary: Mettre à jour une résidence
 *     tags: [Résidences]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la résidence
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 description: Nom de la résidence
 *               description:
 *                 type: string
 *                 description: Description détaillée
 *               location:
 *                 type: object
 *                 properties:
 *                   address:
 *                     type: string
 *                     description: Adresse complète
 *                   city:
 *                     type: string
 *                     description: Ville
 *                   country:
 *                     type: string
 *                     description: Pays
 *                   coordinates:
 *                     type: array
 *                     items:
 *                       type: number
 *                     description: Coordonnées [longitude, latitude]
 *               price:
 *                 type: number
 *                 description: Prix par nuit
 *               capacity:
 *                 type: integer
 *                 description: Nombre de personnes
 *               bedrooms:
 *                 type: integer
 *                 description: Nombre de chambres
 *               bathrooms:
 *                 type: integer
 *                 description: Nombre de salles de bain
 *               amenities:
 *                 type: array
 *                 items:
 *                   type: string
 *                 description: Liste des équipements
 *               isAvailable:
 *                 type: boolean
 *                 description: Disponibilité
 *               hasPool:
 *                 type: boolean
 *                 description: Présence d'une piscine
 *               isVacationResidence:
 *                 type: boolean
 *                 description: Résidence de vacances
 *               isSpecialResidence:
 *                 type: boolean
 *                 description: Résidence spéciale
 *     responses:
 *       200:
 *         description: Résidence mise à jour
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/Residence'
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
 *       403:
 *         description: Accès interdit
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
 *   delete:
 *     summary: Supprimer une résidence
 *     tags: [Résidences]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la résidence
 *     responses:
 *       200:
 *         description: Résidence supprimée
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
 *                   example: "Résidence supprimée avec succès"
 *       401:
 *         description: Non autorisé
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ApiError'
 *       403:
 *         description: Accès interdit
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
 */

/**
 * @swagger
 * /api/residences/{id}/images:
 *   post:
 *     summary: Ajouter des images à une résidence
 *     tags: [Résidences]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la résidence
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               images:
 *                 type: array
 *                 items:
 *                   type: string
 *                   format: binary
 *                 description: Images à téléverser (max 10)
 *     responses:
 *       200:
 *         description: Images ajoutées
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
 *                     images:
 *                       type: array
 *                       items:
 *                         type: string
 *                       description: URLs des images
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
 *       403:
 *         description: Accès interdit
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
 */

/**
 * @swagger
 * /api/residences/{id}/availability:
 *   get:
 *     summary: Vérifier la disponibilité d'une résidence
 *     tags: [Résidences]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de la résidence
 *       - in: query
 *         name: checkIn
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Date d'arrivée (YYYY-MM-DD)
 *       - in: query
 *         name: checkOut
 *         required: true
 *         schema:
 *           type: string
 *           format: date
 *         description: Date de départ (YYYY-MM-DD)
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
 *                     available:
 *                       type: boolean
 *                       example: true
 *                     price:
 *                       type: number
 *                       example: 1050
 *                     nights:
 *                       type: integer
 *                       example: 7
 *       400:
 *         description: Données invalides
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
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
