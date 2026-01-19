import 'package:flutter/material.dart';

/// Système d'espacement cohérent pour l'application ChapeChape Client
/// Basé sur une grille de 4px pour une harmonie visuelle
class AppSpacing {
  // Tokens de base
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double smd = 12.0; // Small-Medium
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Presets pour les paddings courants
  static const EdgeInsets pagePadding = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: md, vertical: smd);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: md, vertical: md);
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(horizontal: md, vertical: lg);

  // Presets pour les margins courantes
  static const EdgeInsets cardMargin = EdgeInsets.only(bottom: md);
  static const EdgeInsets sectionMargin = EdgeInsets.only(bottom: lg);

  // Rayons de bordure courants
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // Espacements verticaux courants
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalSmd = SizedBox(height: smd);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);

  // Espacements horizontaux courants
  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalSmd = SizedBox(width: smd);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalLg = SizedBox(width: lg);
}
