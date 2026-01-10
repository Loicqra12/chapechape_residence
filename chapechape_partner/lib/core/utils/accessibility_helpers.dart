import 'package:flutter/material.dart';

/// Utilitaires pour améliorer l'accessibilité de l'application
class AccessibilityHelpers {
  /// Vérifie si un contraste de couleur est suffisant pour WCAG AA (4.5:1 pour texte normal)
  static bool hasGoodContrast(Color foreground, Color background, {bool largeText = false}) {
    final ratio = calculateContrastRatio(foreground, background);
    final requiredRatio = largeText ? 3.0 : 4.5; // WCAG AA standards
    return ratio >= requiredRatio;
  }

  /// Calcule le ratio de contraste entre deux couleurs
  static double calculateContrastRatio(Color color1, Color color2) {
    final l1 = _relativeLuminance(color1);
    final l2 = _relativeLuminance(color2);
    
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Calcule la luminance relative d'une couleur
  static double _relativeLuminance(Color color) {
    final r = _linearize(color.red / 255.0);
    final g = _linearize(color.green / 255.0);
    final b = _linearize(color.blue / 255.0);
    
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linéarise une composante de couleur
  static double _linearize(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    }
    return ((channel + 0.055) / 1.055).toDouble();
  }

  /// Obtient une couleur de texte avec un bon contraste sur un fond donné
  static Color getContrastingTextColor(Color background) {
    final luminance = _relativeLuminance(background);
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  /// Assombrit une couleur pour améliorer le contraste
  static Color darken(Color color, [double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    
    return hslDark.toColor();
  }

  /// Éclaircit une couleur pour améliorer le contraste
  static Color lighten(Color color, [double amount = 0.2]) {
    assert(amount >= 0 && amount <= 1);
    
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    
    return hslLight.toColor();
  }

  /// Crée un label sémantique pour un widget (pour les lecteurs d'écran)
  static String createSemanticLabel({
    required String text,
    String? hint,
    String? value,
  }) {
    final parts = [text];
    if (value != null) parts.add(value);
    if (hint != null) parts.add(hint);
    return parts.join(', ');
  }

  /// Retourne la taille de police minimale recommandée selon l'importance du texte
  static double getMinimumFontSize(TextImportance importance) {
    switch (importance) {
      case TextImportance.heading:
        return 20.0;
      case TextImportance.subheading:
        return 16.0;
      case TextImportance.body:
        return 14.0;
      case TextImportance.caption:
        return 12.0;
    }
  }

  /// Retourne le ratio de contraste minimum requis selon le type de texte
  static double getMinimumContrastRatio(TextSize size) {
    switch (size) {
      case TextSize.large: // 18pt+ ou 14pt+ bold
        return 3.0; // WCAG AA
      case TextSize.normal:
        return 4.5; // WCAG AA
    }
  }

  /// Crée un TextStyle accessible avec un bon contraste
  static TextStyle createAccessibleTextStyle({
    required BuildContext context,
    required Color backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    TextImportance importance = TextImportance.body,
  }) {
    final theme = Theme.of(context);
    final effectiveFontSize = fontSize ?? getMinimumFontSize(importance);
    final textColor = getContrastingTextColor(backgroundColor);
    
    return theme.textTheme.bodyMedium!.copyWith(
      color: textColor,
      fontSize: effectiveFontSize,
      fontWeight: fontWeight,
    );
  }

  /// Vérifie si une surface est accessible (contraste suffisant avec le texte)
  static bool isSurfaceAccessible(Color surface, Color text) {
    return hasGoodContrast(text, surface);
  }

  /// Suggère une couleur alternative avec un meilleur contraste
  static Color suggestBetterContrast(Color foreground, Color background) {
    if (hasGoodContrast(foreground, background)) {
      return foreground;
    }
    
    // Essayer d'assombrir ou d'éclaircir progressivement
    final luminance = _relativeLuminance(background);
    final shouldDarken = luminance > 0.5;
    
    Color adjusted = foreground;
    double amount = 0.1;
    
    while (amount <= 1.0 && !hasGoodContrast(adjusted, background)) {
      adjusted = shouldDarken ? darken(foreground, amount) : lighten(foreground, amount);
      amount += 0.1;
    }
    
    return adjusted;
  }

  /// Retourne des couleurs d'état accessibles
  static AccessibleColors getAccessibleStateColors(BuildContext context) {
    return const AccessibleColors(
      success: Color(0xFF2E7D32), // Vert foncé
      warning: Color(0xFFE65100), // Orange foncé
      error: Color(0xFFC62828), // Rouge foncé
      info: Color(0xFF1565C0), // Bleu foncé
      successBackground: Color(0xFFC8E6C9), // Vert clair
      warningBackground: Color(0xFFFFE0B2), // Orange clair
      errorBackground: Color(0xFFFFCDD2), // Rouge clair
      infoBackground: Color(0xFFBBDEFB), // Bleu clair
    );
  }

  /// Configure les paramètres d'accessibilité pour un Scaffold
  static Widget makeScaffoldAccessible({
    required Widget child,
    required String screenTitle,
    String? screenDescription,
  }) {
    return Semantics(
      label: screenTitle,
      hint: screenDescription,
      container: true,
      child: child,
    );
  }

  /// Ajoute un feedback haptique pour les actions importantes
  static Future<void> provideFeedback(FeedbackType type) async {
    // Note: Nécessite le package flutter/services.dart
    // await HapticFeedback.vibrate();
    // Pour l'instant, juste un placeholder
  }
}

/// Types d'importance du texte
enum TextImportance {
  heading,
  subheading,
  body,
  caption,
}

/// Tailles de texte pour le calcul du contraste
enum TextSize {
  large, // 18pt+ ou 14pt+ bold
  normal,
}

/// Type de feedback haptique
enum FeedbackType {
  light,
  medium,
  heavy,
  success,
  warning,
  error,
}

/// Couleurs d'état accessibles
class AccessibleColors {
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color successBackground;
  final Color warningBackground;
  final Color errorBackground;
  final Color infoBackground;

  const AccessibleColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.successBackground,
    required this.warningBackground,
    required this.errorBackground,
    required this.infoBackground,
  });
}

/// Widget pour créer un bouton accessible avec bon contraste
class AccessibleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final IconData? icon;
  final bool isOutlined;
  final String? semanticLabel;

  const AccessibleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.backgroundColor,
    this.icon,
    this.isOutlined = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBgColor = backgroundColor ?? theme.primaryColor;
    final textColor = AccessibilityHelpers.getContrastingTextColor(effectiveBgColor);

    final buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );

    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: onPressed != null,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: effectiveBgColor,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: buttonContent,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: effectiveBgColor,
                foregroundColor: textColor,
                minimumSize: const Size(120, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: buttonContent,
            ),
    );
  }
}
