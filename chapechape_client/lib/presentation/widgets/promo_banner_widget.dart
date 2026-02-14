import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/spacing.dart';

class PromoBannerWidget extends StatelessWidget {
  const PromoBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.smd),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Action à définir (ex: scroll vers offres ou dialog)
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              color: AppTheme.accentColor, // Fond noir
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icône Cadeau animée
                Container(
                  padding: EdgeInsets.all(AppSpacing.smd),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppTheme.secondaryColor, // Or plus vif pour l'icône
                    size: 24,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.1, duration: 1000.ms)
                .shimmer(duration: 2000.ms, color: AppTheme.secondaryColor.withOpacity(0.5)),

                SizedBox(width: AppSpacing.md),

                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Offre de Bienvenue",
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.secondaryColor.withOpacity(0.9), // Or plus vif
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "-15%",
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppTheme.secondaryColor, // Or plus vif pour le pourcentage
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            " sur votre 1ère résa !",
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppTheme.textLight, // Blanc pour le texte secondaire
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Flèche
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.secondaryColor.withOpacity(0.9), // Or plus vif
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 600.ms, delay: 200.ms)
    .slideY(begin: 0.1, end: 0, duration: 600.ms, delay: 200.ms);
  }
}
