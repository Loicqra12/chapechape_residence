/**
 * Tests d'intégration - Sécurité Backend
 * Execute: npm test
 */

const request = require('supertest');
const app = require('../../src/app');
const crypto = require('crypto');

// Couleurs pour console
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  reset: '\x1b[0m',
  blue: '\x1b[34m'
};

const log = {
  success: (msg) => console.log(`${colors.green}✅ ${msg}${colors.reset}`),
  error: (msg) => console.log(`${colors.red}❌ ${msg}${colors.reset}`),
  info: (msg) => console.log(`${colors.blue}ℹ️  ${msg}${colors.reset}`),
  test: (msg) => console.log(`${colors.yellow}🧪 ${msg}${colors.reset}`)
};

// Compteurs
let totalTests = 0;
let passedTests = 0;
let failedTests = 0;

/**
 * Helper pour exécuter un test
 */
async function runTest(name, testFn) {
  totalTests++;
  log.test(name);
  try {
    await testFn();
    passedTests++;
    log.success(`PASS: ${name}\n`);
  } catch (error) {
    failedTests++;
    log.error(`FAIL: ${name}`);
    console.error(`  Error: ${error.message}\n`);
  }
}

/**
 * Helper pour générer signature HMAC
 */
function generateHMAC(apiKey, path, timestamp) {
  const secret = process.env.MOBILE_APP_SECRET || 'test-secret-key';
  const payload = `${apiKey}:${path}:${timestamp}`;
  return crypto.createHmac('sha256', secret).update(payload).digest('hex');
}

/**
 * TEST SUITE 1: Rate Limiting
 */
async function testRateLimiting() {
  log.info('\n📊 TEST SUITE 1: Rate Limiting\n');

  // Test 1.1: Global rate limit
  await runTest('Global rate limit (100 req/15min)', async () => {
    const response = await request(app)
      .get('/api/residences')
      .expect(200);

    if (!response.headers['ratelimit-limit']) {
      throw new Error('RateLimit headers missing');
    }
  });

  // Test 1.2: Auth rate limit strict
  await runTest('Auth rate limit (5 échecs/15min)', async () => {
    const responses = [];

    // Faire 6 tentatives échouées
    for (let i = 0; i < 6; i++) {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: 'test@test.com', password: 'wrong' });
      responses.push(res.statusCode);
    }

    // 6ème tentative devrait être bloquée (429)
    if (responses[5] !== 429) {
      throw new Error(`Expected 429, got ${responses[5]}`);
    }
  });

  // Test 1.3: Rate limit headers présents
  await runTest('Rate limit headers correctement définis', async () => {
    const response = await request(app)
      .get('/api/residences');

    const hasLimit = response.headers['ratelimit-limit'];
    const hasRemaining = response.headers['ratelimit-remaining'];
    const hasReset = response.headers['ratelimit-reset'];

    if (!hasLimit || !hasRemaining || !hasReset) {
      throw new Error('Missing rate limit headers');
    }
  });
}

/**
 * TEST SUITE 2: CSRF Protection
 */
async function testCSRFProtection() {
  log.info('\n📊 TEST SUITE 2: CSRF Protection\n');

  // Test 2.1: CSRF requis pour routes sensibles
  await runTest('CSRF token requis (sans mobile auth)', async () => {
    const response = await request(app)
      .post('/api/users/profile')
      .send({ test: 'data' });

    // Devrait retourner 403 (CSRF manquant) ou 401 (auth) — pas 200
    if (![401, 403].includes(response.statusCode)) {
      throw new Error(`Expected 401/403, got ${response.statusCode}`);
    }
  });

  // Test 2.2: Bypass Content-Type supprimé
  await runTest('Bypass Content-Type supprimé (vulnérabilité corrigée)', async () => {
    const response = await request(app)
      .post('/api/users/profile')
      .set('Content-Type', 'application/json')
      .send({ test: 'data' });

    // Devrait toujours retourner 401/403 (bypass supprimé)
    if (![401, 403].includes(response.statusCode)) {
      throw new Error(`Content-Type bypass still active! Got ${response.statusCode}`);
    }
  });

  // Test 2.3: Mobile auth HMAC requis
  await runTest('Mobile auth HMAC accepté', async () => {
    const apiKey = 'chapechape-client-test';
    const path = '/api/auth/login';
    const timestamp = Date.now().toString();
    const signature = generateHMAC(apiKey, path, timestamp);

    const response = await request(app)
      .post(path)
      .set('X-API-Key', apiKey)
      .set('X-Mobile-Signature', signature)
      .set('X-Timestamp', timestamp)
      .send({ email: 'test@test.com', password: 'test123' });

    // Ne devrait pas retourner 403 (HMAC valide)
    if (response.statusCode === 403) {
      throw new Error('HMAC signature rejected');
    }
  });

  // Test 2.4: Signature expirée rejetée
  await runTest('Signature HMAC expirée rejetée (> 5min)', async () => {
    const apiKey = 'chapechape-client-test';
    const path = '/api/auth/login';
    const oldTimestamp = (Date.now() - 6 * 60 * 1000).toString(); // 6min ago
    const signature = generateHMAC(apiKey, path, oldTimestamp);

    const response = await request(app)
      .post(path)
      .set('X-API-Key', apiKey)
      .set('X-Mobile-Signature', signature)
      .set('X-Timestamp', oldTimestamp)
      .send({ email: 'test@test.com', password: 'test123' });

    // Devrait retourner 401 (signature expirée)
    if (response.statusCode !== 401) {
      throw new Error(`Expected 401, got ${response.statusCode}`);
    }
  });
}

/**
 * TEST SUITE 3: Error Handling
 */
async function testErrorHandling() {
  log.info('\n📊 TEST SUITE 3: Error Handling\n');

  // Test 3.1: Pas de stack trace en réponse
  await runTest('Stack trace supprimée des réponses', async () => {
    const response = await request(app)
      .get('/api/nonexistent-route')
      .expect(404);

    const body = JSON.stringify(response.body);
    if (body.includes('at ') || body.includes('.js:')) {
      throw new Error('Stack trace exposed in response');
    }
  });

  // Test 3.2: Messages d'erreur génériques (prod)
  await runTest('Messages d\'erreur génériques en production', async () => {
    // Simuler production
    const oldEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'production';

    const response = await request(app)
      .get('/api/trigger-error'); // Route qui génère erreur

    process.env.NODE_ENV = oldEnv;

    // Message ne doit pas contenir détails techniques
    const message = response.body.message || '';
    if (message.includes('localhost') || message.includes('mongodb://')) {
      throw new Error('Technical details exposed in error message');
    }
  });

  // Test 3.3: Codes d'erreur structurés
  await runTest('Codes d\'erreur structurés présents', async () => {
    const response = await request(app)
      .post('/api/auth/login')
      .send({ email: 'invalid', password: '123' });

    if (!response.body.errorCode) {
      throw new Error('Error code missing in response');
    }

    // Format: DOMAINE_ACTION_RAISON
    const codeFormat = /^[A-Z]+_[A-Z_]+$/;
    if (!codeFormat.test(response.body.errorCode)) {
      throw new Error('Invalid error code format');
    }
  });
}

/**
 * TEST SUITE 4: Timing Attack Prevention
 */
async function testTimingAttackPrevention() {
  log.info('\n📊 TEST SUITE 4: Timing Attack Prevention\n');

  // Test 4.1: Temps de réponse similaire
  await runTest('Temps réponse constant (user existe vs non)', async () => {
    const times = [];

    // Test avec utilisateur qui existe
    const start1 = Date.now();
    await request(app)
      .post('/api/auth/login')
      .send({ email: 'existing@user.com', password: 'wrong' });
    times.push(Date.now() - start1);

    // Test avec utilisateur qui n'existe pas
    const start2 = Date.now();
    await request(app)
      .post('/api/auth/login')
      .send({ email: 'notexist@user.com', password: 'wrong' });
    times.push(Date.now() - start2);

    // Différence devrait être < 100ms (avec délai aléatoire)
    const diff = Math.abs(times[0] - times[1]);
    if (diff > 100) {
      throw new Error(`Timing difference too large: ${diff}ms`);
    }
  });

  // Test 4.2: Délai aléatoire appliqué
  await runTest('Délai aléatoire appliqué (50-150ms)', async () => {
    const start = Date.now();
    await request(app)
      .post('/api/auth/login')
      .send({ email: 'test@test.com', password: 'wrong' });
    const duration = Date.now() - start;

    // Devrait prendre au moins 50ms (délai minimum)
    if (duration < 50) {
      throw new Error(`No random delay applied: ${duration}ms`);
    }
  });
}

/**
 * TEST SUITE 5: Input Validation
 */
async function testInputValidation() {
  log.info('\n📊 TEST SUITE 5: Input Validation\n');

  // Test 5.1: Email validation robuste
  await runTest('Email validation accepte TLDs modernes', async () => {
    const validEmails = [
      'test@example.technology',
      'user@domain.museum',
      'contact@site.info'
    ];

    for (const email of validEmails) {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email,
          password: 'Test123!',
          firstName: 'Test',
          lastName: 'User'
        });

      // Ne devrait pas retourner erreur validation email
      if (response.body.message?.includes('email valide')) {
        throw new Error(`Valid email rejected: ${email}`);
      }
    }
  });

  // Test 5.2: Email normalisation
  await runTest('Email normalisation (lowercase, trim)', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        email: '  TEST@Example.COM  ',
        password: 'Test123!',
        firstName: 'Test',
        lastName: 'User'
      });

    // Email devrait être normalisé en lowercase
    if (response.body.user?.email !== 'test@example.com') {
      throw new Error('Email not normalized');
    }
  });

  // Test 5.3: Emails invalides rejetés
  await runTest('Emails invalides rejetés', async () => {
    const invalidEmails = [
      'notanemail',
      '@nodomain.com',
      'missing@.com',
      'spaces in@email.com'
    ];

    for (const email of invalidEmails) {
      const response = await request(app)
        .post('/api/auth/register')
        .send({
          email,
          password: 'Test123!',
          firstName: 'Test',
          lastName: 'User'
        });

      // Devrait retourner erreur validation
      if (response.statusCode !== 400) {
        throw new Error(`Invalid email accepted: ${email}`);
      }
    }
  });
}

/**
 * MAIN TEST RUNNER
 */
async function runAllTests() {
  console.log('\n' + '='.repeat(60));
  console.log('🔒 TESTS D\'INTÉGRATION SÉCURITÉ BACKEND');
  console.log('='.repeat(60) + '\n');

  try {
    await testRateLimiting();
    await testCSRFProtection();
    await testErrorHandling();
    await testTimingAttackPrevention();
    await testInputValidation();
  } catch (error) {
    log.error(`Fatal error: ${error.message}`);
  }

  // Résumé
  console.log('\n' + '='.repeat(60));
  console.log('📊 RÉSUMÉ DES TESTS');
  console.log('='.repeat(60));
  console.log(`Total: ${totalTests}`);
  console.log(`${colors.green}Passés: ${passedTests}${colors.reset}`);
  console.log(`${colors.red}Échoués: ${failedTests}${colors.reset}`);
  console.log(`Taux de réussite: ${((passedTests / totalTests) * 100).toFixed(1)}%`);
  console.log('='.repeat(60) + '\n');

  // Exit code
  process.exit(failedTests > 0 ? 1 : 0);
}

// Exécuter si appelé directement
if (require.main === module) {
  runAllTests();
}

module.exports = { runAllTests };


