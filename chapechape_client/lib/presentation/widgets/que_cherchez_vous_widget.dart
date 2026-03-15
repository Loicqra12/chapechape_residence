import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';

/// Bloc "Que cherchez-vous aujourd'hui ?" — 6 intentions (Court séjour, Hôtel, etc.).
/// Un tap sur un chip ouvre la recherche avec la catégorie sélectionnée.
/// "Continuer ma recherche" envoie vers l'écran de recherche sans filtre catégorie.
class QueCherchezVousWidget extends StatelessWidget {
  const QueCherchezVousWidget({Key? key}) : super(key: key);

  static const List<_QuickCategory> _categories = [
    _QuickCategory('meublee', 'Court séjour', Icons.home_outlined),
    _QuickCategory('hotel', 'Hôtel', Icons.hotel_outlined),
    _QuickCategory('longue_duree', 'Longue durée', Icons.home_work_outlined),
    _QuickCategory('colocation', 'Colocation', Icons.people_outline),
    _QuickCategory('insolite', 'Insolite', Icons.forest_outlined),
    _QuickCategory('economique', 'Économique', Icons.savings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final textColor = scheme.onSurface;
    final subColor = scheme.onSurface.withOpacity(0.8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Que cherchez-vous aujourd\'hui ?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSpacing.smd),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categories.map((c) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/search', extra: {'residenceCategory': c.value});
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : AppTheme.lightGold,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white24
                            : AppTheme.primaryColor.withOpacity(0.6),
                        width: 1.2,
                      ),
                      boxShadow: isDark ? null : AppTheme.softShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          c.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          const _ContinueSearchCard(),
        ],
      ),
    );
  }
}

/// Carte "Continuer ma recherche" : texte à gauche, pile d'images à droite, fond blanc, contour or, ombre douce.
class _ContinueSearchCard extends StatelessWidget {
  const _ContinueSearchCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final subColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/search');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.5),
              width: 1.2,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explorer les résidences',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continuer ma recherche',
                      style: TextStyle(
                        fontSize: 13,
                        color: subColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 72,
                height: 56,
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    _stackedImage(0),
                    _stackedImage(1),
                    _stackedImage(2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stackedImage(int index) {
    const double width = 48;
    const double height = 40;
    const double offset = 12;

    // Trois vraies images de résidences issues des assets
    const List<String> images = [
      ResidenceAssets.villa1,
      ResidenceAssets.apartment4,
      ResidenceAssets.luxury1,
    ];
    final imagePath = images[index % images.length];

    return Positioned(
      right: index * offset,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: AppTheme.softShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppTheme.lightGold,
            child: Icon(
              Icons.home_work_outlined,
              color: AppTheme.primaryColor.withOpacity(0.6),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCategory {
  final String value;
  final String label;
  final IconData icon;
  const _QuickCategory(this.value, this.label, this.icon);
}
