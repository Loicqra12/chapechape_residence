const mongoose = require('mongoose');
const LoginAttempt = require('../../../src/models/loginAttempt.model');

describe('LoginAttempt Model Test', () => {
    beforeAll(async () => {
        // La connexion est déjà gérée dans setup.js
    });

    afterEach(async () => {
        await LoginAttempt.deleteMany({});
    });

    afterAll(async () => {
        // Le nettoyage est géré dans setup.js
    });

    it('should create & save login attempt successfully', async () => {
        const validLoginAttempt = new LoginAttempt({
            email: 'test@example.com',
            ip: '192.168.1.1',
            success: false,
            attempts: 1
        });

        const savedLoginAttempt = await validLoginAttempt.save();
        
        expect(savedLoginAttempt._id).toBeDefined();
        expect(savedLoginAttempt.email).toBe('test@example.com');
        expect(savedLoginAttempt.ip).toBe('192.168.1.1');
        expect(savedLoginAttempt.success).toBe(false);
        expect(savedLoginAttempt.attempts).toBe(1);
    });

    it('should fail to save login attempt without required fields', async () => {
        const loginAttemptWithoutRequired = new LoginAttempt({});

        let err;
        try {
            await loginAttemptWithoutRequired.save();
        } catch (error) {
            err = error;
        }

        expect(err).toBeDefined();
        expect(err.errors.email).toBeDefined();
        expect(err.errors.ip).toBeDefined();
    });

    it('should convert email to lowercase', async () => {
        const loginAttemptWithUppercase = new LoginAttempt({
            email: 'TEST@EXAMPLE.COM',
            ip: '192.168.1.1',
            success: false,
            attempts: 1
        });

        const savedLoginAttempt = await loginAttemptWithUppercase.save();
        expect(savedLoginAttempt.email).toBe('test@example.com');
    });

    it('should increment attempts counter', async () => {
        const loginAttempt = await LoginAttempt.create({
            email: 'test@example.com',
            ip: '192.168.1.1',
            success: false,
            attempts: 1
        });

        loginAttempt.attempts += 1;
        const updatedLoginAttempt = await loginAttempt.save();

        expect(updatedLoginAttempt.attempts).toBe(2);
    });

    it('should handle blocking until specific date', async () => {
        const blockDate = new Date();
        blockDate.setHours(blockDate.getHours() + 1);

        const loginAttempt = await LoginAttempt.create({
            email: 'test@example.com',
            ip: '192.168.1.1',
            success: false,
            attempts: 5,
            blockedUntil: blockDate
        });

        expect(loginAttempt.blockedUntil).toBeDefined();
        expect(loginAttempt.blockedUntil.getTime()).toBe(blockDate.getTime());
    });
});
