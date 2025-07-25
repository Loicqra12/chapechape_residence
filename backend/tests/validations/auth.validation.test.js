const Joi = require('joi');
// Importer les schémas de validation correctement
const {
  login,
  register,
  googleAuth,
  facebookAuth,
  requestVerificationCode,
  verifyCode
} = require('../../src/validations/auth.validation');

// Extraire les schémas Joi du sous-objet body
const loginSchema = login.body;
const registerSchema = register.body;
const googleAuthSchema = googleAuth.body;
const facebookAuthSchema = facebookAuth.body;
const requestVerificationCodeSchema = requestVerificationCode.body;
const verifyCodeSchema = verifyCode.body;

// Utiliser Jest au lieu de Chai

describe('Schémas de validation d\'authentification', () => {
  
  describe('loginSchema', () => {
    const validData = { email: 'user@example.com', password: 'Password123!' };
    
    const invalidData = {
      'email manquant': { password: 'Password123!' },
      'email invalide': { email: 'not-an-email', password: 'Password123!' },
      'mot de passe manquant': { email: 'user@example.com' },
      'mot de passe trop court': { email: 'user@example.com', password: 'Pass1!' }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = loginSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = loginSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });

  describe('registerSchema', () => {
    const validData = {
      name: 'John Doe',
      email: 'john@example.com',
      password: 'SecurePass123!',
      phoneNumber: '+33612345678',
      role: 'user'
    };
    
    const invalidData = {
      'email invalide': { ...validData, email: 'invalid-email' },
      'mot de passe trop court': { ...validData, password: 'short' },
      'numéro de téléphone invalide': { ...validData, phoneNumber: '123' },
      'rôle invalide': { ...validData, role: 'superuser' }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = registerSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = registerSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });

  describe('googleAuthSchema', () => {
    const validData = {
      idToken: 'valid-google-token-12345'
    };
    
    const invalidData = {
      'token manquant': {},
      'token vide': { idToken: '' }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = googleAuthSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = googleAuthSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });

  describe('facebookAuthSchema', () => {
    const validData = {
      accessToken: 'valid-facebook-token-12345'
    };
    
    const invalidData = {
      'token manquant': {},
      'token vide': { accessToken: '' }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = facebookAuthSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = facebookAuthSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });

  describe('requestVerificationCodeSchema', () => {
    const validData = {
      phoneNumber: '+33612345678'
    };
    
    const invalidData = {
      'numéro manquant': {},
      'numéro invalide': { phoneNumber: '123' },
      'numéro mal formaté': { phoneNumber: '0612345678' }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = requestVerificationCodeSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = requestVerificationCodeSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });

  describe('verifyCodeSchema', () => {
    const validData = {
      phoneNumber: '+33612345678',
      code: '123456'
    };
    
    const invalidData = {
      'numéro manquant': { code: '123456' },
      'numéro invalide': { phoneNumber: '123', code: '123456' },
      'code manquant': { phoneNumber: '+33612345678' },
      'code invalide': { phoneNumber: '+33612345678', code: '12' }
    };
    
    it('devrait valider les données correctes', () => {
      const { error } = verifyCodeSchema.validate(validData);
      expect(error).toBe(undefined);
    });

    Object.keys(invalidData).forEach(key => {
      it(`devrait rejeter les données avec ${key} invalide`, () => {
        const { error } = verifyCodeSchema.validate(invalidData[key]);
        expect(error).not.toBe(undefined);
      });
    });
  });
});
