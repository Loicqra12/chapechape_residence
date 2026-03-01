/// Bouton principal réutilisable avec support d'accessibilité
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/colors.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsets? padding;
  final IconData? icon;
  /// Bouton plein violet (fond violet, texte blanc) au lieu du contour violet
  final bool filled;
  /// Label personnalisé pour les lecteurs d'écran (optionnel, utilise [text] par défaut)
  final String? semanticLabel;
  /// Hint pour les lecteurs d'écran (ex: "Double-tap pour confirmer")
  final String? semanticHint;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.padding,
    this.icon,
    this.filled = false,
    this.semanticLabel,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool useFilled = filled;
    final Color borderColor = AppColors.accentViolet.withOpacity(isLoading ? 0.4 : 1);
    final Color textColor = useFilled
        ? (isLoading ? Colors.white70 : Colors.white)
        : AppColors.accentViolet.withOpacity(isLoading ? 0.5 : 1);
    final Color bgColor = useFilled
        ? (isLoading ? AppColors.accentViolet.withOpacity(0.7) : AppColors.accentViolet)
        : theme.colorScheme.surface;
    final BorderSide? side = useFilled ? null : BorderSide(color: borderColor, width: 2);

    return Semantics(
      button: true,
      enabled: !isLoading,
      label: semanticLabel ?? text,
      hint: semanticHint ?? (isLoading ? 'Chargement en cours' : null),
      child: SizedBox(
        width: isFullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: isLoading
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
          style: ElevatedButton.styleFrom(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
            elevation: useFilled ? 1 : 0,
            backgroundColor: bgColor,
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: side ?? BorderSide.none,
            ),
          ),
          child: isLoading
              ? Semantics(
                  label: 'Chargement',
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        useFilled ? Colors.white : AppColors.accentViolet,
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20, semanticLabel: null, color: textColor),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
