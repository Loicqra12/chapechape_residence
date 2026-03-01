/// Classe utilitaire pour centraliser tous les chemins d'images de l'application
class AppImages {
  AppImages._();

  // Base paths
  static const String _basePath = 'assets/images';
  static const String _logoPath = '$_basePath/logo';
  static const String _onboardingPath = '$_basePath/onboarding';
  static const String _placeholdersPath = '$_basePath/placeholders';
  static const String _backgroundsPath = '$_basePath/backgrounds';
  static const String _illustrationsPath = '$_basePath/illustrations';

  // Logo Images
  static const String logoPrimary = '$_logoPath/logo_primary.png';
  static const String logoPrimarySvg = '$_logoPath/logo_primary.svg';
  static const String logoLight = '$_logoPath/logo_light.png';
  static const String logoDark = '$_logoPath/logo_dark.png';
  static const String appIcon = '$_logoPath/app_icon.png';
  static const String favicon = '$_logoPath/favicon.ico';

  // Onboarding Images
  static const String onboarding1 = '$_onboardingPath/onboarding_1.png';
  static const String onboarding2 = '$_onboardingPath/onboarding_2.png';
  static const String onboarding3 = '$_onboardingPath/onboarding_3.png';

  // Placeholder Images
  static const String residencePlaceholder = '$_placeholdersPath/residence_placeholder.png';
  static const String defaultResidence = '$_basePath/default_residence.jpg';
  static const String profilePlaceholder = '$_placeholdersPath/profile_placeholder.png';
  static const String errorPlaceholder = '$_placeholdersPath/error_placeholder.png';

  // Illustrations
  static const String emptyConnexion = '$_illustrationsPath/empty_connexion.png';
  static const String emptyRegister = '$_illustrationsPath/empty_register.png';
  static const String emptyError = '$_illustrationsPath/empty_error.png';

  // Background Images
  static const String patternLight = '$_backgroundsPath/pattern_light.svg';
  static const String patternDark = '$_backgroundsPath/pattern_dark.svg';
  static const String gradientPrimary = '$_backgroundsPath/gradient_primary.svg';
  static const String textureLight = '$_backgroundsPath/texture_light.svg';
  static const String textureDark = '$_backgroundsPath/texture_dark.svg';

  /// Retourne l'image de placeholder appropriée pour une résidence
  static String getResidencePlaceholder({bool isDarkMode = false}) {
    return residencePlaceholder;
  }

  /// Retourne l'image de placeholder appropriée pour un profil
  static String getProfilePlaceholder({bool isDarkMode = false}) {
    return profilePlaceholder;
  }

  /// Retourne le logo approprié en fonction du mode (clair/sombre)
  static String getLogo({bool isDarkMode = false}) {
    return isDarkMode ? logoDark : logoLight;
  }

  /// Retourne le motif d'arrière-plan approprié en fonction du mode (clair/sombre)
  static String getPattern({bool isDarkMode = false}) {
    return isDarkMode ? patternDark : patternLight;
  }

  /// Retourne la texture d'arrière-plan appropriée en fonction du mode (clair/sombre)
  static String getTexture({bool isDarkMode = false}) {
    return isDarkMode ? textureDark : textureLight;
  }

  /// Liste des images d'onboarding dans l'ordre
  static List<String> get onboardingImages => [
    onboarding1,
    onboarding2,
    onboarding3,
  ];
}
