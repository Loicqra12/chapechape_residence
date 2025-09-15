/// Classe pour représenter un numéro de téléphone avec son code pays
class PhoneNumber {
  /// Code ISO du pays (ex: 'CI', 'SN', 'ML')
  final String isoCode;
  
  /// Numéro national sans le code pays
  final String phoneNumber;
  
  /// Code pays numérique (ex: '+225', '+221')
  final String dialCode;

  PhoneNumber({
    required this.isoCode,
    required this.phoneNumber,
    String? dialCode,
  }) : dialCode = dialCode ?? _getDialCodeFromIsoCode(isoCode);

  /// Obtenir le code pays à partir du code ISO
  static String _getDialCodeFromIsoCode(String isoCode) {
    switch (isoCode) {
      case 'CI': return '+225'; // Côte d'Ivoire
      case 'SN': return '+221'; // Sénégal
      case 'ML': return '+223'; // Mali
      case 'BF': return '+226'; // Burkina Faso
      case 'GN': return '+224'; // Guinée
      case 'GH': return '+233'; // Ghana
      case 'NG': return '+234'; // Nigeria
      case 'TG': return '+228'; // Togo
      case 'BJ': return '+229'; // Bénin
      default: return '+225';   // Par défaut Côte d'Ivoire
    }
  }

  /// Numéro complet au format E.164
  String get completeNumber => '$dialCode$phoneNumber';

  /// Numéro formaté pour l'affichage
  String get formattedNumber {
    if (phoneNumber.length >= 8) {
      // Format: XX XX XX XX XX
      final parts = <String>[];
      for (int i = 0; i < phoneNumber.length; i += 2) {
        final end = (i + 2 < phoneNumber.length) ? i + 2 : phoneNumber.length;
        parts.add(phoneNumber.substring(i, end));
      }
      return parts.join(' ');
    }
    return phoneNumber;
  }

  /// Validation du numéro
  bool get isValid {
    if (phoneNumber.isEmpty) return false;
    
    // Validation basique : doit contenir uniquement des chiffres
    if (!RegExp(r'^\d+$').hasMatch(phoneNumber)) return false;
    
    // Validation par pays - alignée avec le backend
    switch (isoCode) {
      case 'CI': // Côte d'Ivoire : 8-10 chiffres (comme le backend)
        return phoneNumber.length >= 8 && phoneNumber.length <= 10 && 
               RegExp(r'^(0[1-7]|[1-7]\d)\d{6,8}$').hasMatch(phoneNumber);
      case 'SN': // Sénégal : 9 chiffres (7X)
        return phoneNumber.length == 9 && phoneNumber.startsWith('7');
      case 'ML': // Mali : 8 chiffres
        return phoneNumber.length == 8;
      case 'BF': // Burkina Faso : 8 chiffres
        return phoneNumber.length == 8;
      case 'GN': // Guinée : 9 chiffres
        return phoneNumber.length == 9;
      default:
        return phoneNumber.length >= 8 && phoneNumber.length <= 10;
    }
  }

  /// Parser un numéro E.164 complet
  static PhoneNumber? parseE164(String phoneE164) {
    if (!phoneE164.startsWith('+')) return null;
    
    // Mapping des codes pays vers ISO
    final countryMapping = {
      '+225': 'CI', '+221': 'SN', '+223': 'ML', '+226': 'BF',
      '+224': 'GN', '+233': 'GH', '+234': 'NG', '+228': 'TG', '+229': 'BJ'
    };
    
    for (final entry in countryMapping.entries) {
      if (phoneE164.startsWith(entry.key)) {
        final nationalNumber = phoneE164.substring(entry.key.length);
        return PhoneNumber(
          isoCode: entry.value,
          phoneNumber: nationalNumber,
          dialCode: entry.key,
        );
      }
    }
    
    // Si aucun code reconnu, supposer Côte d'Ivoire
    if (phoneE164.length > 4) {
      return PhoneNumber(
        isoCode: 'CI',
        phoneNumber: phoneE164.substring(4),
        dialCode: '+225',
      );
    }
    
    return null;
  }

  @override
  String toString() => completeNumber;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneNumber &&
          runtimeType == other.runtimeType &&
          isoCode == other.isoCode &&
          phoneNumber == other.phoneNumber;

  @override
  int get hashCode => isoCode.hashCode ^ phoneNumber.hashCode;

  /// Copier avec des modifications
  PhoneNumber copyWith({
    String? isoCode,
    String? phoneNumber,
    String? dialCode,
  }) {
    return PhoneNumber(
      isoCode: isoCode ?? this.isoCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dialCode: dialCode ?? this.dialCode,
    );
  }
}
