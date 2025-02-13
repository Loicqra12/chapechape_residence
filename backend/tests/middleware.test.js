const request = require('supertest');
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');
const app = require('../src/app');
const User = require('../src/models/user.model');
const jwt = require('jsonwebtoken');
const path = require('path');
const fs = require('fs');

let mongoServer;

// Créer le dossier fixtures s'il n'existe pas
const fixturesDir = path.join(__dirname, 'fixtures');
if (!fs.existsSync(fixturesDir)) {
    fs.mkdirSync(fixturesDir);
}

// Créer un petit fichier image de test
const testImagePath = path.join(fixturesDir, 'test-image.jpg');
fs.writeFileSync(testImagePath, Buffer.from('fake image data'));

// Créer un fichier texte invalide
const invalidFilePath = path.join(fixturesDir, 'invalid-file.txt');
fs.writeFileSync(invalidFilePath, 'Some text content');

// Créer un "gros" fichier
const largeFilePath = path.join(fixturesDir, 'large-image.jpg');
const largeBuffer = Buffer.alloc(6 * 1024 * 1024); // 6MB
fs.writeFileSync(largeFilePath, largeBuffer);

beforeAll(async () => {
    // Déconnexion de toute connexion existante
    if (mongoose.connection.readyState !== 0) {
        await mongoose.disconnect();
    }
    
    mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    await mongoose.connect(mongoUri, {
        useNewUrlParser: true,
        useUnifiedTopology: true
    });
});

afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();

    // Nettoyer les fichiers de test
    try {
        fs.unlinkSync(testImagePath);
        fs.unlinkSync(invalidFilePath);
        fs.unlinkSync(largeFilePath);
        fs.rmdirSync(fixturesDir);
    } catch (error) {
        console.error('Error cleaning up test files:', error);
    }
});

describe('Middleware Tests', () => {
    describe('Auth Middleware', () => {
        let testUser;
        let token;

        beforeEach(async () => {
            await User.deleteMany({});
            
            testUser = await User.create({
                email: 'test@example.com',
                password: 'password123',
                firstName: 'Test',
                lastName: 'User',
                role: 'user'
            });

            token = jwt.sign(
                { id: testUser._id, role: testUser.role },
                process.env.JWT_SECRET || 'test-secret',
                { expiresIn: '1h' }
            );
        });

        describe('verifyToken', () => {
            it('should pass with valid token', async () => {
                const res = await request(app)
                    .get('/api/auth/profile')
                    .set('Authorization', `Bearer ${token}`);

                expect(res.status).toBe(200);
            });

            it('should fail without token', async () => {
                const res = await request(app)
                    .get('/api/auth/profile');

                expect(res.status).toBe(401);
            });

            it('should fail with expired token', async () => {
                const expiredToken = jwt.sign(
                    { id: testUser._id },
                    process.env.JWT_SECRET || 'test-secret',
                    { expiresIn: '0s' }
                );

                const res = await request(app)
                    .get('/api/auth/profile')
                    .set('Authorization', `Bearer ${expiredToken}`);

                expect(res.status).toBe(401);
            });

            it('should fail with invalid token format', async () => {
                const res = await request(app)
                    .get('/api/auth/profile')
                    .set('Authorization', 'Invalid-Token-Format');

                expect(res.status).toBe(401);
            });
        });

        describe('checkRole', () => {
            it('should allow access with correct role', async () => {
                const adminUser = await User.create({
                    email: 'admin@example.com',
                    password: 'password123',
                    firstName: 'Admin',
                    lastName: 'User',
                    role: 'admin'
                });

                const adminToken = jwt.sign(
                    { id: adminUser._id, role: 'admin' },
                    process.env.JWT_SECRET || 'test-secret'
                );

                const res = await request(app)
                    .get('/api/admin/dashboard')
                    .set('Authorization', `Bearer ${adminToken}`);

                expect(res.status).toBe(200);
            });

            it('should deny access with incorrect role', async () => {
                const res = await request(app)
                    .get('/api/admin/dashboard')
                    .set('Authorization', `Bearer ${token}`);

                expect(res.status).toBe(403);
            });
        });
    });

    describe('Validation Middleware', () => {
        it('should validate required fields', async () => {
            const res = await request(app)
                .post('/api/auth/register')
                .send({});

            expect(res.status).toBe(400);
            expect(res.body).toHaveProperty('error');
        });

        it('should validate email format', async () => {
            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    email: 'invalid-email',
                    password: 'password123',
                    firstName: 'Test',
                    lastName: 'User',
                    role: 'user'
                });

            expect(res.status).toBe(400);
            expect(res.body.error).toContain('email');
        });

        it('should validate password strength', async () => {
            const res = await request(app)
                .post('/api/auth/register')
                .send({
                    email: 'test@example.com',
                    password: 'weak',
                    firstName: 'Test',
                    lastName: 'User',
                    role: 'user'
                });

            expect(res.status).toBe(400);
            expect(res.body.error).toContain('password');
        });
    });

    describe('Upload Middleware', () => {
        it('should handle file upload', async () => {
            const res = await request(app)
                .post('/api/upload')
                .set('Authorization', `Bearer ${token}`)
                .attach('file', testImagePath);

            expect(res.status).toBe(200);
        });

        it('should validate file type', async () => {
            const res = await request(app)
                .post('/api/upload')
                .set('Authorization', `Bearer ${token}`)
                .attach('file', invalidFilePath);

            expect(res.status).toBe(400);
        });

        it('should handle file size limit', async () => {
            const res = await request(app)
                .post('/api/upload')
                .set('Authorization', `Bearer ${token}`)
                .attach('file', largeFilePath);

            expect(res.status).toBe(400);
        });
    });

    describe('Error Middleware', () => {
        it('should handle validation errors', async () => {
            const res = await request(app)
                .post('/api/auth/register')
                .send({});

            expect(res.status).toBe(400);
            expect(res.body).toHaveProperty('error');
        });

        it('should handle not found errors', async () => {
            const res = await request(app)
                .get('/api/non-existent-route');

            expect(res.status).toBe(404);
        });

        it('should handle server errors', async () => {
            const res = await request(app)
                .get('/api/test-error');

            expect(res.status).toBe(500);
        });

        it('should handle custom errors', async () => {
            const res = await request(app)
                .get('/api/test-custom-error');

            expect(res.status).toBe(400);
            expect(res.body).toHaveProperty('error');
        });
    });
});
