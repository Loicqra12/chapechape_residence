const {
  login,
  register,
  googleAuth,
  facebookAuth,
  requestVerificationCode,
  verifyCode,
} = require('../../src/validations/auth.validation');

const loginSchema = login.body;
const registerSchema = register.body;
const googleAuthSchema = googleAuth.body;
const facebookAuthSchema = facebookAuth.body;
const requestVerificationCodeSchema = requestVerificationCode.body;
const verifyCodeSchema = verifyCode.body;

describe('Schémas de validation d\'authentification (contrats actuels)', () => {
  describe('loginSchema', () => {
    it('accepte email ou identifiant téléphone (pas un format email strict)', () => {
      expect(loginSchema.validate({ email: 'user@example.com', password: 'x' }).error).toBeUndefined();
      expect(loginSchema.validate({ email: '0700000000', password: 'x' }).error).toBeUndefined();
    });

    it('rejette email ou mot de passe manquant', () => {
      expect(loginSchema.validate({ password: 'x' }).error).toBeDefined();
      expect(loginSchema.validate({ email: 'user@example.com' }).error).toBeDefined();
    });
  });

  describe('registerSchema', () => {
    const valid = {
      email: 'john@example.com',
      password: 'SecurePass123!',
      firstName: 'John',
      lastName: 'Doe',
      phoneNumber: '+2250700000001',
    };

    it('valide un payload canonique (sans rôle — forcé client côté API)', () => {
      expect(registerSchema.validate(valid).error).toBeUndefined();
    });

    it('rejette email invalide, mot de passe trop court, téléphone invalide', () => {
      expect(registerSchema.validate({ ...valid, email: 'invalid-email' }).error).toBeDefined();
      expect(registerSchema.validate({ ...valid, password: 'short' }).error).toBeDefined();
      expect(registerSchema.validate({ ...valid, phoneNumber: 'abc' }).error).toBeDefined();
    });

    it('ignore / strip role (clé inconnue) selon Joi — le contrôleur force client', () => {
      const { error, value } = registerSchema.validate({ ...valid, role: 'superadmin' }, { stripUnknown: true });
      expect(error).toBeUndefined();
      expect(value.role).toBeUndefined();
    });
  });

  describe('googleAuthSchema / facebookAuthSchema', () => {
    it('exige un token', () => {
      expect(googleAuthSchema.validate({ idToken: 'tok' }).error).toBeUndefined();
      expect(googleAuthSchema.validate({}).error).toBeDefined();
      expect(facebookAuthSchema.validate({ accessToken: 'tok' }).error).toBeUndefined();
      expect(facebookAuthSchema.validate({}).error).toBeDefined();
    });
  });

  describe('OTP schemas', () => {
    it('requestVerificationCode accepte E.164 et formats locaux larges', () => {
      expect(requestVerificationCodeSchema.validate({ phoneNumber: '+2250700000001' }).error).toBeUndefined();
      expect(requestVerificationCodeSchema.validate({ phoneNumber: '0700000001' }).error).toBeUndefined();
      expect(requestVerificationCodeSchema.validate({}).error).toBeDefined();
      expect(requestVerificationCodeSchema.validate({ phoneNumber: '12' }).error).toBeDefined();
    });

    it('verifyCode exige téléphone + code', () => {
      expect(verifyCodeSchema.validate({ phoneNumber: '+2250700000001', code: '123456' }).error).toBeUndefined();
      expect(verifyCodeSchema.validate({ code: '123456' }).error).toBeDefined();
      expect(verifyCodeSchema.validate({ phoneNumber: '+2250700000001' }).error).toBeDefined();
    });
  });
});
