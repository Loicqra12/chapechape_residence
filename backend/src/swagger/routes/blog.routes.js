/**
 * Documentation Swagger pour les endpoints de blog
 *
 * @swagger
 * tags:
 *   name: Blog
 *   description: Gestion du blog et des articles de contenu
 */

/**
 * @swagger
 * /api/blog:
 *   get:
 *     summary: Récupérer tous les articles de blog
 *     tags: [Blog]
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *         description: Numéro de page
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 10
 *         description: Nombre d'articles par page
 *       - in: query
 *         name: category
 *         schema:
 *           type: string
 *         description: Filtrer par catégorie
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: Rechercher dans le titre et contenu
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [draft, published, archived]
 *           default: published
 *         description: Statut des articles
 *     responses:
 *       200:
 *         description: Liste des articles récupérée
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
 *                     articles:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/BlogArticle'
 *                     pagination:
 *                       $ref: '#/components/schemas/Pagination'
 *       500:
 *         description: Erreur serveur
 *   post:
 *     summary: Créer un nouvel article de blog (admin uniquement)
 *     tags: [Blog]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - title
 *               - content
 *               - category
 *             properties:
 *               title:
 *                 type: string
 *                 example: "Guide complet pour réussir votre location saisonnière"
 *               slug:
 *                 type: string
 *                 description: "Généré automatiquement si non fourni"
 *                 example: "guide-location-saisonniere"
 *               excerpt:
 *                 type: string
 *                 example: "Découvrez tous nos conseils pour optimiser vos revenus locatifs"
 *               content:
 *                 type: string
 *                 description: "Contenu HTML de l'article"
 *               category:
 *                 type: string
 *                 example: "conseils"
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *                 example: ["location", "revenus", "optimisation"]
 *               featuredImage:
 *                 type: string
 *                 example: "https://example.com/images/blog/guide-location.jpg"
 *               status:
 *                 type: string
 *                 enum: [draft, published, archived]
 *                 default: draft
 *               isFeatured:
 *                 type: boolean
 *                 default: false
 *               seoTitle:
 *                 type: string
 *                 description: "Titre SEO (optionnel)"
 *               seoDescription:
 *                 type: string
 *                 description: "Description SEO (optionnelle)"
 *               publishedAt:
 *                 type: string
 *                 format: date-time
 *                 description: "Date de publication (optionnelle)"
 *     responses:
 *       201:
 *         description: Article créé avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/BlogArticle'
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux administrateurs
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/blog/featured:
 *   get:
 *     summary: Récupérer les articles en vedette
 *     tags: [Blog]
 *     parameters:
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 5
 *         description: Nombre d'articles en vedette à récupérer
 *     responses:
 *       200:
 *         description: Articles en vedette récupérés
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
 *                     $ref: '#/components/schemas/BlogArticle'
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/blog/categories:
 *   get:
 *     summary: Récupérer toutes les catégories de blog
 *     tags: [Blog]
 *     responses:
 *       200:
 *         description: Liste des catégories récupérée
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
 *                       name:
 *                         type: string
 *                         example: "Conseils"
 *                       slug:
 *                         type: string
 *                         example: "conseils"
 *                       description:
 *                         type: string
 *                         example: "Conseils et astuces pour les propriétaires"
 *                       articlesCount:
 *                         type: integer
 *                         example: 15
 *                       color:
 *                         type: string
 *                         example: "#3B82F6"
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/blog/{slug}:
 *   get:
 *     summary: Récupérer un article par son slug
 *     tags: [Blog]
 *     parameters:
 *       - in: path
 *         name: slug
 *         required: true
 *         schema:
 *           type: string
 *         description: Slug unique de l'article
 *         example: "guide-location-saisonniere"
 *     responses:
 *       200:
 *         description: Article récupéré avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   allOf:
 *                     - $ref: '#/components/schemas/BlogArticle'
 *                     - type: object
 *                       properties:
 *                         content:
 *                           type: string
 *                           description: "Contenu complet HTML de l'article"
 *                         relatedArticles:
 *                           type: array
 *                           items:
 *                             $ref: '#/components/schemas/BlogArticle'
 *                         previousArticle:
 *                           $ref: '#/components/schemas/BlogArticle'
 *                         nextArticle:
 *                           $ref: '#/components/schemas/BlogArticle'
 *       404:
 *         description: Article non trouvé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/blog/{id}/like:
 *   post:
 *     summary: Liker ou unliker un article
 *     tags: [Blog]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de l'article
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               userIdentifier:
 *                 type: string
 *                 description: "Identifiant utilisateur (IP, email, etc.)"
 *                 example: "192.168.1.1"
 *     responses:
 *       200:
 *         description: Like enregistré avec succès
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
 *                     liked:
 *                       type: boolean
 *                       example: true
 *                     totalLikes:
 *                       type: integer
 *                       example: 25
 *       404:
 *         description: Article non trouvé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/blog/{id}:
 *   put:
 *     summary: Mettre à jour un article (admin uniquement)
 *     tags: [Blog]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de l'article
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               title:
 *                 type: string
 *               slug:
 *                 type: string
 *               excerpt:
 *                 type: string
 *               content:
 *                 type: string
 *               category:
 *                 type: string
 *               tags:
 *                 type: array
 *                 items:
 *                   type: string
 *               featuredImage:
 *                 type: string
 *               status:
 *                 type: string
 *                 enum: [draft, published, archived]
 *               isFeatured:
 *                 type: boolean
 *               seoTitle:
 *                 type: string
 *               seoDescription:
 *                 type: string
 *               publishedAt:
 *                 type: string
 *                 format: date-time
 *     responses:
 *       200:
 *         description: Article mis à jour avec succès
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 data:
 *                   $ref: '#/components/schemas/BlogArticle'
 *       400:
 *         description: Données invalides
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux administrateurs
 *       404:
 *         description: Article non trouvé
 *       500:
 *         description: Erreur serveur
 *   delete:
 *     summary: Supprimer un article (admin uniquement)
 *     tags: [Blog]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: ID de l'article
 *     responses:
 *       200:
 *         description: Article supprimé avec succès
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
 *                   example: "Article supprimé avec succès"
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux administrateurs
 *       404:
 *         description: Article non trouvé
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * /api/blog/admin/stats:
 *   get:
 *     summary: Obtenir les statistiques du blog (admin uniquement)
 *     tags: [Blog]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Statistiques récupérées avec succès
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
 *                     totalArticles:
 *                       type: integer
 *                       example: 45
 *                     publishedArticles:
 *                       type: integer
 *                       example: 38
 *                     draftArticles:
 *                       type: integer
 *                       example: 7
 *                     totalViews:
 *                       type: integer
 *                       example: 125000
 *                     totalLikes:
 *                       type: integer
 *                       example: 3200
 *                     avgViewsPerArticle:
 *                       type: number
 *                       example: 3289.47
 *                     topCategories:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           category:
 *                             type: string
 *                             example: "Conseils"
 *                           count:
 *                             type: integer
 *                             example: 15
 *                           views:
 *                             type: integer
 *                             example: 45000
 *                     recentArticles:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/BlogArticle'
 *                     monthlyStats:
 *                       type: array
 *                       items:
 *                         type: object
 *                         properties:
 *                           month:
 *                             type: string
 *                             example: "2024-01"
 *                           articles:
 *                             type: integer
 *                             example: 5
 *                           views:
 *                             type: integer
 *                             example: 8500
 *                           likes:
 *                             type: integer
 *                             example: 245
 *       401:
 *         description: Non autorisé
 *       403:
 *         description: Accès réservé aux administrateurs
 *       500:
 *         description: Erreur serveur
 */

/**
 * @swagger
 * components:
 *   schemas:
 *     BlogArticle:
 *       type: object
 *       properties:
 *         _id:
 *           type: string
 *           example: "60d21b4667d0d8992e610c85"
 *         title:
 *           type: string
 *           example: "Guide complet pour réussir votre location saisonnière"
 *         slug:
 *           type: string
 *           example: "guide-location-saisonniere"
 *         excerpt:
 *           type: string
 *           example: "Découvrez tous nos conseils pour optimiser vos revenus locatifs"
 *         featuredImage:
 *           type: string
 *           example: "https://example.com/images/blog/guide-location.jpg"
 *         category:
 *           type: object
 *           properties:
 *             name:
 *               type: string
 *               example: "Conseils"
 *             slug:
 *               type: string
 *               example: "conseils"
 *         author:
 *           type: object
 *           properties:
 *             _id:
 *               type: string
 *             name:
 *               type: string
 *               example: "Équipe ChapeChape"
 *             avatar:
 *               type: string
 *         readTime:
 *           type: integer
 *           example: 5
 *           description: "Temps de lecture estimé en minutes"
 *         likesCount:
 *           type: integer
 *           example: 24
 *         viewsCount:
 *           type: integer
 *           example: 1250
 *         status:
 *           type: string
 *           enum: [draft, published, archived]
 *           example: "published"
 *         isFeatured:
 *           type: boolean
 *           example: false
 *         tags:
 *           type: array
 *           items:
 *             type: string
 *           example: ["location", "revenus", "optimisation"]
 *         seoTitle:
 *           type: string
 *           example: "Guide Location Saisonnière - Conseils ChapeChape"
 *         seoDescription:
 *           type: string
 *           example: "Découvrez nos conseils d'experts pour optimiser vos revenus de location saisonnière"
 *         publishedAt:
 *           type: string
 *           format: date-time
 *         createdAt:
 *           type: string
 *           format: date-time
 *         updatedAt:
 *           type: string
 *           format: date-time
 *     Pagination:
 *       type: object
 *       properties:
 *         page:
 *           type: integer
 *           example: 1
 *         limit:
 *           type: integer
 *           example: 10
 *         total:
 *           type: integer
 *           example: 45
 *         pages:
 *           type: integer
 *           example: 5
 */

// Ce fichier sert uniquement à documenter les endpoints pour Swagger
// Il n'exporte rien car il est uniquement lu par swagger-jsdoc
