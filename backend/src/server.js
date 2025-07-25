// IMPORTANT: Sentry instrument.js doit être importé en TOUT PREMIER
require('../instrument');

// New Relic doit être importé en SECOND, avant les autres modules
require('../newrelic');

const dotenv = require('dotenv');
const path = require('path');

// Load env vars BEFORE importing other files
dotenv.config({ path: path.join(__dirname, '../.env') });

const connectDB = require('./config/database');
const app = require('./app');
const http = require('http');
const SocketService = require('./services/socket.service');

// Connect to database
connectDB();

// Configuration du proxy global si spécifié dans les variables d'environnement
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
  
  console.log('Proxy configured:', { HTTP_PROXY: httpProxy, HTTPS_PROXY: httpsProxy });
}

const server = http.createServer(app);

// Initialiser le service de socket
SocketService.initialize(server);

const PORT = process.env.PORT || 4000;

server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
