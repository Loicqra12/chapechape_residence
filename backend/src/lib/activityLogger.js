const ActivityLog = require('../models/activityLog.model');

/**
 * Create an activity log entry
 * @param {Object} logData - Activity log data
 * @param {string} logData.user - User ID
 * @param {string} logData.action - Action performed
 * @param {string} logData.target - Target of the action (e.g., 'role', 'permission')
 * @param {string} logData.description - Description of the activity
 * @param {Object} req - Express request object (optional)
 * @returns {Promise<ActivityLog>} Created activity log
 */
exports.createActivityLog = async (logData, req = null) => {
  try {
    // Map target to module
    const targetToModule = {
      'role': 'security',
      'permission': 'security',
      'user': 'profile',
      'admin': 'profile',
      'residence': 'residence',
      'reservation': 'reservation',
      'payment': 'payment'
    };

    // Map action to standard enum values
    const actionMap = {
      'create': 'profile_update',
      'update': 'profile_update',
      'delete': 'profile_update'
    };

    const activityData = {
      user: logData.user,
      action: actionMap[logData.action] || logData.action || 'profile_update',
      module: targetToModule[logData.target] || 'security',
      description: logData.description || `${logData.action} ${logData.target}`,
      ipAddress: req?.ip || req?.headers?.['x-forwarded-for'] || req?.connection?.remoteAddress || '127.0.0.1',
      userAgent: req?.headers?.['user-agent'] || 'Unknown',
      status: logData.status || 'success',
      severity: logData.severity || 'low',
      metadata: logData.metadata || {}
    };

    const log = new ActivityLog(activityData);
    await log.save();

    return log;
  } catch (error) {
    // Log error but don't throw to avoid breaking the main flow
    console.error('Error creating activity log:', error.message);
    return null;
  }
};

/**
 * Get activity logs with filtering and pagination
 * @param {Object} filters - Filter options
 * @param {Object} pagination - Pagination options
 * @returns {Promise<Object>} Activity logs and pagination info
 */
exports.getActivityLogs = async (filters = {}, pagination = {}) => {
  try {
    const { page = 1, limit = 50 } = pagination;
    const skip = (page - 1) * limit;

    const query = {};

    if (filters.user) query.user = filters.user;
    if (filters.action) query.action = filters.action;
    if (filters.module) query.module = filters.module;
    if (filters.startDate || filters.endDate) {
      query.createdAt = {};
      if (filters.startDate) query.createdAt.$gte = new Date(filters.startDate);
      if (filters.endDate) query.createdAt.$lte = new Date(filters.endDate);
    }

    const [logs, total] = await Promise.all([
      ActivityLog.find(query)
        .populate('user', 'firstName lastName email')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      ActivityLog.countDocuments(query)
    ]);

    return {
      data: logs,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    };
  } catch (error) {
    console.error('Error fetching activity logs:', error.message);
    throw error;
  }
};
