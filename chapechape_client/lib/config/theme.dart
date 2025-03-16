import 'package:flutter/material.dart';

/// Classe définissant le thème global de l'application ChapeChape Residence
class AppTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF1A73E8);
  static const Color secondaryColor = Color(0xFF34A853);
  static const Color accentColor = Color(0xFFFFA000);
  
  // Couleurs neutres
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFEEEEEE);
  
  // Couleurs de texte
  static const Color textPrimaryColor = Color(0xFF202124);
  static const Color textSecondaryColor = Color(0xFF5F6368);
  static const Color textTertiaryColor = Color(0xFF9AA0A6);
  
  // Couleurs d'état
  static const Color successColor = Color(0xFF34A853);
  static const Color warningColor = Color(0xFFFFA000);
  static const Color errorColor = Color(0xFFEA4335);
  static const Color infoColor = Color(0xFF4285F4);
  
  // Couleurs de statut de réservation
  static const Color pendingColor = Color(0xFFFFA000);
  static const Color confirmedColor = Color(0xFF34A853);
  static const Color cancelledColor = Color(0xFFEA4335);
  static const Color completedColor = Color(0xFF4285F4);

  // Rayons d'arrondi
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  // Espacement
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Élévation
  static const double elevationSmall = 1.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  
  // Style de bouton principal
  static ButtonStyle primaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(primaryColor),
    foregroundColor: MaterialStateProperty.all(Colors.white),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
      ),
    ),
  );
  
  // Style de bouton secondaire
  static ButtonStyle secondaryButtonStyle = ButtonStyle(
    backgroundColor: MaterialStateProperty.all(Colors.white),
    foregroundColor: MaterialStateProperty.all(primaryColor),
    padding: MaterialStateProperty.all(
      const EdgeInsets.symmetric(horizontal: spacingL, vertical: spacingM),
    ),
    shape: MaterialStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusMedium),
        side: const BorderSide(color: primaryColor),
      ),
    ),
  );
  
  // Style de carte
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Retourne le thème complet pour l'application
  static ThemeData themeData() {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        error: errorColor,
        onError: Colors.white,
        background: backgroundColor,
        onBackground: textPrimaryColor,
        surface: cardColor,
        onSurface: textPrimaryColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: elevationSmall,
        margin: const EdgeInsets.all(spacingS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: primaryButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: secondaryButtonStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all(primaryColor),
          textStyle: MaterialStateProperty.all(
            const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: errorColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(spacingM),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        headlineSmall: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: textSecondaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textTertiaryColor,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: spacingM,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return textTertiaryColor;
            }
            if (states.contains(MaterialState.selected)) {
              return primaryColor;
            }
            return Colors.transparent;
          },
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        side: const BorderSide(color: textTertiaryColor),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondaryColor,
        indicatorColor: primaryColor,
        labelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textTertiaryColor,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        elevation: elevationMedium,
      ),
    );
  }
  
  // Méthode pour obtenir la couleur en fonction du statut d'une réservation
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pendingColor;
      case 'confirmed':
        return confirmedColor;
      case 'cancelled':
        return cancelledColor;
      case 'completed':
        return completedColor;
      default:
        return infoColor;
    }
  }
} 