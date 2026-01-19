import 'package:flutter/material.dart';
import 'colors.dart';

/// Styles de texte avec police Poppins et échelle typographique cohérente (ratio 1.25)
/// 
/// Échelle: 10 → 12 → 14 → 16 → 20 → 24 → 30 → 36
class AppTextStyles {
  // Police de base
  static const String _fontFamily = 'Poppins';

  // ═══════════════════════════════════════════════════════════════════════════
  // CAPTION - 10px (textes très petits, labels secondaires)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const captionMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SMALL - 12px (labels, badges, hints)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const small = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const smallMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const smallBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY - 14px (texte principal, paragraphes)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodyBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // Alias pour compatibilité avec l'ancien code
  static const regular = body;
  static const regularBold = bodyBold;

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY LARGE - 16px (texte mis en avant)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodyLargeMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const bodyLargeBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // Alias pour compatibilité
  static const medium = bodyLarge;
  static const mediumBold = bodyLargeBold;

  // ═══════════════════════════════════════════════════════════════════════════
  // SUBTITLE - 18px (sous-titres de sections)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const subtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const subtitleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const subtitleBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Alias pour compatibilité
  static const large = subtitle;
  static const largeBold = subtitleBold;

  // ═══════════════════════════════════════════════════════════════════════════
  // TITLE - 20px (titres de cards, sections)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const titleSmallBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TITLE MEDIUM - 24px (titres de pages)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const title = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  static const titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADLINE - 30px (titres importants)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const headline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY - 36px (très grands titres, splash, hero)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  static const displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w700,
    height: 1.1,
    color: AppColors.textPrimary,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // STYLES UTILITAIRES
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Style pour les boutons
  static const button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  /// Style pour les liens
  static const link = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    decoration: TextDecoration.underline,
    color: AppColors.primary,
  );

  /// Style pour les erreurs
  static const error = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.error,
  );

  /// Style pour les prix
  static const price = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: AppColors.primary,
  );

  /// Style pour les badges/tags
  static const tag = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  // Ancien alias (tiny) pour compatibilité
  static const tiny = caption;
}
