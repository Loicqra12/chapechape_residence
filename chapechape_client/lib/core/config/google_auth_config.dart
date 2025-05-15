class GoogleAuthConfig {
  // ID client OAuth pour Android
  static const String androidClientId = '150162865149-m6q57o1f68t73o8lfiumb0671qcj55da.apps.googleusercontent.com';
  
  // ID client OAuth pour Web (si nécessaire ultérieurement)
  static const String webClientId = '150162865149-m6q57o1f68t73o8lfiumb0671qcj55da.apps.googleusercontent.com';
  
  // Scopes demandés (champs d'accès)
  static const List<String> scopes = [
    'email',
    'profile',
  ];
}
