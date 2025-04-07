/// Configuration pour Twilio
class TwilioConfig {
  /// Mode production ou développement
  static const bool isProduction = false;
  
  /// Identifiant du compte Twilio (SID)
  static const String accountSid = 'AC00000000000000000000000000000000';
  
  /// Token d'authentification Twilio
  static const String authToken = '0000000000000000000000000000000';
  
  /// Numéro Twilio pour envoyer les SMS
  static const String twilioNumber = '+12345678900';
  
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
    'push',  // Notifications push
    'sms',   // SMS
    'email', // Email
  ];
  
  /// Canaux activés par défaut
  static const Map<String, bool> defaultChannels = {
    'push': true,
    'sms': false,
    'email': false,
  };
} 