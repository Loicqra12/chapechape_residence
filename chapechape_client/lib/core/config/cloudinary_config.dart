/// Configuration pour l'intégration Cloudinary
/// 
/// Ce fichier contient les identifiants et paramètres nécessaires
/// pour interagir avec l'API Cloudinary.
class CloudinaryConfig {
  // Identifiants Cloudinary
  static const String cloudName = 'djeares5m';
  static const String apiKey = '425526277812378';
  static const String apiSecret = 'ZibUaqw61QA1kCoJoiNTeMoRGpI';
  static const String uploadPreset = 'ml_default'; // Utiliser votre preset ou 'ml_default' par défaut
  
  // URLs complètes
  static const String cloudinaryUrl = 'cloudinary://425526277812378:ZibUaqw61QA1kCoJoiNTeMoRGpI@djeares5m';
  
  // Structure de dossiers recommandée
  static const String residencesFolder = 'chapechape/residences';
  static const String profilesFolder = 'chapechape/profiles';
  static const String documentsFolder = 'chapechape/documents';
}
