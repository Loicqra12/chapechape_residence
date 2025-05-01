class Country {
  final String code;
  final String name;
  final String phoneCode;
  
  /// Capitale du pays
  final String? capital;
  
  /// URL du drapeau du pays
  final String? flagUrl;
  
  /// Nombre de régions dans le pays
  final int? regionCount;
  
  /// Liste des langues officielles
  final List<String>? languages;
  
  /// Devise du pays
  final String? currency;
  
  /// Informations additionnelles
  final Map<String, dynamic>? additionalInfo;
  
  const Country({
    required this.code, 
    required this.name, 
    required this.phoneCode,
    this.capital,
    this.flagUrl,
    this.regionCount,
    this.languages,
    this.currency,
    this.additionalInfo,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
  
  // Création d'une copie de l'objet avec des valeurs modifiées
  Country copyWith({
    String? code,
    String? name,
    String? phoneCode,
    String? capital,
    String? flagUrl,
    int? regionCount,
    List<String>? languages,
    String? currency,
    Map<String, dynamic>? additionalInfo,
  }) {
    return Country(
      code: code ?? this.code,
      name: name ?? this.name,
      phoneCode: phoneCode ?? this.phoneCode,
      capital: capital ?? this.capital,
      flagUrl: flagUrl ?? this.flagUrl,
      regionCount: regionCount ?? this.regionCount,
      languages: languages ?? this.languages,
      currency: currency ?? this.currency,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
  
  // Conversion de l'objet en Map
  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'phoneCode': phoneCode,
      'capital': capital,
      'flagUrl': flagUrl,
      'regionCount': regionCount,
      'languages': languages,
      'currency': currency,
      'additionalInfo': additionalInfo,
    };
  }
  
  // Création d'un objet à partir d'une Map
  factory Country.fromJson(Map<String, dynamic> map) {
    return Country(
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phoneCode: map['phoneCode']?.toString() ?? '',
      capital: map['capital'] as String?,
      flagUrl: map['flagUrl'] as String?,
      regionCount: map['regionCount'] as int?,
      languages: map['languages'] != null ? List<String>.from(map['languages']) : null,
      currency: map['currency'] as String?,
      additionalInfo: map['additionalInfo'] as Map<String, dynamic>?,
    );
  }
  
  // Alias pour compatibilité avec l'ancien code
  Map<String, dynamic> toMap() => toJson();
  factory Country.fromMap(Map<String, dynamic> map) => Country.fromJson(map);
}