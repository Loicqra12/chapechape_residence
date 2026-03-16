/// Configuration Google Sign-In.
/// Un seul projet Firebase (chapchapresi / 39884732136) est utilisé pour dev ET prod.
/// Le SHA-1 du certificat Play App Signing doit être enregistré dans ce projet Firebase.
class GoogleAuthConfig {
  /// Web Client ID du projet Firebase (chapchapresi / 39884732136).
  /// Utilisé aussi bien en dev (keystore debug) qu'en prod (keystore release / Play App Signing).
  static const String webClientIdDev =
      '39884732136-952k7nbb1gucreafp9h33pmq4m5mnfu5.apps.googleusercontent.com';

  /// Prod utilise le même projet Firebase → même Web Client ID.
  /// NB: le SHA-1 Play App Signing doit être ajouté dans Firebase Console > chapchapresi.
  static const String webClientIdProd =
      '39884732136-952k7nbb1gucreafp9h33pmq4m5mnfu5.apps.googleusercontent.com';

  /// Alias unique (toujours le même projet).
  static const String webClientId = webClientIdProd;

  static const List<String> scopes = ['email', 'profile'];
}
