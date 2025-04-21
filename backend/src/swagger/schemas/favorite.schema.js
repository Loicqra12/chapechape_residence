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
 *         _id:
 *           type: string
 *           description: ID unique du favori
 *         user:
 *           type: string
 *           description: ID de l'utilisateur qui a ajouté cette résidence à ses favoris
 *         residence:
 *           type: string
 *           description: ID de la résidence ajoutée aux favoris (peut être expandé en objet complet)
 *         createdAt:
 *           type: string
 *           format: date-time
 *           description: Date d'ajout aux favoris
 *       example:
 *         _id: "60d21b4667d0d8992e610c88"
 *         user: "60d21b4667d0d8992e610c85"
 *         residence: "60d21b4667d0d8992e610c87"
 *         createdAt: "2023-01-01T12:00:00Z"
*/ 