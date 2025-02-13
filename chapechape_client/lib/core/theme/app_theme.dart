import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryGold = Color(0xFFD4AF37);  // Or royal
  static const Color secondaryGold = Color(0xFFFFD700); // Or plus vif
  static const Color lightGold = Color(0xFFFFF5E1);    // Or très clair pour les fonds
  
  // Couleurs complémentaires
  static const Color darkBlue = Color(0xFF1A237E);     // Bleu profond pour le contraste
  static const Color cream = Color(0xFFFFFAF0);        // Crème pour les fonds
  static const Color charcoal = Color(0xFF2F4F4F);     // Gris foncé pour le texte
  
  // Couleurs de support
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1976D2);

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
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: charcoal,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: charcoal,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: charcoal,
    letterSpacing: 0.2,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: charcoal,
    letterSpacing: 0.1,
  );

  // Styles de boutons
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
    backgroundColor: primaryGold,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 0,
  );

  static ButtonStyle get outlinedButton => OutlinedButton.styleFrom(
    foregroundColor: primaryGold,
    side: const BorderSide(color: primaryGold),
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
    fillColor: cream,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: lightGold),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: primaryGold, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
