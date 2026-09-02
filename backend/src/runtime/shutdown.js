const mongoose = require('mongoose');
const logger = require('../utils/logger');
const readiness = require('./readiness');

const DEFAULT_TIMEOUT_MS = 25000;

async function closeQuiet(label, fn) {
  try {
    await fn();
    logger.info(`${label} arrêté`);
  } catch (err) {
    logger.warn(`Arrêt ${label}: ${err.message}`);
  }
}

/**
 * HTTP → Socket.IO → Agenda → Redis → Mongo.
 * Ne laisse pas une transaction / job Agenda dans un état ambigu si possible.
 */
function createShutdown({ server, getServer, timeoutMs = DEFAULT_TIMEOUT_MS } = {}) {
  let started = false;
  return function shutdown(signal) {
    if (started) return;
    started = true;
    readiness.beginShutdown();
    logger.warn(`${signal} received, starting graceful shutdown...`);

    const timer = setTimeout(() => {
      logger.error('Forced shutdown after timeout');
      process.exit(1);
    }, timeoutMs);
    timer.unref();

    const httpServer = typeof getServer === 'function' ? getServer() : server;

    const finish = async () => {
      try {
        try {
          const SocketService = require('../services/socket.service');
          if (typeof SocketService.close === 'function') {
            await SocketService.close();
          }
        } catch (err) {
          logger.warn(`Arrêt Socket.IO: ${err.message}`);
        }

        await closeQuiet('Agenda', async () => {
          const { agenda } = require('../services/agenda.service');
          if (agenda && typeof agenda.stop === 'function') {
            await agenda.stop();
          }
        });

        await closeQuiet('Redis', async () => {
          const redis = require('../config/redis');
          const client = redis.getClient ? redis.getClient() : redis;
          if (client && typeof client.quit === 'function' && process.env.NODE_ENV === 'production') {
            await client.quit();
          }
        });

        if (mongoose.connection.readyState !== 0) {
          await mongoose.connection.close();
          logger.info('MongoDB connection closed');
        }
        clearTimeout(timer);
        process.exit(0);
      } catch (error) {
        logger.error('Error during shutdown', error);
        clearTimeout(timer);
        process.exit(1);
      }
    };

    if (!httpServer) {
      finish();
      return;
    }

    httpServer.close(() => {
      finish();
    });
  };
}

module.exports = { createShutdown, DEFAULT_TIMEOUT_MS };
