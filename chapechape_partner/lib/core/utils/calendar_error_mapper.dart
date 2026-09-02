import '../exceptions/api_exception.dart';

/// Messages 409 calendrier — codes métier Backend, pas de parsing de texte Flutter.
class CalendarErrorMapper {
  static const alreadyReserved =
      'Cette période vient d\'être réservée et ne peut plus être bloquée.';
  static const blockConflict = 'Ces dates sont déjà bloquées.';
  static const externalConflict =
      'Ces dates sont déjà occupées par une réservation externe.';
  static const dateConflict = 'Cette période n\'est plus disponible.';

  static String messageFor(Object error, {String action = 'block'}) {
    final code = _errorCode(error);
    switch (code) {
      case 'INVENTORY_ALREADY_RESERVED':
        return action == 'external'
            ? 'Cette période vient d\'être réservée et ne peut plus être ajoutée en externe.'
            : alreadyReserved;
      case 'INVENTORY_BLOCK_CONFLICT':
        return blockConflict;
      case 'EXTERNAL_RESERVATION_CONFLICT':
        return externalConflict;
      case 'RESERVATION_DATE_CONFLICT':
        return dateConflict;
      default:
        if (error is ApiException && error.statusCode == 409) {
          return action == 'external'
              ? 'Cette période n\'est plus disponible pour une réservation externe.'
              : alreadyReserved;
        }
        if (error is ApiException) return error.message;
        return 'Une erreur est survenue. Le calendrier va être actualisé.';
    }
  }

  static String? _errorCode(Object error) {
    if (error is ApiException) {
      final data = error.data;
      return (data['errorCode'] ?? data['code'])?.toString();
    }
    return null;
  }
}
