import 'package:flutter/material.dart';

/// Thème unifié pour l'application ChapéChapé Residence
/// Combine les éléments des trois fichiers de thème précédents
/// en privilégiant une palette de couleurs or/noir élégante
class AppTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFFD4AF37);  // Or royal
  static const Color secondaryColor = Color(0xFFFFD700); // Or plus vif
  static const Color accentColor = Color(0xFF1A1A1A);   // Noir
  static const Color backgroundColor = Color(0xFFFFFAF0); // Crème pour les fonds
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF1A1A1A);   // Noir
  static const Color textSecondary = Color(0xFF666666); // Gris
  static const Color textLight = Color(0xFFFFFFFF);     // Blanc
  
  // Couleurs de support
  static const Color successColor = Color(0xFF4CAF50);  // Vert
  static const Color errorColor = Color(0xFFD32F2F);    // Rouge
  static const Color warningColor = Color(0xFFFFA000);  // Orange
  static const Color infoColor = Color(0xFF1976D2);     // Bleu
  static const Color dividerColor = Color(0xFFE0E0E0);  // Gris clair

  // Couleurs spéciales
  static const Color lightGold = Color(0xFFFFF5E1);     // Or très clair pour les fonds
  static const Color darkGold = Color(0xFFB8860B);      // Or foncé
  
  // Gradients
  static const LinearGradient goldGradient = LinearGradient(
    colors: [
      Color(0xFFD4AF37),
      Color(0xFFFFD700),
      Color(0xFFD4AF37),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Ombres
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  // Styles de texte
  static TextStyle get headingLarge => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.5,
  );

  static TextStyle get headingMedium => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    letterSpacing: -0.3,
  );

  static TextStyle get headingSmall => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 18,
    color: textPrimary,
    letterSpacing: 0.2,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    color: textPrimary,
    letterSpacing: 0.1,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: textPrimary,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 12,
    color: textSecondary,
  );

  static TextStyle get button => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textLight,
  );

  static TextStyle get errorTextStyle => TextStyle(
    fontFamily: 'Poppins',
    fontSize: 14,
    color: errorColor,
    fontWeight: FontWeight.w500,
  );

  // Styles de boutons
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: textPrimary,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
    backgroundColor: accentColor,
    foregroundColor: textLight,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );

  static ButtonStyle get outlinedGoldButton => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Styles de cartes
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: softShadow,
    border: Border.all(
      color: lightGold,
      width: 1,
    ),
  );

  // Styles d'input
  static InputDecoration get inputDecoration => InputDecoration(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: dividerColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: dividerColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: errorColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );

  // Thème clair
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: Colors.white,
        background: backgroundColor,
        error: errorColor,
        onPrimary: textPrimary,
        onSecondary: textPrimary,
        onTertiary: textLight,
        onSurface: textPrimary,
        onBackground: textPrimary,
        onError: textLight,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Poppins'),
        headlineMedium: TextStyle(fontFamily: 'Poppins'),
        headlineSmall: TextStyle(fontFamily: 'Poppins'),
        bodyLarge: TextStyle(fontFamily: 'Poppins'),
        bodyMedium: TextStyle(fontFamily: 'Poppins'),
        bodySmall: TextStyle(fontFamily: 'Poppins'),
        labelSmall: TextStyle(fontFamily: 'Poppins'),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textPrimary),
        titleTextStyle: headingMedium,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.white;
        }),
        side: const BorderSide(color: dividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return dividerColor;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return dividerColor;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: dividerColor,
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: textSecondary,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  // Thème sombre
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: accentColor,
        surface: const Color(0xFF2C2C2C),
        background: const Color(0xFF1A1A1A),
        error: errorColor,
        onPrimary: textLight,
        onSecondary: textLight,
        onTertiary: textLight,
        onSurface: textLight,
        onBackground: textLight,
        onError: textLight,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Poppins'),
        headlineMedium: TextStyle(fontFamily: 'Poppins'),
        headlineSmall: TextStyle(fontFamily: 'Poppins'),
        bodyLarge: TextStyle(fontFamily: 'Poppins'),
        bodyMedium: TextStyle(fontFamily: 'Poppins'),
        bodySmall: TextStyle(fontFamily: 'Poppins'),
        labelSmall: TextStyle(fontFamily: 'Poppins'),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textLight),
        titleTextStyle: headingMedium.copyWith(color: textLight),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textPrimary,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3E3E3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF2C2C2C),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF2C2C2C),
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFFAAAAAA),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3E3E3E),
        thickness: 1,
        space: 1,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return const Color(0xFF3E3E3E);
        }),
        side: const BorderSide(color: Color(0xFF3E3E3E)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return const Color(0xFF3E3E3E);
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor;
          }
          return Colors.white;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.5);
          }
          return const Color(0xFF3E3E3E);
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: const Color(0xFF3E3E3E),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withOpacity(0.2),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primaryColor,
        unselectedLabelColor: const Color(0xFFAAAAAA),
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: primaryColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
