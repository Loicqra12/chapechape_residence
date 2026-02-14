import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget de comparaison entre deux périodes
/// Affiche la valeur actuelle, la valeur précédente et le pourcentage de changement
class PeriodComparisonWidget extends StatelessWidget {
  final String title;
  final double currentValue;
  final double previousValue;
  final String currentPeriodLabel;
  final String previousPeriodLabel;
  final String unit;
  final IconData icon;
  final Color? color;
  final bool isMonetary;

  const PeriodComparisonWidget({
    super.key,
    required this.title,
    required this.currentValue,
    required this.previousValue,
    required this.currentPeriodLabel,
    required this.previousPeriodLabel,
    this.unit = '',
    this.icon = Icons.trending_up,
    this.color,
    this.isMonetary = false,
  });

  double get _percentageChange {
    if (previousValue == 0) return currentValue > 0 ? 100 : 0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  bool get _isPositiveChange => _percentageChange >= 0;

  Color get _changeColor => _isPositiveChange ? Colors.green : Colors.red;

  IconData get _changeIcon =>
      _isPositiveChange ? Icons.trending_up : Icons.trending_down;

  String _formatValue(double value) {
    if (isMonetary) {
      return NumberFormat.currency(
        symbol: '',
        decimalDigits: 0,
        locale: 'fr_FR',
      ).format(value);
    }
    return value.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? Theme.of(context).primaryColor;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête avec icône et titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: displayColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: displayColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Valeur actuelle (grande)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    _formatValue(currentValue),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: displayColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),

            // Label période actuelle
            Text(
              currentPeriodLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),

            // Divider
            Divider(color: Colors.grey[300], height: 1),
            const SizedBox(height: 10),

            // Comparaison avec période précédente
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Valeur précédente
                Flexible(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previousPeriodLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatValue(previousValue)} $unit',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Badge de changement
                Flexible(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                  decoration: BoxDecoration(
                    color: _changeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _changeColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _changeIcon,
                        color: _changeColor,
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${_isPositiveChange ? '+' : ''}${_percentageChange.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _changeColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ],
            ),

            // Message de contexte (optionnel, supprimé pour économiser l'espace)
            // if (_percentageChange.abs() > 0) ...[
            //   const SizedBox(height: 8),
            //   Text(
            //     _isPositiveChange ? 'En hausse' : 'En baisse',
            //     style: TextStyle(
            //       fontSize: 10,
            //       color: Colors.grey[600],
            //       fontStyle: FontStyle.italic,
            //     ),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}

/// Widget de comparaison multiple (plusieurs métriques côte à côte)
class MultiPeriodComparisonWidget extends StatelessWidget {
  final List<PeriodComparisonData> comparisons;
  final String currentPeriodLabel;
  final String previousPeriodLabel;

  const MultiPeriodComparisonWidget({
    super.key,
    required this.comparisons,
    required this.currentPeriodLabel,
    required this.previousPeriodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: comparisons.length,
      itemBuilder: (context, index) {
        final comparison = comparisons[index];
        return PeriodComparisonWidget(
          title: comparison.title,
          currentValue: comparison.currentValue,
          previousValue: comparison.previousValue,
          currentPeriodLabel: currentPeriodLabel,
          previousPeriodLabel: previousPeriodLabel,
          unit: comparison.unit,
          icon: comparison.icon,
          color: comparison.color,
          isMonetary: comparison.isMonetary,
        );
      },
    );
  }
}

/// Modèle de données pour une comparaison de période
class PeriodComparisonData {
  final String title;
  final double currentValue;
  final double previousValue;
  final String unit;
  final IconData icon;
  final Color? color;
  final bool isMonetary;

  PeriodComparisonData({
    required this.title,
    required this.currentValue,
    required this.previousValue,
    this.unit = '',
    this.icon = Icons.trending_up,
    this.color,
    this.isMonetary = false,
  });
}

