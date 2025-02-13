const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/user.model');
const fs = require('fs').promises;
const path = require('path');
const { cleanupTempFiles } = require('../src/utils/cleanup');

describe('File Cleanup Tests', () => {
    let adminToken;
    const tempDir = path.join(__dirname, '../temp');
    
    const testAdmin = {
        email: 'admin@example.com',
        password: 'Password123!',
        firstName: 'Admin',
        lastName: 'User',
        role: 'admin'
    };

    beforeAll(async () => {
        // Create temp directory if it doesn't exist
        try {
            await fs.mkdir(tempDir, { recursive: true });
        } catch (error) {
            if (error.code !== 'EEXIST') throw error;
        }

        const admin = await User.create(testAdmin);
        const loginRes = await request(app)
            .post('/api/auth/login')
            .send({
                email: testAdmin.email,
                password: testAdmin.password
            });
        adminToken = loginRes.body.data.token;
    });

    afterAll(async () => {
        await User.deleteMany({});
        // Clean up temp directory
        try {
            await fs.rm(tempDir, { recursive: true, force: true });
        } catch (error) {
            console.error('Error cleaning up temp directory:', error);
        }
    });

    describe('Temporary File Management', () => {
        it('should clean up old temporary files', async () => {
            // Create some test temporary files
            const testFiles = [
                'test1.tmp',
                'test2.tmp',
                'test3.tmp'
            ];

            for (const file of testFiles) {
                await fs.writeFile(
                    path.join(tempDir, file),
                    'test content'
                );
            }

            // Set file timestamps to be old
            const oldTime = new Date(Date.now() - 25 * 60 * 60 * 1000); // 25 hours ago
            for (const file of testFiles) {
                await fs.utimes(
                    path.join(tempDir, file),
                    oldTime,
                    oldTime
                );
            }

            // Run cleanup
            await cleanupTempFiles();

            // Check if files were deleted
            const remainingFiles = await fs.readdir(tempDir);
            expect(remainingFiles.length).toBe(0);
        });

        it('should not delete recent temporary files', async () => {
            // Create a recent test file
            const testFile = 'recent.tmp';
            await fs.writeFile(
                path.join(tempDir, testFile),
                'test content'
            );

            // Run cleanup
            await cleanupTempFiles();

            // Check if file still exists
            const remainingFiles = await fs.readdir(tempDir);
            expect(remainingFiles).toContain(testFile);
        });

        it('should handle missing files gracefully', async () => {
            // Try to clean up a non-existent directory
            const nonExistentDir = path.join(__dirname, 'nonexistent');
            
            // This should not throw an error
            await expect(cleanupTempFiles(nonExistentDir))
                .resolves
                .not
                .toThrow();
        });
    });

    describe('File Upload Cleanup', () => {
        it('should clean up after successful upload', async () => {
            const testFile = path.join(tempDir, 'upload.jpg');
            await fs.writeFile(testFile, 'test image content');

            const res = await request(app)
                .post('/api/residences/upload')
                .set('Authorization', `Bearer ${adminToken}`)
                .attach('image', testFile);

            expect(res.status).toBe(200);

            // Check if temporary file was cleaned up
            try {
                await fs.access(testFile);
                fail('Temporary file should have been deleted');
            } catch (error) {
                expect(error.code).toBe('ENOENT');
            }
        });

        it('should clean up after failed upload', async () => {
            const testFile = path.join(tempDir, 'invalid.txt');
            await fs.writeFile(testFile, 'invalid content');

            const res = await request(app)
                .post('/api/residences/upload')
                .set('Authorization', `Bearer ${adminToken}`)
                .attach('image', testFile);

            expect(res.status).toBe(400);

            // Check if temporary file was cleaned up
            try {
                await fs.access(testFile);
                fail('Temporary file should have been deleted');
            } catch (error) {
                expect(error.code).toBe('ENOENT');
            }
        });
    });

    describe('Scheduled Cleanup', () => {
        it('should run scheduled cleanup job', async () => {
            // Create some test files
            const testFiles = [
                'scheduled1.tmp',
                'scheduled2.tmp'
            ];

            for (const file of testFiles) {
                await fs.writeFile(
                    path.join(tempDir, file),
                    'test content'
                );
            }

            // Set file timestamps to be old
            const oldTime = new Date(Date.now() - 25 * 60 * 60 * 1000);
            for (const file of testFiles) {
                await fs.utimes(
                    path.join(tempDir, file),
                    oldTime,
                    oldTime
                );
            }

            // Trigger scheduled cleanup
            const res = await request(app)
                .post('/api/maintenance/cleanup')
                .set('Authorization', `Bearer ${adminToken}`);

            expect(res.status).toBe(200);

            // Check if files were deleted
            const remainingFiles = await fs.readdir(tempDir);
            expect(remainingFiles.length).toBe(0);
        });
    });
});
