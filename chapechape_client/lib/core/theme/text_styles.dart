import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Styles de texte unifiés pour l'application ChapeChape Client
/// Utilise la police Poppins avec une échelle typographique harmonieuse (ratio 1.25)
/// et des line-heights optimisées pour la lisibilité
class AppTextStyles {
  static const String _fontFamily = 'Poppins';

  /// Style pour les textes très petits (captions, labels)
  /// 12px / 1.5 line-height / Poppins-Regular
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5, // line-height
    color: AppTheme.textSecondary,
  );

  /// Style pour les textes petits (body small)
  /// 14px / 1.5 line-height / Poppins-Regular
  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppTheme.textPrimary,
  );

  /// Style pour les textes de corps standard (body medium)
  /// 16px / 1.5 line-height / Poppins-Medium
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppTheme.textPrimary,
  );

  /// Style pour les sous-titres
  /// 18px / 1.4 line-height / Poppins-SemiBold
  static const TextStyle subtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppTheme.textPrimary,
  );

  /// Style pour les titres moyens (sections)
  /// 20px / 1.3 line-height / Poppins-SemiBold (600)
  /// Couleur: #1A1A1A (noir strict, pas de doré)
  static const TextStyle title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600, // SemiBold au lieu de Bold
    height: 1.3,
    color: Color(0xFF1A1A1A), // Noir strict #1A1A1A
  );

  /// Style pour les titres grands (headlines)
  /// 28px / 1.2 line-height / Poppins-Bold
  static const TextStyle headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppTheme.textPrimary,
  );

  /// Style pour les titres très grands (display)
  /// 36px / 1.1 line-height / Poppins-Bold
  static const TextStyle display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.1,
    color: AppTheme.textPrimary,
  );

  /// Style pour les boutons
  /// 16px / 1.5 line-height / Poppins-SemiBold
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppTheme.textLight,
  );

  /// Style pour les liens
  /// 14px / 1.5 line-height / Poppins-Medium
  static const TextStyle link = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppTheme.primaryColor,
    decoration: TextDecoration.underline,
  );

  /// Style pour les messages d'erreur
  /// 14px / 1.5 line-height / Poppins-Medium
  static const TextStyle error = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppTheme.errorColor,
  );

  /// Style pour les prix
  /// 16px / 1.5 line-height / Poppins-Bold
  static const TextStyle price = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.5,
    color: AppTheme.primaryColor,
  );

  /// Style pour les tags/badges
  /// 12px / 1.5 line-height / Poppins-SemiBold
  static const TextStyle tag = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: AppTheme.textPrimary,
  );
}
