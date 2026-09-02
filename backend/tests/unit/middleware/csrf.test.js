const request = require('supertest');
const express = require('express');
const { csrfMiddleware, generateCsrfToken } = require('../../../src/middlewares/csrf.mock');

/**
 * Tests pour le middleware CSRF (version mock)
 */
describe('CSRF Middleware', () => {
    let testApp;
    
    beforeEach(() => {
        // Créer une application Express minimaliste pour tester le middleware
        testApp = express();
        testApp.use(express.json());
        
        // Route protégée par CSRF
        testApp.post('/protected', csrfMiddleware, (req, res) => {
            res.status(200).json({ message: 'Accès autorisé' });
        });
        
        // Route pour générer un token CSRF
        testApp.get('/get-token', generateCsrfToken, (req, res) => {
            // La réponse est maintenant gérée directement par le middleware mock
        });
        
        // Route qui n'est pas protégée (méthode GET)
        testApp.get('/unprotected', csrfMiddleware, (req, res) => {
            res.status(200).json({ message: 'Accès public' });
        });
        
        // Route mobile (bypass CSRF)
        testApp.post('/api/mobile/action', csrfMiddleware, (req, res) => {
            res.status(200).json({ message: 'Accès mobile' });
        });

        // Middleware d'erreur pour gérer les erreurs CSRF
        testApp.use((err, req, res, next) => {
            if (err.statusCode === 401) {
                return res.status(401).json({
                    success: false,
                    message: err.message
                });
            }
            next(err);
        });
    });
    
    describe('Protection des routes mutatives', () => {
        it('devrait autoriser les requêtes POST avec un token CSRF valide', async () => {
            // Utiliser le token connu du mock
            const csrfToken = 'test-csrf-token';
            
            // Utiliser le token pour accéder à une route protégée
            const res = await request(testApp)
                .post('/protected')
                .set('X-CSRF-Token', csrfToken)
                .send({ data: 'test' });
            
            expect(res.status).toBe(200);
            expect(res.body.message).toBe('Accès autorisé');
        });
        
        it('devrait refuser les requêtes POST sans token CSRF', async () => {
            const res = await request(testApp)
                .post('/protected')
                .send({ data: 'test' });
            
            expect(res.status).toBe(401); 
            expect(res.body.success).toBe(false);
        });
        
        it('devrait refuser les requêtes POST avec un token CSRF invalide', async () => {
            const res = await request(testApp)
                .post('/protected')
                .set('X-CSRF-Token', 'invalid-token')
                .send({ data: 'test' });
            
            expect(res.status).toBe(401); 
            expect(res.body.success).toBe(false);
        });
    });
    
    describe('Exclusions de la protection CSRF', () => {
        it('devrait permettre les requêtes GET sans token CSRF', async () => {
            const res = await request(testApp).get('/unprotected');
            
            expect(res.status).toBe(200);
            expect(res.body.message).toBe('Accès public');
        });
        
        it('devrait permettre les requêtes POST aux endpoints mobiles sans token CSRF', async () => {
            const res = await request(testApp)
                .post('/api/mobile/action')
                .send({ data: 'test' });
            
            expect(res.status).toBe(200);
            expect(res.body.message).toBe('Accès mobile');
        });
    });
    
    describe('Génération de tokens CSRF', () => {
        it('devrait générer un token CSRF valide', async () => {
            const res = await request(testApp).get('/get-token');
            
            expect(res.status).toBe(200);
            expect(res.body).toHaveProperty('csrfToken');
            expect(typeof res.body.csrfToken).toBe('string');
            expect(res.body.csrfToken.length).toBeGreaterThan(0);
        });
        
        it('devrait définir l\'en-tête X-CSRF-Token dans la réponse', async () => {
            const res = await request(testApp).get('/get-token');
            
            expect(res.headers).toHaveProperty('x-csrf-token');
            expect(res.headers['x-csrf-token']).toBe(res.body.csrfToken);
        });
    });
});
