const responseTime = require('response-time');
const logger = require('../utils/logger');

    /**
     * Bridge vers le Winston canonique (utils/logger).
     * Conserve le contrat local (operation, number|object) de l’ancien logger parallèle.
     */
function logPerformance(operation, durationOrDetails) {
  if (typeof durationOrDetails === 'number') {
    return logger.logPerformance(operation, durationOrDetails);
  }
  return logger.info('Performance Metric', {
    type: 'performance',
    operation,
    details: durationOrDetails,
  });
}

// Middleware pour mesurer le temps de réponse
const performanceMonitor = responseTime((req, res, time) => {
  const route = `${req.method} ${req.originalUrl}`;
  logPerformance(route, time);

  if (time > 1000) {
    logPerformance(`Performance Alert - Slow Response: ${route}`, time);
  }
});

const memoryMonitor = (req, res, next) => {
  const used = process.memoryUsage();
  const metrics = {
    rss: `${Math.round((used.rss / 1024 / 1024) * 100) / 100} MB`,
    heapTotal: `${Math.round((used.heapTotal / 1024 / 1024) * 100) / 100} MB`,
    heapUsed: `${Math.round((used.heapUsed / 1024 / 1024) * 100) / 100} MB`,
    external: `${Math.round((used.external / 1024 / 1024) * 100) / 100} MB`,
  };

  if (used.heapUsed > 500 * 1024 * 1024) {
    logPerformance('Memory Alert - High Memory Usage', metrics);
  }

  next();
};

const dbErrorMonitor = (err, req, res, next) => {
  if (err.name === 'MongoError' || err.name === 'MongooseError') {
    logPerformance('Database Error', {
      error: err.message,
      code: err.code,
      operation: err.op,
    });
  }
  next(err);
};

let currentRequests = 0;
const requestMonitor = (req, res, next) => {
  currentRequests++;

  if (currentRequests > 100) {
    logPerformance('High Concurrent Requests', currentRequests);
  }

  res.on('finish', () => {
    currentRequests--;
  });

  next();
};

const notFoundMonitor = (req, res, next) => {
  res.on('finish', () => {
    if (res.statusCode === 404) {
      logPerformance('404 Not Found', {
        path: req.originalUrl,
        method: req.method,
        ip: req.ip,
      });
    }
  });
  next();
};

const serverErrorMonitor = (err, req, res, next) => {
  if (res.statusCode >= 500) {
    logPerformance('Server Error', {
      error: err.message,
      path: req.originalUrl,
      method: req.method,
      stack: err.stack,
    });
  }
  next(err);
};

setInterval(() => {
  const metrics = {
    uptime: process.uptime(),
    timestamp: Date.now(),
    activeRequests: currentRequests,
    memory: process.memoryUsage(),
    cpu: process.cpuUsage(),
  };

  logPerformance('System Metrics', metrics);
}, 300000);

module.exports = {
  performanceMonitor,
  memoryMonitor,
  dbErrorMonitor,
  requestMonitor,
  notFoundMonitor,
  serverErrorMonitor,
};
