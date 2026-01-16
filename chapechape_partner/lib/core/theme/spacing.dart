import 'package:flutter/material.dart';

/// Système d'espacements cohérent pour l'application
/// 
/// Basé sur une échelle de 4px (4, 8, 12, 16, 24, 32, 48, 64)
class AppSpacing {
  AppSpacing._();

  // ═══════════════════════════════════════════════════════════════════════════
  // VALEURS DE BASE
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// 4px - Micro spacing (entre icônes et texte)
  static const double xs = 4.0;
  
  /// 8px - Small spacing (entre éléments liés)
  static const double sm = 8.0;
  
  /// 12px - Small-medium spacing
  static const double smd = 12.0;
  
  /// 16px - Medium spacing (standard)
  static const double md = 16.0;
  
  /// 20px - Medium-large spacing
  static const double mlg = 20.0;
  
  /// 24px - Large spacing (entre sections)
  static const double lg = 24.0;
  
  /// 32px - Extra large spacing
  static const double xl = 32.0;
  
  /// 48px - XXL spacing (entre grandes sections)
  static const double xxl = 48.0;
  
  /// 64px - XXXL spacing (marges de page)
  static const double xxxl = 64.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // PADDING PRESETS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Padding standard pour les pages
  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  
  /// Padding horizontal pour les pages
  static const EdgeInsets pageHorizontal = EdgeInsets.symmetric(horizontal: md);
  
  /// Padding pour les cards
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  
  /// Padding compact pour les cards
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(smd);
  
  /// Padding pour les boutons
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: smd,
  );
  
  /// Padding pour les champs de texte
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: smd,
  );
  
  /// Padding pour les ListTile
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // SIZED BOX PRESETS (pour éviter de créer des SizedBox partout)
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// SizedBox horizontal 4px
  static const SizedBox horizontalXs = SizedBox(width: xs);
  
  /// SizedBox horizontal 8px
  static const SizedBox horizontalSm = SizedBox(width: sm);
  
  /// SizedBox horizontal 16px
  static const SizedBox horizontalMd = SizedBox(width: md);
  
  /// SizedBox horizontal 24px
  static const SizedBox horizontalLg = SizedBox(width: lg);
  
  /// SizedBox vertical 4px
  static const SizedBox verticalXs = SizedBox(height: xs);
  
  /// SizedBox vertical 8px
  static const SizedBox verticalSm = SizedBox(height: sm);
  
  /// SizedBox vertical 12px
  static const SizedBox verticalSmd = SizedBox(height: smd);
  
  /// SizedBox vertical 16px
  static const SizedBox verticalMd = SizedBox(height: md);
  
  /// SizedBox vertical 24px
  static const SizedBox verticalLg = SizedBox(height: lg);
  
  /// SizedBox vertical 32px
  static const SizedBox verticalXl = SizedBox(height: xl);
  
  /// SizedBox vertical 48px
  static const SizedBox verticalXxl = SizedBox(height: xxl);

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS PRESETS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Border radius small (4px)
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(xs));
  
  /// Border radius standard (8px)
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(sm));
  
  /// Border radius medium (12px)
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(smd));
  
  /// Border radius large (16px)
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(md));
  
  /// Border radius extra large (24px)
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(lg));
  
  /// Border radius rond (pour avatars, badges)
  static const BorderRadius radiusRound = BorderRadius.all(Radius.circular(999));
}
