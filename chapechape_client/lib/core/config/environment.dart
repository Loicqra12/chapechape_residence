/// Enumération des différents environnements d'exécution
enum Environment {
  /// Environnement de développement (local)
  dev,
  
  /// Environnement de préproduction (staging)
  staging,
  
  /// Environnement de production
  prod;
  
  /// Nom de l'environnement en format lisible
  String get displayName {
    switch (this) {
      case Environment.dev:
        return 'Développement';
      case Environment.staging:
        return 'Préproduction';
      case Environment.prod:
        return 'Production';
    }
  }
  
  /// Préfixe à utiliser pour les logs
  String get logPrefix {
    switch (this) {
      case Environment.dev:
        return '[DEV]';
      case Environment.staging:
        return '[STAGING]';
      case Environment.prod:
        return '[PROD]';
    }
  }
  
  /// Indique si cet environnement est considéré comme "debug"
  bool get isDebug {
    return this != Environment.prod;
  }
}
