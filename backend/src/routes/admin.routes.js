const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');  // Correction du chemin
const { isAdmin } = require('../lib/roleMiddleware');
const adminController = require('../controllers/admin.controller');
const roleController = require('../controllers/role.controller');

// Dashboard et statistiques
router.get('/dashboard', protect, isAdmin, adminController.getDashboardStats);
router.get('/payments', protect, isAdmin, adminController.getPayments);
router.get('/stats/advanced', protect, isAdmin, adminController.getAdvancedStats);
router.get('/activity-logs', protect, isAdmin, adminController.getActivityLogs);

// Gestion des administrateurs
router.get('/admins', protect, isAdmin, adminController.getAllAdmins);
router.post('/admins', protect, isAdmin, adminController.createAdmin);
router.get('/admins/:id', protect, isAdmin, adminController.getAdmin);
router.put('/admins/:id', protect, isAdmin, adminController.updateAdmin);
router.delete('/admins/:id', protect, isAdmin, adminController.deleteAdmin);

// Gestion des utilisateurs
router.get('/users', protect, isAdmin, adminController.getAllUsers);
router.get('/users/:id', protect, isAdmin, adminController.getUser);
router.put('/users/:id', protect, isAdmin, adminController.updateUser);
router.delete('/users/:id', protect, isAdmin, adminController.deleteUser);

// Gestion des partenaires
router.get('/partners', protect, isAdmin, adminController.getAllPartners);
router.get('/partners/:id', protect, isAdmin, adminController.getPartner);
router.put('/partners/:id', protect, isAdmin, adminController.updatePartner);
router.delete('/partners/:id', protect, isAdmin, adminController.deletePartner);
router.put('/partners/:id/verify', protect, isAdmin, adminController.verifyPartner);

// Gestion des disponibilités
router.get('/residences/:residenceId/availability', protect, isAdmin, adminController.getResidenceAvailability);
router.post('/residences/:residenceId/block-dates', protect, isAdmin, adminController.blockResidenceDates);
router.delete('/residences/:residenceId/unblock-dates', protect, isAdmin, adminController.unblockResidenceDates);

// Gestion des résidences
router.get('/residences', protect, isAdmin, adminController.getAllResidences);
router.get('/residences/pending', protect, isAdmin, adminController.getPendingResidences);
router.get('/residences/:id', protect, isAdmin, adminController.getResidence);
router.put('/residences/:id/validate', protect, isAdmin, adminController.validateResidence);
router.put('/residences/:id/reject', protect, isAdmin, adminController.rejectResidence);
router.put('/residences/:id/verify', protect, isAdmin, adminController.verifyResidence);

// Gestion des rôles - REAL CONTROLLER
router.get('/roles', protect, isAdmin, roleController.getAllRoles);
router.post('/roles', protect, isAdmin, roleController.createRole);
router.get('/roles/:id', protect, isAdmin, roleController.getRole);
router.put('/roles/:id', protect, isAdmin, roleController.updateRole);
router.delete('/roles/:id', protect, isAdmin, roleController.deleteRole);

// Gestion des permissions - REAL CONTROLLER
router.get('/permissions', protect, isAdmin, roleController.getAllPermissions);
router.post('/permissions', protect, isAdmin, roleController.createPermission);
router.get('/permissions/:id', protect, isAdmin, roleController.getPermission);
router.put('/permissions/:id', protect, isAdmin, roleController.updatePermission);
router.delete('/permissions/:id', protect, isAdmin, roleController.deletePermission);

module.exports = router;
