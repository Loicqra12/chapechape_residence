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
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1E3C72), // Bleu nuit profond
                  Color(0xFF2A5298), // Bleu plus clair
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF1E3C72).withOpacity(0.3),
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
                    color: AppTheme.textLight.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    color: AppTheme.textLight,
                    size: 24,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 1.0, end: 1.1, duration: 1000.ms)
                .shimmer(duration: 2000.ms, color: AppTheme.textLight.withOpacity(0.4)),

                SizedBox(width: AppSpacing.md),

                // Texte
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Offre de Bienvenue",
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textLight.withOpacity(0.7),
                          letterSpacing: 1.0,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Text(
                            "-15%",
                            style: AppTextStyles.subtitle.copyWith(
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            " sur votre 1ère résa !",
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppTheme.textLight,
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
                  color: AppTheme.textLight.withOpacity(0.7),
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
