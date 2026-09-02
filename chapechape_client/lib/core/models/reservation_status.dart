/// P1-06 — valeurs Reservation.status canoniques côté Client.
/// Les catégories UI (upcoming / past) se dérivent de ces valeurs.
/// Ne pas confondre avec [paymentStatus].
class ReservationStatusCanon {
  static const pending = 'pending';
  static const awaitingApproval = 'awaiting_approval';
  static const paymentPending = 'payment_pending';
  static const confirmed = 'confirmed';
  static const inStay = 'in_stay';
  static const expired = 'expired';
  static const cancelled = 'cancelled';
  static const completed = 'completed';
  static const refunded = 'refunded';
  static const unknown = 'unknown';

  static const Set<String> canonical = {
    pending,
    awaitingApproval,
    paymentPending,
    confirmed,
    inStay,
    expired,
    cancelled,
    completed,
    refunded,
  };

  /// Alias de caches / anciennes apps. Jamais réémis tels quels.
  static const Map<String, String> aliases = {
    'pending_payment': paymentPending,
    'waiting_payment': paymentPending,
    'payment_required': paymentPending,
    'in_progress': inStay,
    'checked_in': inStay,
    'ongoing': inStay,
    'checked_out': completed,
    'finished': completed,
    'complete': completed,
    'canceled': cancelled,
    'payment_expired': expired,
    'rejected': cancelled,
  };

  static const Set<String> activeUi = {
    pending,
    awaitingApproval,
    paymentPending,
    confirmed,
    inStay,
  };

  static const Set<String> pastUi = {
    expired,
    cancelled,
    completed,
    refunded,
  };

  static String fromApi(String? value) {
    if (value == null || value.trim().isEmpty) return unknown;
    final raw = value.trim().toLowerCase();
    if (canonical.contains(raw)) return raw;
    return aliases[raw] ?? unknown;
  }

  static bool isCanonical(String status) => canonical.contains(status);

  static bool isPaymentTimerStatus(String status) => status == paymentPending;

  static bool isHostApprovalTimerStatus(String status) => status == awaitingApproval;

  static bool isQrEligible(String status) =>
      status == confirmed || status == inStay;

  /// Purpose QR selon le statut canonique (confirmed → checkin, in_stay → checkout).
  static String? stayQrPurpose(String status) {
    final canon = fromApi(status);
    if (canon == confirmed) return 'checkin';
    if (canon == inStay) return 'checkout';
    return null;
  }

  static bool isUpcoming(String status, DateTime checkIn, DateTime now) {
    if (pastUi.contains(status)) return false;
    return activeUi.contains(status) && !checkIn.isBefore(now);
  }

  static bool isPast(String status, DateTime checkOut, DateTime now) {
    if (pastUi.contains(status)) return true;
    return checkOut.isBefore(now);
  }
}
