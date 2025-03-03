import 'package:flutter/material.dart';

/// Classe utilitaire pour gérer la réactivité de l'application
class ResponsiveUtils {
  /// Tailles d'écran pour les différents appareils
  static const double mobileSmallBreakpoint = 320;
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;

  /// Vérifie si l'écran est un petit mobile (< 320px)
  static bool isMobileSmall(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileSmallBreakpoint;
  }

  /// Vérifie si l'écran est un mobile (< 480px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Vérifie si l'écran est une tablette (< 768px)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint &&
        MediaQuery.of(context).size.width >= mobileBreakpoint;
  }

  /// Vérifie si l'écran est un desktop (>= 1024px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Retourne la valeur adaptée en fonction de la taille de l'écran
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T defaultValue,
    T? mobileSmallValue,
    T? mobileValue,
    T? tabletValue,
    T? desktopValue,
  }) {
    if (isDesktop(context) && desktopValue != null) {
      return desktopValue;
    }
    if (isTablet(context) && tabletValue != null) {
      return tabletValue;
    }
    if (isMobile(context) && mobileValue != null) {
      return mobileValue;
    }
    if (isMobileSmall(context) && mobileSmallValue != null) {
      return mobileSmallValue;
    }
    return defaultValue;
  }

  /// Retourne une valeur de padding adaptée en fonction de la taille de l'écran
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return getResponsiveValue<EdgeInsets>(
      context: context,
      defaultValue: const EdgeInsets.all(16.0),
      mobileSmallValue: const EdgeInsets.all(8.0),
      mobileValue: const EdgeInsets.all(12.0),
      tabletValue: const EdgeInsets.all(16.0),
      desktopValue: const EdgeInsets.all(24.0),
    );
  }

  /// Retourne une valeur de marge adaptée en fonction de la taille de l'écran
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    return getResponsiveValue<EdgeInsets>(
      context: context,
      defaultValue: const EdgeInsets.all(16.0),
      mobileSmallValue: const EdgeInsets.all(8.0),
      mobileValue: const EdgeInsets.all(12.0),
      tabletValue: const EdgeInsets.all(16.0),
      desktopValue: const EdgeInsets.all(24.0),
    );
  }

  /// Retourne une taille de police adaptée en fonction de la taille de l'écran
  static double getResponsiveFontSize(
    BuildContext context, {
    required double defaultSize,
  }) {
    return getResponsiveValue<double>(
      context: context,
      defaultValue: defaultSize,
      mobileSmallValue: defaultSize * 0.8,
      mobileValue: defaultSize * 0.9,
      tabletValue: defaultSize,
      desktopValue: defaultSize * 1.1,
    );
  }

  /// Retourne une hauteur adaptée en fonction de la taille de l'écran
  static double getResponsiveHeight(
    BuildContext context, {
    required double defaultHeight,
  }) {
    return getResponsiveValue<double>(
      context: context,
      defaultValue: defaultHeight,
      mobileSmallValue: defaultHeight * 0.7,
      mobileValue: defaultHeight * 0.8,
      tabletValue: defaultHeight,
      desktopValue: defaultHeight * 1.2,
    );
  }

  /// Retourne une largeur adaptée en fonction de la taille de l'écran
  static double getResponsiveWidth(
    BuildContext context, {
    required double defaultWidth,
  }) {
    return getResponsiveValue<double>(
      context: context,
      defaultValue: defaultWidth,
      mobileSmallValue: defaultWidth * 0.7,
      mobileValue: defaultWidth * 0.8,
      tabletValue: defaultWidth,
      desktopValue: defaultWidth * 1.2,
    );
  }
}

/// Extension sur BuildContext pour faciliter l'accès aux méthodes responsives
extension ResponsiveContext on BuildContext {
  bool get isMobileSmall => ResponsiveUtils.isMobileSmall(this);
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  
  EdgeInsets get responsivePadding => ResponsiveUtils.getResponsivePadding(this);
  EdgeInsets get responsiveMargin => ResponsiveUtils.getResponsiveMargin(this);
  
  double responsiveFontSize(double defaultSize) => 
      ResponsiveUtils.getResponsiveFontSize(this, defaultSize: defaultSize);
      
  double responsiveHeight(double defaultHeight) => 
      ResponsiveUtils.getResponsiveHeight(this, defaultHeight: defaultHeight);
      
  double responsiveWidth(double defaultWidth) => 
      ResponsiveUtils.getResponsiveWidth(this, defaultWidth: defaultWidth);
}
