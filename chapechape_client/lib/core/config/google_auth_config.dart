/// Configuration Google Sign-In : IDs différents selon l'environnement (dev vs prod).
/// En dev, l'app utilise le keystore debug → il faut le Web Client ID du projet
/// dans google-services.json. En prod, le Web Client ID du projet Firebase de production.
class GoogleAuthConfig {
  /// Web Client ID du projet Firebase dans google-services.json (chapchapresi / 39884732136).
  /// Utilisé en dev pour que Google Sign-In fonctionne avec le certificat debug.
  static const String webClientIdDev =
      '39884732136-952k7nbb1gucreafp9h33pmq4m5mnfu5.apps.googleusercontent.com';

  /// Web Client ID du projet Firebase de production (150162865149).
  /// Utilisé en prod ; le SHA-1 du keystore release doit être enregistré dans ce projet.
  static const String webClientIdProd =
      '150162865149-m6q57o1f68t73o8lfiumb0671qcj55da.apps.googleusercontent.com';

  /// Rétrocompatibilité : égal à webClientIdProd (comportement par défaut si pas d'env).
  static const String webClientId = webClientIdProd;

  static const List<String> scopes = ['email', 'profile'];
}
