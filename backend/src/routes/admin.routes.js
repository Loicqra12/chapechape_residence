const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');  // Correction du chemin
const { isAdmin, isSuperAdmin } = require('../lib/roleMiddleware');
const adminController = require('../controllers/admin.controller');
const roleController = require('../controllers/role.controller');
const opsAdminController = require('../controllers/ops-admin.controller');

// Dashboard et statistiques
router.get('/dashboard', protect, isAdmin, adminController.getDashboardStats);
router.get('/payments', protect, isAdmin, adminController.getPayments);
router.get('/stats/advanced', protect, isAdmin, adminController.getAdvancedStats);
router.get('/activity-logs', protect, isAdmin, adminController.getActivityLogs);

// Gestion des administrateurs — création / mutation : superadmin uniquement
router.get('/admins', protect, isAdmin, adminController.getAllAdmins);
router.post('/admins', protect, isSuperAdmin, adminController.createAdmin);
router.get('/admins/:id', protect, isAdmin, adminController.getAdmin);
router.put('/admins/:id', protect, isSuperAdmin, adminController.updateAdmin);
router.delete('/admins/:id', protect, isSuperAdmin, adminController.deleteAdmin);

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

// P1-07 — Ops Admin (Reservation / Refund / Inventory / Anomalies)
router.get('/ops/reservations', protect, isAdmin, opsAdminController.listReservations);
router.get('/ops/reservations/:id', protect, isAdmin, opsAdminController.getReservation);
router.post('/ops/reservations/:id/cancel', protect, isAdmin, opsAdminController.cancelReservation);
router.post('/ops/reservations/:id/checkin', protect, isAdmin, opsAdminController.checkinReservation);
router.post('/ops/reservations/:id/checkout', protect, isAdmin, opsAdminController.checkoutReservation);
router.get('/ops/refunds', protect, isAdmin, opsAdminController.listRefunds);
router.post('/ops/refunds/:id/confirm', protect, isAdmin, opsAdminController.confirmRefund);
router.get('/ops/inventory/:residenceId', protect, isAdmin, opsAdminController.getInventoryCalendar);
router.get('/ops/anomalies', protect, isAdmin, opsAdminController.listAnomalies);
router.get('/ops/audit', protect, isAdmin, opsAdminController.listAudit);

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

// Gestion des rôles / permissions — superadmin uniquement (évite élévation via RBAC)
router.get('/roles', protect, isSuperAdmin, roleController.getAllRoles);
router.post('/roles', protect, isSuperAdmin, roleController.createRole);
router.get('/roles/:id', protect, isSuperAdmin, roleController.getRole);
router.put('/roles/:id', protect, isSuperAdmin, roleController.updateRole);
router.delete('/roles/:id', protect, isSuperAdmin, roleController.deleteRole);

router.get('/permissions', protect, isSuperAdmin, roleController.getAllPermissions);
router.post('/permissions', protect, isSuperAdmin, roleController.createPermission);
router.get('/permissions/:id', protect, isSuperAdmin, roleController.getPermission);
router.put('/permissions/:id', protect, isSuperAdmin, roleController.updatePermission);
router.delete('/permissions/:id', protect, isSuperAdmin, roleController.deletePermission);

module.exports = router;
