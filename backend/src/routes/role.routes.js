const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { isSuperAdmin } = require('../lib/roleMiddleware');
const roleController = require('../controllers/role.controller');

// Routes pour la gestion des rôles (accessibles uniquement aux super admins)
router.get('/roles', protect, isSuperAdmin, roleController.getAllRoles);
router.post('/roles', protect, isSuperAdmin, roleController.createRole);
router.get('/roles/:id', protect, isSuperAdmin, roleController.getRole);
router.put('/roles/:id', protect, isSuperAdmin, roleController.updateRole);
router.delete('/roles/:id', protect, isSuperAdmin, roleController.deleteRole);

// Routes pour la gestion des permissions
router.get('/permissions', protect, isSuperAdmin, roleController.getAllPermissions);
router.post('/permissions', protect, isSuperAdmin, roleController.createPermission);
router.get('/permissions/:id', protect, isSuperAdmin, roleController.getPermission);
router.put('/permissions/:id', protect, isSuperAdmin, roleController.updatePermission);
router.delete('/permissions/:id', protect, isSuperAdmin, roleController.deletePermission);

module.exports = router;
