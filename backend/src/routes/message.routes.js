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
    createConversation
} = require('../controllers/message.controller');

// Middleware d'authentification pour toutes les routes
router.use(protect);

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

module.exports = router;
