const express = require('express');
const {
    getNotifications,
    markAsRead,
    markAllAsRead,
    deleteNotification,
    deleteReadNotifications,
    getUnreadCount
} = require('../controllers/notification.controller');

const router = express.Router();
const { protect, authorize } = require('../middlewares/auth.middleware');

router.use(protect); // Toutes les routes nécessitent une authentification

// Routes principales
router.route('/')
    .get(authorize('admin', 'superadmin', 'partner', 'client'), getNotifications);

// Routes spéciales (doivent être avant les routes avec :id)
router.route('/read-all')
    .put(authorize('admin', 'superadmin', 'partner', 'client'), markAllAsRead);

router.route('/read')
    .delete(authorize('admin', 'superadmin', 'partner', 'client'), deleteReadNotifications);

// Route pour compter les notifications non lues
router.route('/unread/count')
    .get(authorize('admin', 'superadmin', 'partner', 'client'), getUnreadCount);

// Routes avec paramètres
router.route('/:id/read')
    .put(authorize('admin', 'superadmin', 'partner', 'client'), markAsRead);

router.route('/:id')
    .delete(authorize('admin', 'superadmin', 'partner', 'client'), deleteNotification);

module.exports = router;
