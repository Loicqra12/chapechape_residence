import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final subColor = isDark ? Colors.grey[400] : Colors.grey[600];

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
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? Colors.white24
                            : Colors.grey.shade300,
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
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/search');
              },
              icon: Icon(Icons.tune, size: 18, color: subColor),
              label: Text(
                'Continuer ma recherche',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
            ),
          ),
        ],
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
