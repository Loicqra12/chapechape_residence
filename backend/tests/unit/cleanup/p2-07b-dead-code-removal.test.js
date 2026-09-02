/**
 * P2-07B — Characterization tests for notification hub runtime winners
 * (post shadow-block removal; behavior must remain identical)
 */
const notificationService = require('../../../src/services/notification.service');
const Notification = require('../../../src/models/notification.model');
const User = require('../../../src/models/user.model');
const notificationTypes = require('../../../src/utils/notification-types');
const oneSignalService = require('../../../src/services/onesignal.service');

jest.setTimeout(60000);

async function createUser(role, suffix = '') {
  return User.create({
    email: `${role}-p2-07b-${suffix}-${Date.now()}-${Math.random()}@test.com`,
    password: 'Test1234!',
    firstName: role,
    lastName: 'Test',
    role,
    deviceTokens: [],
  });
}

describe('P2-07B dead-code removal — notification runtime winners', () => {
  beforeEach(() => {
    jest.spyOn(oneSignalService, 'sendToMultipleUsers').mockResolvedValue({
      success: true,
      status: 'sent',
      providerId: 'os-p2-07b',
      recipients: 0,
      invalidSubscriptionIds: [],
    });
    jest.spyOn(require('../../../src/services/email.service'), 'sendNotificationEmail')
      .mockResolvedValue(undefined);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('notifyVerificationSent — runtime winner uses DB role lookup + message text', async () => {
    const partner = await createUser('partner', 'verify-sent');
    const phone = '+2250700000001';
    const channel = 'sms';

    await notificationService.notifyVerificationSent(partner._id, phone, channel);

    const notif = await Notification.findOne({ user: partner._id }).sort({ createdAt: -1 });
    expect(notif).toBeTruthy();
    expect(notif.type).toBe(notificationTypes.PARTNER.VERIFICATION_SENT);
    expect(notif.message).toContain('SMS');
    expect(notif.message).toContain(phone);
    expect(notif.data.phoneNumber).toBe(phone);
    expect(notif.data.channel).toBe(channel);
    expect(notif.data.sentAt).toBeTruthy();
  });

  it('notifyVerificationSuccess — runtime winner uses DB role lookup + message text', async () => {
    const partner = await createUser('partner', 'verify-ok');
    const phone = '+2250700000002';

    await notificationService.notifyVerificationSuccess(partner._id, phone);

    const notif = await Notification.findOne({ user: partner._id }).sort({ createdAt: -1 });
    expect(notif).toBeTruthy();
    expect(notif.type).toBe(notificationTypes.PARTNER.VERIFICATION_SUCCESS);
    expect(notif.message).toContain(phone);
    expect(notif.data.phoneNumber).toBe(phone);
    expect(notif.data.verifiedAt).toBeTruthy();
  });

  it('notifyNewLogin — runtime winner uses DB role lookup + ip in message', async () => {
    const client = await createUser('client', 'login');
    const ip = '192.168.1.50';
    const userAgent = 'Mozilla/5.0 Test';

    await notificationService.notifyNewLogin(client._id, ip, userAgent);

    const notif = await Notification.findOne({ user: client._id }).sort({ createdAt: -1 });
    expect(notif).toBeTruthy();
    expect(notif.type).toBe(notificationTypes.CLIENT.LOGIN_ALERT);
    expect(notif.message).toContain(ip);
    expect(notif.data.ip).toBe(ip);
    expect(notif.data.userAgent).toBe(userAgent);
    expect(notif.data.loginAt).toBeTruthy();
  });

  it('notifyNewLogin — no-op when user missing (runtime winner guard)', async () => {
    const fakeId = '507f1f77bcf86cd799439011';
    await notificationService.notifyNewLogin(fakeId, '10.0.0.1', 'agent');
    expect(await Notification.countDocuments({ user: fakeId })).toBe(0);
  });
});

describe('P2-07B dead-code removal — static orphan check', () => {
  it('removed symbols are not exported on live services', () => {
    const SocketService = require('../../../src/services/socket.service');
    const twilioService = require('../../../src/services/twilio.service');

    expect(typeof SocketService.emitPaymentDeadlineNotification).toBe('undefined');
    expect(typeof SocketService.emitReservationExpired).toBe('undefined');
    expect(typeof twilioService.sendBookingNotification).toBe('undefined');
    expect(typeof twilioService.sendWhatsAppBookingNotification).toBe('undefined');
    expect(typeof notificationService.notifyPhoneChange).toBe('undefined');
    expect(typeof notificationService.notifyVerificationFailed).toBe('undefined');
  });

  it('phone-change orphan service file is gone', () => {
    expect(() => require('../../../src/services/phone-change-notification.service')).toThrow();
  });
});
