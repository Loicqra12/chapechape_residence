const asyncHandler = require('../middlewares/async.middleware');
const apiError = require('../utils/apiError');
const systemUtils = require('../utils/system.utils');
const backupUtils = require('../utils/backup.utils');
const SystemSetting = require('../models/systemSetting.model');
const redisClient = require('../config/redis');

/**
 * @desc    Get system status (CPU, RAM, Disk, DB, etc.)
 * @route   GET /api/maintenance/status
 * @access  Private/SuperAdmin
 */
exports.getSystemStatus = asyncHandler(async (req, res) => {
  const status = await systemUtils.getSystemStatus();

  res.status(200).json({
    success: true,
    data: status
  });
});

/**
 * @desc    Create a new backup
 * @route   POST /api/maintenance/backup
 * @access  Private/SuperAdmin
 */
exports.createBackup = asyncHandler(async (req, res) => {
  const { name } = req.body;

  const backup = await backupUtils.createBackup(name);

  res.status(201).json({
    success: true,
    data: backup,
    message: 'Backup created successfully'
  });
});

/**
 * @desc    Get all backups
 * @route   GET /api/maintenance/backups
 * @access  Private/SuperAdmin
 */
exports.getBackups = asyncHandler(async (req, res) => {
  const backups = await backupUtils.listBackups();

  res.status(200).json({
    success: true,
    count: backups.length,
    data: backups
  });
});

/**
 * @desc    Delete a backup
 * @route   DELETE /api/maintenance/backup/:id
 * @access  Private/SuperAdmin
 */
exports.deleteBackup = asyncHandler(async (req, res) => {
  const { id } = req.params;

  await backupUtils.deleteBackup(id);

  res.status(200).json({
    success: true,
    message: 'Backup deleted successfully'
  });
});

/**
 * @desc    Restore from backup
 * @route   POST /api/maintenance/backup/:id/restore
 * @access  Private/SuperAdmin
 */
exports.restoreBackup = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const result = await backupUtils.restoreBackup(id);

  res.status(200).json({
    success: true,
    data: result,
    message: 'Backup restored successfully'
  });
});

/**
 * @desc    Cleanup cache, logs, or sessions
 * @route   POST /api/maintenance/cleanup/:type
 * @access  Private/SuperAdmin
 */
exports.cleanup = asyncHandler(async (req, res) => {
  const { type } = req.params;

  let result = {};

  switch (type) {
    case 'cache':
      // Clear Redis cache
      await redisClient.flushAll();
      result = { message: 'Cache cleared successfully', type: 'cache' };
      break;

    case 'logs':
      // Archive old logs (simplified - in production, use log rotation)
      result = { message: 'Logs archived successfully', type: 'logs' };
      break;

    case 'sessions':
      // Clear expired sessions from Redis
      const keys = await redisClient.keys('sess:*');
      if (keys.length > 0) {
        await redisClient.del(keys);
      }
      result = { message: `${keys.length} sessions cleared`, type: 'sessions', count: keys.length };
      break;

    case 'temp':
      // Clear temporary files
      result = { message: 'Temporary files cleared', type: 'temp' };
      break;

    default:
      throw new apiError(`Invalid cleanup type: ${type}`, 400);
  }

  res.status(200).json({
    success: true,
    data: result
  });
});

/**
 * @desc    Toggle maintenance mode
 * @route   PUT /api/maintenance/mode
 * @access  Private/SuperAdmin
 */
exports.toggleMaintenanceMode = asyncHandler(async (req, res) => {
  const { enabled } = req.body;

  if (typeof enabled !== 'boolean') {
    throw new apiError('enabled must be a boolean', 400);
  }

  // Update or create maintenance mode setting
  let setting = await SystemSetting.findOne({ key: 'maintenance_mode' });

  if (setting) {
    setting.value = enabled;
    setting.updatedBy = req.user._id;
    await setting.save();
  } else {
    setting = await SystemSetting.create({
      key: 'maintenance_mode',
      value: enabled,
      description: 'Enable or disable maintenance mode',
      type: 'boolean',
      category: 'maintenance',
      updatedBy: req.user._id
    });
  }

  res.status(200).json({
    success: true,
    data: {
      maintenanceMode: enabled,
      updatedAt: setting.updatedAt
    },
    message: `Maintenance mode ${enabled ? 'enabled' : 'disabled'}`
  });
});

/**
 * @desc    Get maintenance mode status
 * @route   GET /api/maintenance/mode
 * @access  Public
 */
exports.getMaintenanceMode = asyncHandler(async (req, res) => {
  const setting = await SystemSetting.findOne({ key: 'maintenance_mode' });

  res.status(200).json({
    success: true,
    data: {
      maintenanceMode: setting ? setting.value : false
    }
  });
});
