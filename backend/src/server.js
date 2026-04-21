// IMPORTANT: Sentry instrument.js doit être importé en TOUT PREMIER
require('../instrument');

// New Relic doit être importé en SECOND, avant les autres modules
require('../newrelic');

const dotenv = require('dotenv');
const path = require('path');

// Load env vars BEFORE importing other files
dotenv.config({ path: path.join(__dirname, '../.env') });

const http = require('http');
const mongoose = require('mongoose');
const logger = require('./utils/logger');
const connectDB = require('./config/database');

// Configuration du proxy global AVANT MongoDB (Atlas derrière proxy entreprise)
const httpProxy = process.env.HTTP_PROXY || process.env.http_proxy;
const httpsProxy = process.env.HTTPS_PROXY || process.env.https_proxy;

if (httpProxy || httpsProxy) {
  const globalAgent = require('global-agent');
  globalAgent.bootstrap();

  if (httpProxy) {
    global.GLOBAL_AGENT.HTTP_PROXY = httpProxy;
  }

  if (httpsProxy) {
    global.GLOBAL_AGENT.HTTPS_PROXY = httpsProxy;
  }

  logger.info('Proxy configured', { HTTP_PROXY: httpProxy, HTTPS_PROXY: httpsProxy });
}

/** Référence serveur HTTP (remplie après bootstrap) */
let server;
let isShuttingDown = false;

async function bootstrap() {
  await connectDB();

  // Charger l’app APRÈS MongoDB prêt — sinon Agenda / Mongoose bufferise createIndex et timeout à 10s
  const app = require('./app');
  const SocketService = require('./services/socket.service');
  const { startAgenda } = require('./services/agenda.service');

  server = http.createServer(app);
  SocketService.initialize(server);

  const PORT = process.env.PORT || 4000;

  if (process.env.DISABLE_AGENDA === 'true') {
    logger.warn('Agenda désactivé (DISABLE_AGENDA=true)');
  } else {
    try {
      await startAgenda();
    } catch (err) {
      logger.error('Agenda: échec du démarrage — jobs planifiés indisponibles', err);
    }
  }

  server.listen(PORT, () => {
    logger.info(`Server is running on port ${PORT}`);
  });
}

bootstrap().catch((err) => {
  logger.error('Échec du démarrage du serveur', err);
  process.exit(1);
});

const forceShutdownTimer = () =>
  setTimeout(() => {
    logger.error('Forced shutdown after timeout');
    process.exit(1);
  }, 10000).unref();

const shutdown = (signal) => {
  if (isShuttingDown) return;
  isShuttingDown = true;

  logger.warn(`${signal} received, starting graceful shutdown...`);
  const timer = forceShutdownTimer();

  if (!server) {
    clearTimeout(timer);
    process.exit(0);
    return;
  }

  server.close(async () => {
    try {
      try {
        const { agenda } = require('./services/agenda.service');
        if (agenda && typeof agenda.stop === 'function') {
          await agenda.stop();
          logger.info('Agenda arrêté');
        }
      } catch (agendaErr) {
        logger.warn(`Arrêt Agenda: ${agendaErr.message}`);
      }
      await mongoose.connection.close();
      logger.info('MongoDB connection closed');
      clearTimeout(timer);
      process.exit(0);
    } catch (error) {
      logger.error('Error during shutdown', error);
      clearTimeout(timer);
      process.exit(1);
    }
  });
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

process.on('unhandledRejection', (reason) => {
  logger.error('Unhandled Promise Rejection', reason);
  shutdown('unhandledRejection');
});

process.on('uncaughtException', (error) => {
  logger.error('Uncaught Exception', error);
  shutdown('uncaughtException');
});
