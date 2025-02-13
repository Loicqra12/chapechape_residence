const request = require('supertest');
const app = require('../src/app');
const User = require('../src/models/user.model');
const SystemSetting = require('../src/models/systemSetting.model');
const { generateToken } = require('../src/utils/jwt');

describe('SuperAdmin Routes', () => {
    let superAdminToken;
    let adminId;

    const superAdmin = {
        firstName: 'Super',
        lastName: 'Admin',
        email: 'superadmin@test.com',
        password: 'SuperAdmin123!',
        role: 'superadmin'
    };

    const testAdmin = {
        firstName: 'Test',
        lastName: 'Admin',
        email: 'admin@test.com',
        password: 'Admin123!',
        role: 'admin'
    };

    beforeEach(async () => {
        // Créer un super admin et générer son token
        const admin = await User.create(superAdmin);
        superAdminToken = generateToken(admin._id);
    });

    describe('Admin Management', () => {
        describe('POST /api/superadmin/admins', () => {
            it('should create a new admin', async () => {
                const res = await request(app)
                    .post('/api/superadmin/admins')
                    .set('Authorization', `Bearer ${superAdminToken}`)
                    .send(testAdmin);

                expect(res.status).toBe(201);
                expect(res.body.success).toBe(true);
                expect(res.body.data.role).toBe('admin');
            });
        });

        describe('GET /api/superadmin/admins', () => {
            beforeEach(async () => {
                const admin = await User.create(testAdmin);
                adminId = admin._id;
            });

            it('should get all admins', async () => {
                const res = await request(app)
                    .get('/api/superadmin/admins')
                    .set('Authorization', `Bearer ${superAdminToken}`);

                expect(res.status).toBe(200);
                expect(Array.isArray(res.body.data)).toBe(true);
            });
        });

        describe('PUT /api/superadmin/admins/:id', () => {
            it('should update admin details', async () => {
                const update = { firstName: 'Updated' };
                const res = await request(app)
                    .put(`/api/superadmin/admins/${adminId}`)
                    .set('Authorization', `Bearer ${superAdminToken}`)
                    .send(update);

                expect(res.status).toBe(200);
                expect(res.body.data.firstName).toBe(update.firstName);
            });
        });
    });

    describe('System Settings', () => {
        describe('GET /api/superadmin/settings', () => {
            beforeEach(async () => {
                await SystemSetting.create({
                    category: 'general',
                    key: 'maintenance_mode',
                    value: 'false'
                });
            });

            it('should get all system settings', async () => {
                const res = await request(app)
                    .get('/api/superadmin/settings')
                    .set('Authorization', `Bearer ${superAdminToken}`);

                expect(res.status).toBe(200);
                expect(Array.isArray(res.body.data)).toBe(true);
            });
        });

        describe('PUT /api/superadmin/settings', () => {
            it('should update system setting', async () => {
                const settingUpdate = {
                    category: 'general',
                    key: 'maintenance_mode',
                    value: 'true'
                };

                const res = await request(app)
                    .put('/api/superadmin/settings')
                    .set('Authorization', `Bearer ${superAdminToken}`)
                    .send(settingUpdate);

                expect(res.status).toBe(200);
                expect(res.body.data.value).toBe(settingUpdate.value);
            });
        });
    });

    describe('Security', () => {
        describe('GET /api/superadmin/security/logs', () => {
            it('should get activity logs', async () => {
                const res = await request(app)
                    .get('/api/superadmin/security/logs')
                    .set('Authorization', `Bearer ${superAdminToken}`);

                expect(res.status).toBe(200);
                expect(Array.isArray(res.body.data)).toBe(true);
            });
        });

        describe('POST /api/superadmin/security/block-ip', () => {
            it('should block an IP address', async () => {
                const res = await request(app)
                    .post('/api/superadmin/security/block-ip')
                    .set('Authorization', `Bearer ${superAdminToken}`)
                    .send({
                        ip: '192.168.1.1',
                        reason: 'Suspicious activity'
                    });

                expect(res.status).toBe(200);
                expect(res.body.success).toBe(true);
            });
        });
    });

    describe('Reports', () => {
        describe('GET /api/superadmin/reports/system', () => {
            it('should get system report', async () => {
                const res = await request(app)
                    .get('/api/superadmin/reports/system')
                    .set('Authorization', `Bearer ${superAdminToken}`);

                expect(res.status).toBe(200);
                expect(res.body.data).toHaveProperty('systemHealth');
            });
        });

        describe('GET /api/superadmin/reports/security', () => {
            it('should get security report', async () => {
                const res = await request(app)
                    .get('/api/superadmin/reports/security')
                    .set('Authorization', `Bearer ${superAdminToken}`);

                expect(res.status).toBe(200);
                expect(res.body.data).toHaveProperty('securityMetrics');
            });
        });
    });
});
