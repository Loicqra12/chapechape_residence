/**
 * P2-01 — constantes prod (pas de secrets).
 * Empreinte attendue : hash(host SRV | database) de l'URI Mongo du droplet.
 */
const EXPECTED_PROD_MONGO_FINGERPRINT = 'efebb871c934cf3c';

module.exports = { EXPECTED_PROD_MONGO_FINGERPRINT };
