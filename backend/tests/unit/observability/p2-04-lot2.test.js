const fs = require('fs');
const path = require('path');
const ApiError = require('../../../src/utils/apiError');
const logger = require('../../../src/utils/logger');
const { logLevelForError, shouldCaptureSentry } = require('../../../src/observability/http-error-policy');
const { attachAgendaEnvelope } = require('../../../src/observability/agenda-envelope');

describe('P2-04 lot 2 — runtime log hygiene', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('conflit métier 409 ≠ logger.error / Sentry', () => {
    const err = ApiError.conflict('Déjà réservé', 'INVENTORY_ALREADY_RESERVED');
    expect(logLevelForError(err)).toBe('info');
    expect(shouldCaptureSentry(err)).toBe(false);
  });

  it('erreur technique 500 = logger.error + Sentry capturable', () => {
    const err = new Error('Mongo timeout');
    expect(logLevelForError(err)).toBe('error');
    expect(shouldCaptureSentry(err)).toBe(true);
  });

  it('chemins migrés : pas de console.* Auth Google / Wave / CSRF custom / Cloudinary', () => {
    const files = [
      'src/controllers/auth/google-auth.controller.js',
      'src/services/wave.service.js',
      'src/services/wave-payout.service.js',
      'src/services/payment.service.js',
      'src/middlewares/csrf-custom.middleware.js',
      'src/middlewares/csrf.middleware.js',
      'src/config/cloudinary.js',
    ];
    for (const rel of files) {
      const src = fs.readFileSync(path.join(__dirname, '../../..', rel), 'utf8');
      expect(src).not.toMatch(/console\.(log|info|warn|error)/);
    }
  });

  it('webhook Wave ne dump plus le payload brut (PII/secrets)', () => {
    const src = fs.readFileSync(
      path.join(__dirname, '../../../src/services/wave.service.js'),
      'utf8'
    );
    expect(src).toMatch(/WAVE_WEBHOOK_RECEIVED/);
    expect(src).not.toMatch(/logger\.info\('Traitement webhook Wave:', webhookData\)/);
  });

  it('CSRF legacy ne logge plus headers/body complets', () => {
    const src = fs.readFileSync(
      path.join(__dirname, '../../../src/middlewares/csrf.middleware.js'),
      'utf8'
    );
    expect(src).toMatch(/CSRF_ATTACK_DETECTED/);
    expect(src).not.toMatch(/headers:\s*req\.headers/);
    expect(src).not.toMatch(/body:\s*req\.body/);
  });

  it('Agenda envelope reste unique ; prose « Exécution job payout » retirée', () => {
    const envelope = fs.readFileSync(
      path.join(__dirname, '../../../src/observability/agenda-envelope.js'),
      'utf8'
    );
    const agenda = fs.readFileSync(
      path.join(__dirname, '../../../src/services/agenda.service.js'),
      'utf8'
    );
    expect(envelope).toMatch(/attachAgendaEnvelope/);
    expect(agenda).toMatch(/attachAgendaEnvelope\(realAgenda\)/);
    expect(agenda).not.toMatch(/Exécution job payout/);
    expect(attachAgendaEnvelope).toEqual(expect.any(Function));
  });

  it('google-auth controller utilise logLevelForError (4xx ≠ error forcé)', () => {
    const src = fs.readFileSync(
      path.join(__dirname, '../../../src/controllers/auth/google-auth.controller.js'),
      'utf8'
    );
    expect(src).toMatch(/logLevelForError/);
    expect(src).toMatch(/GOOGLE_AUTH_CONTROLLER_FAILED/);
  });

  it('sanitizer Winston toujours présent ; pas de logger V2', () => {
    expect(logger.maskEmail('admin@example.com')).toBe('ad***@example.com');
    expect(logger.sanitizeObject({ password: 'x', otp: '1' })).toEqual({
      password: '***MASKED***',
      otp: '***MASKED***',
    });
    const srcRoot = path.join(__dirname, '../../../src');
    const banned = [/loggerV2/, /secureLogger/, /observabilityService/, /errorPolicyV2/, /agendaLogger2/];
    const walk = (dir) => {
      for (const name of fs.readdirSync(dir)) {
        const full = path.join(dir, name);
        if (fs.statSync(full).isDirectory()) walk(full);
        else if (full.endsWith('.js')) {
          const text = fs.readFileSync(full, 'utf8');
          for (const re of banned) expect(text).not.toMatch(re);
        }
      }
    };
    walk(srcRoot);
  });
});
