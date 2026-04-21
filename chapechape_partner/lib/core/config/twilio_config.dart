import 'package:flutter/foundation.dart';

/// Configuration SMS Partner (toujours via le backend, jamais Twilio dans l’APK).
///
/// **Comportement par défaut (recommandé, sans rien oublier au Play Store)** :
/// - [debug] (`flutter run`) : SMS **simulés** (log) — pas d’appel API, pratique sans backend.
/// - [release] (`flutter build appbundle` / APK release) : SMS **réels** via `POST /api/sms/send`.
///
/// **Overrides `--dart-define` (compile-time)** :
/// - `PARTNER_SMS_PRODUCTION=true` : forcer SMS réels même en **debug** (test intégration).
/// - `PARTNER_SMS_FORCE_DEV=true` : forcer **simulation** même en **release** (ex. build interne sans frais SMS).
///
/// Exemples :
/// ```text
/// flutter run --dart-define=PARTNER_SMS_PRODUCTION=true
/// flutter build appbundle --dart-define=PARTNER_SMS_FORCE_DEV=true
/// ```
class TwilioConfig {
  /// Indique si les envois SMS passent par l’API backend (`true`) ou restent simulés (`false`).
  static bool get isProduction {
    const forceDev = bool.fromEnvironment(
      'PARTNER_SMS_FORCE_DEV',
      defaultValue: false,
    );
    if (forceDev) {
      return false;
    }
    const forceProd = bool.fromEnvironment(
      'PARTNER_SMS_PRODUCTION',
      defaultValue: false,
    );
    if (forceProd) {
      return true;
    }
    return kReleaseMode;
  }

  /// Temps minimum entre deux SMS (en minutes)
  static const int smsThrottleTime = 5;

  /// Préférences de notification par défaut (types activés)
  static const Map<String, bool> defaultNotificationPreferences = {
    'residence_created': true,
    'residence_updated': true,
    'residence_deleted': true,
    'booking_created': true,
    'booking_confirmed': true,
    'booking_canceled': true,
    'message_received': true,
    'review_received': true,
  };

  /// Canaux de notification disponibles
  static const List<String> availableChannels = [
    'push', // Notifications push
    'sms', // SMS
    'email', // Email
  ];

  /// Canaux activés par défaut
  static const Map<String, bool> defaultChannels = {
    'push': true,
    'sms': false,
    'email': false,
  };
}
