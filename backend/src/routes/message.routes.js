const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const validate = require('../middlewares/validate.middleware');
const messageValidation = require('../validations/message.validation');
const {
    getConversations,
    getConversation,
    getMessages,
    sendMessage,
    markAsRead,
    uploadAttachment,
    createConversation,
    sendWhatsAppMessage,
    testWhatsAppSend
} = require('../controllers/message.controller');

// Middleware d'authentification pour toutes les routes
router.use(protect);

// Route racine - alias pour /conversations (pour compatibilité avec le Dashboard)
router.get('/', validate(messageValidation.getConversations), getConversations);

// Routes des conversations
router.route('/conversations')
    .get(validate(messageValidation.getConversations), getConversations)
    .post(validate(messageValidation.createConversation), createConversation);

router.route('/conversations/:id')
    .get(validate(messageValidation.getConversation), getConversation);

router.route('/conversations/:id/messages')
    .get(validate(messageValidation.getMessages), getMessages)
    .post(validate(messageValidation.sendMessage), sendMessage);

router.route('/conversations/:id/attachments')
    .post(validate(messageValidation.uploadAttachment), uploadAttachment);

router.route('/conversations/:id/read')
    .patch(validate(messageValidation.markAsRead), markAsRead);

// ===== WHATSAPP BUSINESS ROUTES =====

// Route pour tester l'envoi WhatsApp simple (développement)
router.route('/whatsapp/test')
    .post(testWhatsAppSend);

// Route pour envoyer un message WhatsApp dans une conversation
router.route('/conversations/:id/whatsapp')
    .post(sendWhatsAppMessage);

// ===== FIN WHATSAPP ROUTES =====

module.exports = router;
