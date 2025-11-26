const express = require('express');
const router = express.Router();
const { protect } = require('../middlewares/auth.middleware');
const { isSuperAdmin } = require('../lib/roleMiddleware');
const validate = require('../middlewares/validate.middleware');
const maintenanceValidation = require('../validations/maintenance.validation');
const maintenanceController = require('../controllers/maintenance.controller');

/**
 * @route   GET /api/maintenance/mode
 * @desc    Get maintenance mode status (Public)
 * @access  Public
 */
router.get('/mode', maintenanceController.getMaintenanceMode);

// All routes below require authentication and SuperAdmin role
router.use(protect, isSuperAdmin);

/**
 * @route   GET /api/maintenance/status
 * @desc    Get system status
 * @access  Private/SuperAdmin
 */
router.get('/status', maintenanceController.getSystemStatus);

/**
 * @route   GET /api/maintenance/backups
 * @desc    Get all backups
 * @access  Private/SuperAdmin
 */
router.get('/backups', maintenanceController.getBackups);

/**
 * @route   POST /api/maintenance/backup
 * @desc    Create a new backup
 * @access  Private/SuperAdmin
 */
router.post(
  '/backup',
  validate(maintenanceValidation.createBackup),
  maintenanceController.createBackup
);

/**
 * @route   DELETE /api/maintenance/backup/:id
 * @desc    Delete a backup
 * @access  Private/SuperAdmin
 */
router.delete(
  '/backup/:id',
  validate(maintenanceValidation.deleteBackup),
  maintenanceController.deleteBackup
);

/**
 * @route   POST /api/maintenance/backup/:id/restore
 * @desc    Restore from backup
 * @access  Private/SuperAdmin
 */
router.post(
  '/backup/:id/restore',
  validate(maintenanceValidation.restoreBackup),
  maintenanceController.restoreBackup
);

/**
 * @route   POST /api/maintenance/cleanup/:type
 * @desc    Cleanup cache, logs, sessions, or temp files
 * @access  Private/SuperAdmin
 */
router.post(
  '/cleanup/:type',
  validate(maintenanceValidation.cleanup),
  maintenanceController.cleanup
);

/**
 * @route   PUT /api/maintenance/mode
 * @desc    Toggle maintenance mode
 * @access  Private/SuperAdmin
 */
router.put(
  '/mode',
  validate(maintenanceValidation.toggleMaintenanceMode),
  maintenanceController.toggleMaintenanceMode
);

module.exports = router;
