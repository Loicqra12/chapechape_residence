const errorService = require('../../../src/services/error.service');
const ApiError = require('../../../src/utils/apiError');

describe('Error Service (sans domaine Booking legacy)', () => {
  it('logError retourne un détail structuré', () => {
    const error = new ApiError('Données invalides', 400);
    const result = errorService.logError(error, { domain: 'residence', residenceId: 'abc' });
    expect(result.message).toBe('Données invalides');
    expect(result.statusCode).toBe(400);
    expect(result.context.domain).toBe('residence');
  });

  it('ne journalise pas le mot de passe dans le contexte', () => {
    const error = new ApiError('Invalid credentials', 401);
    const result = errorService.logAuthError(error, {
      _id: '507f1f77bcf86cd799439099',
      email: 'test@example.com',
      password: 'secret-should-not-appear',
      role: 'client',
    });
    const dumped = JSON.stringify(result);
    expect(dumped).not.toContain('secret-should-not-appear');
    expect(result.context.user.email).toBe('test@example.com');
  });

  it('ApiError reste une ApiError', () => {
    const apiError = new ApiError('API error', 400);
    expect(apiError).toBeInstanceOf(ApiError);
    expect(apiError.statusCode).toBe(400);
  });
});
