/// Config Cloudinary côté app — cloud name public uniquement.
/// Upload via signature serveur (`GET /api/media/cloudinary-signature`).
/// Jamais d'api_secret ni d'upload_preset unsigned dans le binaire.
class CloudinaryConfig {
  static const String cloudName = 'djeares5m';

  static const String residencesFolder = 'chapechape/residences';
  static const String profilesFolder = 'chapechape/profiles';
  static const String documentsFolder = 'chapechape/documents';
}
