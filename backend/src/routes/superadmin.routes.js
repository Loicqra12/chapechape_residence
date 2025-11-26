const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { isSuperAdmin } = require('../lib/roleMiddleware');
const superAdminController = require('../controllers/superadmin/superadmin.controller');

// Routes pour la gestion des clients et partenaires
router.get('/clients', protect, isSuperAdmin, superAdminController.getAllClients);
router.get('/partners', protect, isSuperAdmin, superAdminController.getAllPartners);

// Routes pour la gestion des administrateurs
router.get('/admins', protect, isSuperAdmin, superAdminController.getAllAdmins);
router.post('/admins', protect, isSuperAdmin, superAdminController.createAdmin);
router.get('/admins/:id', protect, isSuperAdmin, superAdminController.getAdmin);
router.put('/admins/:id', protect, isSuperAdmin, superAdminController.updateAdmin);
router.delete('/admins/:id', protect, isSuperAdmin, superAdminController.deleteAdmin);

// Routes pour les paramètres système
router.get('/settings', protect, isSuperAdmin, superAdminController.getSystemSettings);
router.put('/settings', protect, isSuperAdmin, superAdminController.updateSystemSettings);

// Routes pour les journaux d'activité
router.get('/activity-logs', protect, isSuperAdmin, superAdminController.getActivityLogs);
router.delete('/activity-logs', protect, isSuperAdmin, superAdminController.clearActivityLogs);

// Routes pour la gestion des tentatives de connexion
router.get('/login-attempts', protect, isSuperAdmin, superAdminController.getLoginAttempts);
router.delete('/login-attempts', protect, isSuperAdmin, superAdminController.clearLoginAttempts);

// Routes pour la gestion des IP bloquées
router.get('/blocked-ips', protect, isSuperAdmin, superAdminController.getBlockedIPs);
router.post('/blocked-ips', protect, isSuperAdmin, superAdminController.blockIP);
router.delete('/blocked-ips/:ip', protect, isSuperAdmin, superAdminController.unblockIP);

module.exports = router;
