/**
 * P2-07G — Socket compatibility alias review (contract register, no removals)
 */
const fs = require('fs');
const path = require('path');
const SocketService = require('../../../src/services/socket.service');

const SOCKET_SERVICE_PATH = path.join(
  __dirname,
  '../../../src/services/socket.service.js'
);

describe('P2-07G socket alias compatibility review', () => {
  describe('canonical reservation events — frozen contract', () => {
    it('emitReservationStatusChange emits reservation_status_changed to client user room', () => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      expect(source).toMatch(
        /io\.to\(room\)\.emit\('reservation_status_changed', eventData\)/
      );
    });

    it('emitReservationStatusChange emits partner_reservation_status_changed to partner user room', () => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      expect(source).toMatch(
        /io\.to\(`user_\$\{partnerId\}`\)\.emit\('partner_reservation_status_changed', eventData\)/
      );
    });

    it('emitReservationStatusChange emits residence_reservation_update to residence room', () => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      expect(source).toMatch(
        /io\.to\(`residence_\$\{residenceId\}`\)\.emit\('residence_reservation_update', eventData\)/
      );
    });

    it('emitNewReservation emits new_reservation_received to partner user room', () => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      expect(source).toMatch(
        /io\.to\(`user_\$\{partnerId\}`\)\.emit\('new_reservation_received', eventData\)/
      );
    });

    it('notifyNewMessage emits new_message unchanged', () => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      expect(source).toMatch(/\.emit\('new_message',/);
    });
  });

  describe('compatibility aliases — single payload source', () => {
    it('aliases reuse eventData object (no second payload construction)', () => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      const fnBlock = source.slice(
        source.indexOf('static emitReservationStatusChange'),
        source.indexOf('static emitNewReservation')
      );
      expect(fnBlock).toMatch(/const eventData = \{/);
      expect(fnBlock).toMatch(/emit\('booking_status_updated', eventData\)/);
      expect(fnBlock).toMatch(/emit\('booking_approved', eventData\)/);
      expect(fnBlock).toMatch(/emit\('booking_rejected', eventData\)/);
      expect(fnBlock).toMatch(/emit\('reservation_expired', eventData\)/);
      expect(fnBlock).toMatch(/emit\('booking_expired', eventData\)/);
      // No alternate payload builder for aliases inside the function
      expect(fnBlock.match(/const eventData = \{/g).length).toBe(1);
    });
  });

  describe('P2-07G removal gate — aliases retained in this lot', () => {
    const retainedAliases = [
      'booking_status_updated',
      'booking_approved',
      'booking_rejected',
      'reservation_expired',
      'booking_expired',
      'new_reservation',
      'residence_new_reservation',
      'reservation_cancelled',
      'blocked_dates_updated',
    ];

    it.each(retainedAliases)('%s producer still present in socket.service.js', (eventName) => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      expect(source).toContain(`'${eventName}'`);
    });

    it('partner_reservation_expired is not produced (consumer-only legacy listener on Partner)', () => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      expect(source).not.toMatch(/emit\('partner_reservation_expired'/);
    });

    it('emitPaymentDeadlineNotification and emitReservationExpired remain absent (P2-07B)', () => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      expect(source).not.toMatch(/emitPaymentDeadlineNotification/);
      expect(source).not.toMatch(/emitReservationExpired/);
    });
  });

  describe('Client Flutter dedup contract (P2-06B)', () => {
    it('Client listens only reservation_status_changed for status (not booking_status_updated)', () => {
      const clientSocketPath = path.join(
        __dirname,
        '../../../../chapechape_client/lib/core/services/socket_service.dart'
      );
      const source = fs.readFileSync(clientSocketPath, 'utf8');
      expect(source).toContain("_socket!.on('reservation_status_changed', handleStatus)");
      expect(source).not.toMatch(/\.on\('booking_status_updated'/);
    });
  });

  describe('Partner Flutter live consumers', () => {
    it('Partner listens new_reservation_received and residence_reservation_update', () => {
      const partnerSocketPath = path.join(
        __dirname,
        '../../../../chapechape_partner/lib/core/services/socket_service.dart'
      );
      const source = fs.readFileSync(partnerSocketPath, 'utf8');
      expect(source).toContain("on('new_reservation_received'");
      expect(source).toContain("on('residence_reservation_update'");
      expect(source).toContain("on('partner_reservation_status_changed'");
    });
  });

  describe('side effects — emit only (no DB in socket service)', () => {
    it('socket.service.js does not write Mongo or send push', () => {
      const source = fs.readFileSync(SOCKET_SERVICE_PATH, 'utf8');
      expect(source).not.toMatch(/Notification\.create|createNotification|oneSignal|sendToMultipleUsers/);
      expect(source).not.toMatch(/Reservation\.findOneAndUpdate|updateMany|insertMany/);
    });
  });
});
