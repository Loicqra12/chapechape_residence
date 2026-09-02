/**
 * P2-07E — Dashboard realtime stub cleanup verification
 */
import fs from 'fs';
import path from 'path';

describe('P2-07E dashboard realtime stub cleanup', () => {
  it('App.js has no NotificationContext or socket.io-client wiring', () => {
    const appSrc = fs.readFileSync(path.join(__dirname, 'App.js'), 'utf8');
    expect(appSrc).not.toMatch(/NotificationContext|NotificationProvider|useNotifications/);
    expect(appSrc).not.toMatch(/socket\.io-client/);
  });

  it('NotificationsPage remains REST-authoritative via communicationService', () => {
    const pageSrc = fs.readFileSync(
      path.join(__dirname, 'pages/communication/NotificationsPage.jsx'),
      'utf8'
    );
    expect(pageSrc).toMatch(/communicationService\.getNotifications/);
    expect(pageSrc).toMatch(/communicationService\.markNotificationAsRead/);
    expect(pageSrc).not.toMatch(/useNotifications|NotificationContext|socket\.io/);
  });

  it('NotificationContext.js removed from codebase', () => {
    const contextPath = path.join(__dirname, 'contexts/NotificationContext.js');
    expect(fs.existsSync(contextPath)).toBe(false);
  });
});
