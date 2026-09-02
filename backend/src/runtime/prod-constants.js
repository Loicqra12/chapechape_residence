/**
 * P2-09B1A — constantes prod (pas de secrets).
 * Empreinte attendue : SHA256(host|database).slice(0, 16) de l'URI Mongo du droplet.
 *
 * Baseline prod DigitalOcean (vérifiée sur droplet) :
 *   host: dbaas-db-3738445-26a10019.mongo.ondigitalocean.com
 *   database: admin
 */
const EXPECTED_PROD_MONGO_FINGERPRINT = '4f095ad783737882';

module.exports = { EXPECTED_PROD_MONGO_FINGERPRINT };
