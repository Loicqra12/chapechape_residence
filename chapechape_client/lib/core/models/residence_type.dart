import '../constants/app_assets.dart';

// Extensions pour ResidenceType
extension ResidenceTypeFeatures on ResidenceType {
  bool get isVacationResidence {
    return this == ResidenceType.villa || 
           this == ResidenceType.bungalow || 
           this == ResidenceType.luxury;
  }
  
  bool get isSpecialResidence {
    return this == ResidenceType.hotel || 
           this == ResidenceType.luxury;
  }
  
  bool get isStudentResidence {
    return this == ResidenceType.studio;
  }
  
  bool get isCoworkingSpace {
    return false; // À implémenter si nécessaire
  }
}
