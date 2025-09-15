/// Modèle représentant les informations d'un pays
class CountryInfo {
  /// Code pays (ISO 3166-1 alpha-2)
  final String code;
  
  /// Nom du pays
  final String name;
  
  /// Code d'appel téléphonique
  final String callingCode;
  
  /// Devise du pays
  final String currency;
  
  /// Statut du pays (active, beta, planned)
  final String status;
  
  /// Priorité pour l'affichage
  final int priority;
  
  /// Nombre d'opérateurs disponibles
  final int operatorCount;
  
  /// Nombre d'options de paiement
  final int paymentOptions;
  
  /// Emoji du drapeau (optionnel)
  final String? flagEmoji;
  
  /// Langues supportées
  final List<String> languages;
  
  /// Fuseau horaire
  final String? timeZone;
  
  /// Population estimée
  final int? estimatedPopulation;
  
  /// Opérateurs disponibles
  final Map<String, OperatorInfo>? operators;
  
  /// Réglementations du pays
  final CountryRegulations? regulations;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.callingCode,
    required this.currency,
    required this.status,
    required this.priority,
    this.operatorCount = 0,
    this.paymentOptions = 0,
    this.flagEmoji,
    this.languages = const [],
    this.timeZone,
    this.estimatedPopulation,
    this.operators,
    this.regulations,
  });

  /// Créer depuis JSON
  factory CountryInfo.fromJson(Map<String, dynamic> json) {
    return CountryInfo(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      callingCode: json['callingCode'] ?? '',
      currency: json['currency'] ?? '',
      status: json['status'] ?? 'unknown',
      priority: json['priority'] ?? 999,
      operatorCount: json['operatorCount'] ?? 0,
      paymentOptions: json['paymentOptions'] ?? 0,
      flagEmoji: json['flagEmoji'],
      languages: List<String>.from(json['languages'] ?? []),
      timeZone: json['timeZone'],
      estimatedPopulation: json['estimatedPopulation'],
      operators: json['operators'] != null 
          ? Map<String, OperatorInfo>.from(
              (json['operators'] as Map).map(
                (key, value) => MapEntry(
                  key.toString(), 
                  OperatorInfo.fromJson(value as Map<String, dynamic>)
                )
              )
            )
          : null,
      regulations: json['regulations'] != null 
          ? CountryRegulations.fromJson(json['regulations'])
          : null,
    );
  }

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'callingCode': callingCode,
      'currency': currency,
      'status': status,
      'priority': priority,
      'operatorCount': operatorCount,
      'paymentOptions': paymentOptions,
      'flagEmoji': flagEmoji,
      'languages': languages,
      'timeZone': timeZone,
      'estimatedPopulation': estimatedPopulation,
      'operators': operators?.map((key, value) => MapEntry(key, value.toJson())),
      'regulations': regulations?.toJson(),
    };
  }

  /// Vérifier si le pays supporte une fonctionnalité
  bool supportsFeature(String feature) {
    switch (feature) {
      case 'basic':
        return ['active', 'beta', 'planned'].contains(status);
      case 'payments':
        return ['active', 'beta'].contains(status);
      case 'verification':
        return ['active', 'beta'].contains(status);
      case 'full':
        return status == 'active';
      default:
        return false;
    }
  }

  /// Obtenir la couleur de statut
  String get statusColor {
    switch (status) {
      case 'active':
        return '#4CAF50'; // Vert
      case 'beta':
        return '#FF9800'; // Orange
      case 'planned':
        return '#2196F3'; // Bleu
      default:
        return '#9E9E9E'; // Gris
    }
  }

  /// Obtenir le libellé de statut localisé
  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'beta':
        return 'Bêta';
      case 'planned':
        return 'Planifié';
      default:
        return 'Inconnu';
    }
  }

  /// Copier avec modifications
  CountryInfo copyWith({
    String? code,
    String? name,
    String? callingCode,
    String? currency,
    String? status,
    int? priority,
    int? operatorCount,
    int? paymentOptions,
    String? flagEmoji,
    List<String>? languages,
    String? timeZone,
    int? estimatedPopulation,
    Map<String, OperatorInfo>? operators,
    CountryRegulations? regulations,
  }) {
    return CountryInfo(
      code: code ?? this.code,
      name: name ?? this.name,
      callingCode: callingCode ?? this.callingCode,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      operatorCount: operatorCount ?? this.operatorCount,
      paymentOptions: paymentOptions ?? this.paymentOptions,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      languages: languages ?? this.languages,
      timeZone: timeZone ?? this.timeZone,
      estimatedPopulation: estimatedPopulation ?? this.estimatedPopulation,
      operators: operators ?? this.operators,
      regulations: regulations ?? this.regulations,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryInfo && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() {
    return 'CountryInfo(code: $code, name: $name, callingCode: $callingCode)';
  }
}

/// Informations sur un opérateur télécom
class OperatorInfo {
  /// Nom de l'opérateur
  final String name;
  
  /// Préfixes des numéros
  final List<String> prefixes;
  
  /// Services supportés
  final List<String> services;
  
  /// Part de marché (0.0 à 1.0)
  final double marketShare;
  
  /// Fiabilité (0.0 à 1.0)
  final double reliability;
  
  /// Endpoint API (optionnel)
  final String? apiEndpoint;
  
  /// Frais de transaction
  final OperatorFees? fees;
  
  /// Statut de l'opérateur
  final String? status;

  const OperatorInfo({
    required this.name,
    required this.prefixes,
    required this.services,
    this.marketShare = 0.0,
    this.reliability = 0.0,
    this.apiEndpoint,
    this.fees,
    this.status,
  });

  factory OperatorInfo.fromJson(Map<String, dynamic> json) {
    return OperatorInfo(
      name: json['name'] ?? '',
      prefixes: List<String>.from(json['prefixes'] ?? []),
      services: List<String>.from(json['services'] ?? []),
      marketShare: (json['marketShare'] ?? 0.0).toDouble(),
      reliability: (json['reliability'] ?? 0.0).toDouble(),
      apiEndpoint: json['apiEndpoint'],
      fees: json['fees'] != null ? OperatorFees.fromJson(json['fees']) : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'prefixes': prefixes,
      'services': services,
      'marketShare': marketShare,
      'reliability': reliability,
      'apiEndpoint': apiEndpoint,
      'fees': fees?.toJson(),
      'status': status,
    };
  }
}

/// Frais d'un opérateur
class OperatorFees {
  /// Frais minimum (pourcentage)
  final double min;
  
  /// Frais maximum (pourcentage)
  final double max;

  const OperatorFees({
    required this.min,
    required this.max,
  });

  factory OperatorFees.fromJson(Map<String, dynamic> json) {
    return OperatorFees(
      min: (json['min'] ?? 0.0).toDouble(),
      max: (json['max'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
    };
  }
}

/// Réglementations d'un pays
class CountryRegulations {
  /// Montant maximum par transaction
  final int? maxTransactionAmount;
  
  /// Limite quotidienne
  final int? dailyLimit;
  
  /// Limite mensuelle
  final int? monthlyLimit;
  
  /// KYC requis
  final bool kycRequired;
  
  /// Niveau anti-blanchiment
  final String? antiMoneyLaundering;
  
  /// Taxe sur les transactions
  final double? taxOnTransactions;
  
  /// Licences requises
  final List<String> licenses;
  
  /// Exigences spéciales
  final List<String>? specialRequirements;

  const CountryRegulations({
    this.maxTransactionAmount,
    this.dailyLimit,
    this.monthlyLimit,
    this.kycRequired = false,
    this.antiMoneyLaundering,
    this.taxOnTransactions,
    this.licenses = const [],
    this.specialRequirements,
  });

  factory CountryRegulations.fromJson(Map<String, dynamic> json) {
    return CountryRegulations(
      maxTransactionAmount: json['maxTransactionAmount'],
      dailyLimit: json['dailyLimit'],
      monthlyLimit: json['monthlyLimit'],
      kycRequired: json['kycRequired'] ?? false,
      antiMoneyLaundering: json['antiMoneyLaundering'],
      taxOnTransactions: json['taxOnTransactions']?.toDouble(),
      licenses: List<String>.from(json['licenses'] ?? []),
      specialRequirements: json['specialRequirements'] != null 
          ? List<String>.from(json['specialRequirements'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxTransactionAmount': maxTransactionAmount,
      'dailyLimit': dailyLimit,
      'monthlyLimit': monthlyLimit,
      'kycRequired': kycRequired,
      'antiMoneyLaundering': antiMoneyLaundering,
      'taxOnTransactions': taxOnTransactions,
      'licenses': licenses,
      'specialRequirements': specialRequirements,
    };
  }
}

/// Résultat de la vérification de support d'un pays
class CountrySupportResult {
  /// Code du pays
  final String countryCode;
  
  /// Fonctionnalité vérifiée
  final String feature;
  
  /// Le pays supporte-t-il la fonctionnalité
  final bool isSupported;
  
  /// Niveau de support
  final String supportLevel;
  
  /// Détails supplémentaires
  final Map<String, dynamic>? details;

  const CountrySupportResult({
    required this.countryCode,
    required this.feature,
    required this.isSupported,
    required this.supportLevel,
    this.details,
  });

  factory CountrySupportResult.fromJson(Map<String, dynamic> json) {
    return CountrySupportResult(
      countryCode: json['countryCode'] ?? '',
      feature: json['feature'] ?? '',
      isSupported: json['isSupported'] ?? false,
      supportLevel: json['supportLevel'] ?? 'unsupported',
      details: json['details'],
    );
  }
}
