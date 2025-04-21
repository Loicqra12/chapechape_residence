const request = require('supertest');
const app = require('../src/app');
const Residence = require('../src/models/residence.model');
const User = require('../src/models/user.model');
const { generateToken } = require('../src/utils/jwt');

describe('Performance Tests', () => {
    let userToken;
    const testUser = {
        firstName: 'Performance',
        lastName: 'Test',
        email: 'performance@test.com',
        password: 'Test123!',
        role: 'client'
    };

    beforeAll(async () => {
        const user = await User.create(testUser);
        userToken = generateToken(user._id);

        // Créer plusieurs résidences pour les tests de performance
        const residences = Array.from({ length: 50 }, (_, i) => ({
            name: `Test Residence ${i}`,
            description: 'A beautiful test residence',
            price: 1000 + i * 100,
            rooms: 3,
            amenities: ['wifi', 'parking', 'pool']
        }));

        await Residence.insertMany(residences);
    });

    describe('Response Time Tests', () => {
        it('should respond to /api/residences within 200ms', async () => {
            const start = Date.now();
            
            await request(app)
                .get('/api/residences');
            
            const responseTime = Date.now() - start;
            expect(responseTime).toBeLessThan(200);
        });

        it('should respond to filtered search within 300ms', async () => {
            const start = Date.now();
            
            await request(app)
                .get('/api/residences')
                .query({
                    minPrice: 1000,
                    maxPrice: 2000,
                    rooms: 3,
                    amenities: ['wifi']
                });
            
            const responseTime = Date.now() - start;
            expect(responseTime).toBeLessThan(300);
        });
    });

    describe('Pagination Performance', () => {
        it('should efficiently handle paginated results', async () => {
            const start = Date.now();
            
            const res = await request(app)
                .get('/api/residences')
                .query({
                    page: 1,
                    limit: 10
                });
            
            const responseTime = Date.now() - start;
            expect(responseTime).toBeLessThan(100);
            expect(res.body.data.length).toBe(10);
        });
    });

    describe('Concurrent Request Handling', () => {
        it('should handle multiple concurrent requests', async () => {
            const numberOfRequests = 10;
            const requests = Array.from({ length: numberOfRequests }, () =>
                request(app).get('/api/residences')
            );

            const start = Date.now();
            await Promise.all(requests);
            const totalTime = Date.now() - start;

            // Le temps moyen par requête devrait être inférieur à 100ms
            const averageTime = totalTime / numberOfRequests;
            expect(averageTime).toBeLessThan(100);
        });
    });

    describe('Cache Performance', () => {
        it('should serve cached responses faster', async () => {
            // Première requête (non cachée)
            const firstStart = Date.now();
            await request(app).get('/api/residences');
            const firstTime = Date.now() - firstStart;

            // Deuxième requête (devrait être cachée)
            const secondStart = Date.now();
            await request(app).get('/api/residences');
            const secondTime = Date.now() - secondStart;

            // La requête cachée devrait être au moins 30% plus rapide
            expect(secondTime).toBeLessThan(firstTime * 0.7);
        });
    });

    describe('Database Query Performance', () => {
        it('should efficiently execute complex queries', async () => {
            const start = Date.now();
            
            await request(app)
                .get('/api/residences')
                .query({
                    minPrice: 1000,
                    maxPrice: 3000,
                    rooms: 3,
                    amenities: ['wifi', 'parking'],
                    sort: 'price',
                    order: 'desc'
                });
            
            const queryTime = Date.now() - start;
            expect(queryTime).toBeLessThan(500);
        });
    });
});
