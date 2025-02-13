const express = require('express');
const {
    getNotifications,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    deleteReadNotifications
} = require('../controllers/notification.controller');

const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');

router.use(protect); // Toutes les routes nécessitent une authentification

// Routes principales
router.route('/')
    .get(getNotifications);

// Routes spéciales (doivent être avant les routes avec :id)
router.route('/read-all')
    .put(markAllAsRead);

router.route('/read')
    .delete(deleteReadNotifications);

// Routes avec paramètres
router.route('/:id/read')
    .put(markAsRead);

router.route('/:id')
    .delete(deleteNotification);

module.exports = router;
