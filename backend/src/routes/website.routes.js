const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const rateLimit = require('express-rate-limit');
const Joi = require('joi');

const {
    submitContactForm,
    subscribeNewsletter,
    getWebsiteStats
} = require('../controllers/website.controller');

// Rate limiting pour les formulaires publics
const contactFormLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 5, // Maximum 5 tentatives par IP par fenêtre
    message: {
        success: false,
        error: 'Trop de tentatives. Veuillez réessayer dans 15 minutes.'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

const newsletterLimiter = rateLimit({
    windowMs: 60 * 60 * 1000, // 1 heure
    max: 3, // Maximum 3 inscriptions par IP par heure
    message: {
        success: false,
        error: 'Trop de tentatives d\'inscription. Veuillez réessayer dans 1 heure.'
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// Validation schemas (Joi format)
const contactFormValidation = {
    body: Joi.object({
        firstName: Joi.string()
            .min(2)
            .max(50)
            .pattern(/^[a-zA-ZÀ-ÿ\s-]+$/)
            .required()
            .messages({
                'string.pattern.base': 'Le prénom ne doit contenir que des lettres, espaces et tirets',
                'any.required': 'Le prénom est obligatoire'
            }),
        lastName: Joi.string()
            .min(2)
            .max(50)
            .pattern(/^[a-zA-ZÀ-ÿ\s-]+$/)
            .required()
            .messages({
                'string.pattern.base': 'Le nom ne doit contenir que des lettres, espaces et tirets',
                'any.required': 'Le nom est obligatoire'
            }),
        email: Joi.string()
            .email()
            .max(100)
            .required()
            .messages({
                'string.email': 'Format d\'email invalide',
                'any.required': 'L\'email est obligatoire'
            }),
        phone: Joi.string()
            .max(20)
            .pattern(/^[+]?[0-9\s-()]+$/)
            .optional()
            .allow('')
            .messages({
                'string.pattern.base': 'Format de téléphone invalide'
            }),
        company: Joi.string()
            .max(100)
            .optional()
            .allow(''),
        subject: Joi.string()
            .max(200)
            .optional()
            .allow(''),
        message: Joi.string()
            .min(10)
            .max(2000)
            .required()
            .messages({
                'string.min': 'Le message doit contenir au moins 10 caractères',
                'any.required': 'Le message est obligatoire'
            })
    })
};

const newsletterValidation = {
    body: Joi.object({
        email: Joi.string()
            .email()
            .max(100)
            .required()
            .messages({
                'string.email': 'Format d\'email invalide',
                'any.required': 'L\'email est obligatoire'
            }),
        firstName: Joi.string()
            .max(50)
            .pattern(/^[a-zA-ZÀ-ÿ\s-]+$/)
            .optional()
            .allow('')
            .messages({
                'string.pattern.base': 'Le prénom ne doit contenir que des lettres, espaces et tirets'
            }),
        lastName: Joi.string()
            .max(50)
            .pattern(/^[a-zA-ZÀ-ÿ\s-]+$/)
            .optional()
            .allow('')
            .messages({
                'string.pattern.base': 'Le nom ne doit contenir que des lettres, espaces et tirets'
            })
    })
};

/**
 * @swagger
 * /api/website/contact:
 *   post:
 *     summary: Submit contact form from website
 *     tags: [Website]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - firstName
 *               - lastName
 *               - email
 *               - message
 *             properties:
 *               firstName:
 *                 type: string
 *                 description: First name
 *                 example: "Jean"
 *               lastName:
 *                 type: string
 *                 description: Last name
 *                 example: "Dupont"
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Email address
 *                 example: "jean.dupont@email.com"
 *               phone:
 *                 type: string
 *                 description: Phone number (optional)
 *                 example: "+225 XX XX XX XX"
 *               company:
 *                 type: string
 *                 description: Company name (optional)
 *                 example: "Mon Entreprise"
 *               subject:
 *                 type: string
 *                 description: Message subject (optional)
 *                 example: "Demande d'information"
 *               message:
 *                 type: string
 *                 description: Message content
 *                 example: "Je souhaite obtenir plus d'informations sur vos services."
 *     responses:
 *       200:
 *         description: Message sent successfully
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
 *                   example: "Votre message a été envoyé avec succès. Nous vous répondrons bientôt !"
 *       400:
 *         description: Invalid input data
 *       429:
 *         description: Too many requests
 *       500:
 *         description: Server error
 */
router.post('/contact', contactFormLimiter, validate(contactFormValidation), submitContactForm);

/**
 * @swagger
 * /api/website/newsletter:
 *   post:
 *     summary: Subscribe to newsletter
 *     tags: [Website]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Email address
 *                 example: "user@email.com"
 *               firstName:
 *                 type: string
 *                 description: First name (optional)
 *                 example: "Marie"
 *               lastName:
 *                 type: string
 *                 description: Last name (optional)
 *                 example: "Martin"
 *     responses:
 *       200:
 *         description: Newsletter subscription successful
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
 *                   example: "Inscription à la newsletter réussie ! Vérifiez votre email de bienvenue."
 *       400:
 *         description: Invalid email or already subscribed
 *       429:
 *         description: Too many requests
 *       500:
 *         description: Server error
 */
router.post('/newsletter', newsletterLimiter, validate(newsletterValidation), subscribeNewsletter);

/**
 * @swagger
 * /api/website/stats:
 *   get:
 *     summary: Get website statistics (Admin only)
 *     tags: [Website]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Website statistics retrieved successfully
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
 *                     totalNewsletterSubscribers:
 *                       type: number
 *                       example: 1250
 *                     newSubscribersThisMonth:
 *                       type: number
 *                       example: 85
 *                     totalUsers:
 *                       type: number
 *                       example: 2340
 *                     lastUpdated:
 *                       type: string
 *                       format: date-time
 *       401:
 *         description: Not authorized
 *       403:
 *         description: Access forbidden (Admin only)
 */
router.get('/stats', protect, authorize('admin', 'superadmin'), getWebsiteStats);

module.exports = router;
