class Country {
  final String code;
  final String name;
  final String phoneCode;
  
  const Country({
    required this.code, 
    required this.name, 
    required this.phoneCode
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
  }) {
    return Country(
      code: code ?? this.code,
      name: name ?? this.name,
      phoneCode: phoneCode ?? this.phoneCode,
    );
  }
  
  // Conversion de l'objet en Map
  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'phoneCode': phoneCode,
    };
  }
  
  // Création d'un objet à partir d'une Map
  factory Country.fromMap(Map<String, dynamic> map) {
    return Country(
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phoneCode: map['phoneCode']?.toString() ?? '',
    );
  }
} 