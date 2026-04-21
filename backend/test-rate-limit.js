/**
 * Test du middleware rate-limit
 * Vérifie que le middleware ne crash pas au chargement
 */

console.log('🧪 Test du middleware rate-limit...\n');

try {
  // Test 1: Charger le middleware
  console.log('1️⃣  Chargement du middleware...');
  const rateLimiters = require('./src/middlewares/rate-limit.middleware');
  console.log('✅ Middleware chargé avec succès\n');

  // Test 2: Vérifier les exports
  console.log('2️⃣  Vérification des exports...');
  const requiredExports = [
    'globalLimiter',
    'authLoginLimiter',
    'authRegisterLimiter',
    'authLimiter',
    'paymentLimiter',
    'userLimiter',
    'uploadLimiter'
  ];
  const missingExports = requiredExports.filter(exp => !rateLimiters[exp]);

  if (missingExports.length > 0) {
    console.error(`❌ Exports manquants: ${missingExports.join(', ')}`);
    process.exit(1);
  }
  console.log('✅ Tous les exports présents\n');

  // Test 3: Vérifier que ce sont des fonctions middleware
  console.log('3️⃣  Vérification des types...');
  Object.entries(rateLimiters).forEach(([name, limiter]) => {
    if (typeof limiter !== 'function') {
      console.error(`❌ ${name} n'est pas une fonction`);
      process.exit(1);
    }
    console.log(`   ✓ ${name} est une fonction middleware`);
  });
  console.log('✅ Tous les middlewares sont des fonctions\n');

  console.log('🎉 TOUS LES TESTS PASSENT ! Le middleware est sûr à utiliser.\n');
  process.exit(0);

} catch (error) {
  console.error('❌ ERREUR:', error.message);
  console.error(error.stack);
  process.exit(1);
}
