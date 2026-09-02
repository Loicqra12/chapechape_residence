/**
 * Présence de configuration (booléens). Jamais les valeurs des secrets.
 *   node scripts/audit-prod-config.js
 */
require('dotenv').config();
const { configPresence } = require('../src/runtime/config-presence');

console.log(JSON.stringify({
  generatedAt: new Date().toISOString(),
  ...configPresence(),
}, null, 2));
