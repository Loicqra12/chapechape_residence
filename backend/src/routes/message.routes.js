const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
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
    .get(getConversations)
    .post(createConversation);

router.route('/conversations/:id')
    .get(getConversation);

router.route('/conversations/:id/messages')
    .get(getMessages)
    .post(sendMessage);

router.route('/conversations/:id/attachments')
    .post(uploadAttachment);

router.route('/conversations/:id/read')
    .patch(markAsRead);

module.exports = router;
