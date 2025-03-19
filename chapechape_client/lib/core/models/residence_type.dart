import '../constants/app_assets.dart';

// Extensions pour ResidenceType
extension ResidenceTypeFeatures on ResidenceType {
  // Ces méthodes sont désormais définies dans ResidenceTypeExtension dans app_assets.dart
  // Pour éviter les ambiguïtés, nous utilisons des noms différents ou les commentons
  
  // Version obsolète - utiliser la version dans ResidenceTypeExtension
  // bool get isVacationResidence {
  //   return this == ResidenceType.villa || 
  //          this == ResidenceType.bungalow || 
  //          this == ResidenceType.luxury;
  // }
  
  // Version obsolète - utiliser la version dans ResidenceTypeExtension
  // bool get isSpecialResidence {
  //   return this == ResidenceType.hotel || 
  //          this == ResidenceType.luxury;
  // }
  
  // Méthodes supplémentaires qui ne sont pas dans ResidenceTypeExtension
  bool get isStudentResidence {
    return this == ResidenceType.studio ||
           this == ResidenceType.residenceUniversitaire ||
           this == ResidenceType.citeDortoir;
  }
  
  bool get isCoworkingSpace {
    return this == ResidenceType.coworking;
  }
}
