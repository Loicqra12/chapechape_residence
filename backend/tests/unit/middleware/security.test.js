const { securityMiddleware, fileSecurityMiddleware } = require('../../../src/middlewares/security');
const logger = require('../../../src/utils/logger');

jest.mock('../../../src/utils/logger', () => ({
    warn: jest.fn(),
    error: jest.fn(),
    info: jest.fn()
}));

describe('Security Middleware', () => {
    let req;
    let res;
    let next;

    beforeEach(() => {
        req = {
            query: {},
            body: {},
            files: null,
            ip: '127.0.0.1'
        };
        res = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn(),
            setHeader: jest.fn()
        };
        next = jest.fn();
        jest.clearAllMocks();
    });

    describe('Input Validation', () => {
        const inputValidation = securityMiddleware.find(m => m.name === 'inputValidation');

        it('should trim string values in query parameters', () => {
            req.query = { name: ' test ', age: 25 };
            inputValidation(req, res, next);
            expect(req.query.name).toBe('test');
            expect(req.query.age).toBe(25);
            expect(next).toHaveBeenCalled();
        });

        it('should trim string values in request body', () => {
            req.body = { email: ' test@example.com ', count: 10 };
            inputValidation(req, res, next);
            expect(req.body.email).toBe('test@example.com');
            expect(req.body.count).toBe(10);
            expect(next).toHaveBeenCalled();
        });
    });

    describe('File Security Middleware', () => {
        it('should allow valid files', () => {
            req.files = [{
                originalname: 'test.jpg',
                size: 1024 * 1024 // 1MB
            }];
            fileSecurityMiddleware(req, res, next);
            expect(next).toHaveBeenCalled();
            expect(res.status).not.toHaveBeenCalled();
        });

        it('should reject files with invalid extensions', () => {
            req.files = [{
                originalname: 'test.exe',
                size: 1024 * 1024
            }];
            fileSecurityMiddleware(req, res, next);
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                success: false,
                message: expect.stringContaining('Extension de fichier non autorisée')
            });
            expect(next).not.toHaveBeenCalled();
        });

        it('should reject files that are too large', () => {
            req.files = [{
                originalname: 'test.jpg',
                size: 10 * 1024 * 1024 // 10MB
            }];
            fileSecurityMiddleware(req, res, next);
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                success: false,
                message: 'Fichier trop volumineux'
            });
            expect(next).not.toHaveBeenCalled();
        });
    });

    describe('Security Headers', () => {
        const securityHeadersMiddleware = securityMiddleware.find(m => m.name === 'securityHeaders');

        it('should set security headers', () => {
            securityHeadersMiddleware(req, res, next);
            expect(res.setHeader).toHaveBeenCalledWith('X-Content-Type-Options', 'nosniff');
            expect(res.setHeader).toHaveBeenCalledWith('X-Frame-Options', 'SAMEORIGIN');
            expect(res.setHeader).toHaveBeenCalledWith('X-XSS-Protection', '1; mode=block');
            expect(res.setHeader).toHaveBeenCalledWith('Referrer-Policy', 'strict-origin-when-cross-origin');
            expect(next).toHaveBeenCalled();
        });
    });

    describe('Rate Limiting', () => {
        it('should have rate limiter configured', () => {
            const rateLimiter = securityMiddleware.find(m => m.name === 'rateLimit');
            expect(rateLimiter).toBeDefined();
            expect(typeof rateLimiter).toBe('function');
        });
    });
});
