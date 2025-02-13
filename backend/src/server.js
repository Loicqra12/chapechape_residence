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

const server = http.createServer(app);

// Initialiser le service de socket
SocketService.initialize(server);

const PORT = process.env.PORT || 4000;

server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
