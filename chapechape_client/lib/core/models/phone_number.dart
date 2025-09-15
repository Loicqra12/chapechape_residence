/// Modèle pour représenter un numéro de téléphone avec validation
class PhoneNumber {
  /// Code ISO du pays (ex: 'CI', 'SN', 'FR')
  final String isoCode;
  
  /// Numéro de téléphone sans le code pays
  final String phoneNumber;
  
  /// Code d'appel du pays (ex: '+225', '+221', '+33')
  final String dialCode;
  
  /// Numéro complet au format international
  String get completeNumber => '$dialCode$phoneNumber';
  
  /// Numéro formaté pour l'affichage
  String get displayNumber => '$dialCode $phoneNumber';

  const PhoneNumber({
    required this.isoCode,
    required this.phoneNumber,
    required this.dialCode,
  });

  /// Créer un PhoneNumber depuis un numéro complet
  factory PhoneNumber.fromCompleteNumber(String completeNumber) {
    // Nettoyer le numéro
    final cleaned = completeNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Détecter le pays selon le préfixe
    if (cleaned.startsWith('+225') || cleaned.startsWith('225')) {
      final number = cleaned.replaceFirst(RegExp(r'^\+?225'), '');
      return PhoneNumber(
        isoCode: 'CI',
        phoneNumber: number,
        dialCode: '+225',
      );
    } else if (cleaned.startsWith('+221') || cleaned.startsWith('221')) {
      final number = cleaned.replaceFirst(RegExp(r'^\+?221'), '');
      return PhoneNumber(
        isoCode: 'SN',
        phoneNumber: number,
        dialCode: '+221',
      );
    } else if (cleaned.startsWith('+223') || cleaned.startsWith('223')) {
      final number = cleaned.replaceFirst(RegExp(r'^\+?223'), '');
      return PhoneNumber(
        isoCode: 'ML',
        phoneNumber: number,
        dialCode: '+223',
      );
    } else if (cleaned.startsWith('+226') || cleaned.startsWith('226')) {
      final number = cleaned.replaceFirst(RegExp(r'^\+?226'), '');
      return PhoneNumber(
        isoCode: 'BF',
        phoneNumber: number,
        dialCode: '+226',
      );
    } else if (cleaned.startsWith('+224') || cleaned.startsWith('224')) {
      final number = cleaned.replaceFirst(RegExp(r'^\+?224'), '');
      return PhoneNumber(
        isoCode: 'GN',
        phoneNumber: number,
        dialCode: '+224',
      );
    } else if (cleaned.startsWith('+33') || cleaned.startsWith('33')) {
      final number = cleaned.replaceFirst(RegExp(r'^\+?33'), '');
      return PhoneNumber(
        isoCode: 'FR',
        phoneNumber: number,
        dialCode: '+33',
      );
    } else {
      // Par défaut, assumer Côte d'Ivoire
      final number = cleaned.startsWith('0') ? cleaned.substring(1) : cleaned;
      return PhoneNumber(
        isoCode: 'CI',
        phoneNumber: number,
        dialCode: '+225',
      );
    }
  }

  /// Valider le format du numéro selon le pays
  bool get isValid {
    switch (isoCode) {
      case 'CI': // Côte d'Ivoire
        return _validateIvoryCoast();
      case 'SN': // Sénégal
        return _validateSenegal();
      case 'ML': // Mali
        return _validateMali();
      case 'BF': // Burkina Faso
        return _validateBurkinaFaso();
      case 'GN': // Guinée
        return _validateGuinea();
      case 'FR': // France
        return _validateFrance();
      default:
        return phoneNumber.length >= 8 && phoneNumber.length <= 10;
    }
  }

  /// Validation pour la Côte d'Ivoire
  bool _validateIvoryCoast() {
    // Accepter 8-10 chiffres comme le backend
    if (phoneNumber.length < 8 || phoneNumber.length > 10) return false;
    
    // Vérifier les préfixes valides
    final validPrefixes = ['01', '02', '03', '05', '07', '08', '09'];
    return validPrefixes.any((prefix) => phoneNumber.startsWith(prefix));
  }

  /// Validation pour le Sénégal
  bool _validateSenegal() {
    if (phoneNumber.length != 9) return false;
    
    // Vérifier les préfixes valides
    final validPrefixes = ['70', '75', '76', '77', '78'];
    return validPrefixes.any((prefix) => phoneNumber.startsWith(prefix));
  }

  /// Validation pour le Mali
  bool _validateMali() {
    if (phoneNumber.length != 8) return false;
    
    // Vérifier les préfixes valides
    final validPrefixes = ['60', '66', '67', '70', '76', '77', '78', '79'];
    return validPrefixes.any((prefix) => phoneNumber.startsWith(prefix));
  }

  /// Validation pour le Burkina Faso
  bool _validateBurkinaFaso() {
    if (phoneNumber.length != 8) return false;
    
    // Vérifier les préfixes valides
    final validPrefixes = ['60', '61', '62', '64', '65', '66', '67', '70', '71', '72', '73', '74', '75', '76', '77', '78', '79'];
    return validPrefixes.any((prefix) => phoneNumber.startsWith(prefix));
  }

  /// Validation pour la Guinée
  bool _validateGuinea() {
    if (phoneNumber.length != 9) return false;
    
    // Vérifier les préfixes valides
    final validPrefixes = ['622', '623', '624', '625', '626', '627', '628', '629', '630', '631', '632', '633', '634', '655', '656', '657', '664', '665', '666', '667'];
    return validPrefixes.any((prefix) => phoneNumber.startsWith(prefix));
  }

  /// Validation pour la France
  bool _validateFrance() {
    if (phoneNumber.length != 9) return false;
    
    // Vérifier les préfixes valides (mobile français)
    final validPrefixes = ['6', '7'];
    return validPrefixes.any((prefix) => phoneNumber.startsWith(prefix));
  }

  /// Obtenir le nom du pays
  String get countryName {
    switch (isoCode) {
      case 'CI':
        return 'Côte d\'Ivoire';
      case 'SN':
        return 'Sénégal';
      case 'ML':
        return 'Mali';
      case 'BF':
        return 'Burkina Faso';
      case 'GN':
        return 'Guinée';
      case 'FR':
        return 'France';
      default:
        return 'Inconnu';
    }
  }

  /// Obtenir l'emoji du drapeau
  String get flagEmoji {
    switch (isoCode) {
      case 'CI':
        return '🇨🇮';
      case 'SN':
        return '🇸🇳';
      case 'ML':
        return '🇲🇱';
      case 'BF':
        return '🇧🇫';
      case 'GN':
        return '🇬🇳';
      case 'FR':
        return '🇫🇷';
      default:
        return '🌍';
    }
  }

  /// Détecter l'opérateur mobile
  String get operatorName {
    switch (isoCode) {
      case 'CI':
        if (phoneNumber.startsWith('07') || phoneNumber.startsWith('47') || phoneNumber.startsWith('67')) {
          return 'Orange CI';
        } else if (phoneNumber.startsWith('05') || phoneNumber.startsWith('45') || phoneNumber.startsWith('65')) {
          return 'MTN CI';
        } else if (phoneNumber.startsWith('01') || phoneNumber.startsWith('41') || phoneNumber.startsWith('61')) {
          return 'Moov CI';
        }
        break;
      case 'SN':
        if (phoneNumber.startsWith('77') || phoneNumber.startsWith('78')) {
          return 'Orange SN';
        } else if (phoneNumber.startsWith('70') || phoneNumber.startsWith('76')) {
          return 'Free SN';
        } else if (phoneNumber.startsWith('75')) {
          return 'Expresso';
        }
        break;
      case 'ML':
        if (phoneNumber.startsWith('77') || phoneNumber.startsWith('78')) {
          return 'Orange Mali';
        } else if (phoneNumber.startsWith('66') || phoneNumber.startsWith('67')) {
          return 'Malitel';
        }
        break;
    }
    return 'Inconnu';
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'isoCode': isoCode,
      'phoneNumber': phoneNumber,
      'dialCode': dialCode,
      'completeNumber': completeNumber,
    };
  }

  /// Créer depuis JSON
  factory PhoneNumber.fromJson(Map<String, dynamic> json) {
    return PhoneNumber(
      isoCode: json['isoCode'] ?? 'CI',
      phoneNumber: json['phoneNumber'] ?? '',
      dialCode: json['dialCode'] ?? '+225',
    );
  }

  /// Copier avec modifications
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhoneNumber &&
        other.isoCode == isoCode &&
        other.phoneNumber == phoneNumber &&
        other.dialCode == dialCode;
  }

  @override
  int get hashCode {
    return isoCode.hashCode ^ phoneNumber.hashCode ^ dialCode.hashCode;
  }

  @override
  String toString() {
    return 'PhoneNumber(isoCode: $isoCode, phoneNumber: $phoneNumber, dialCode: $dialCode)';
  }
}
