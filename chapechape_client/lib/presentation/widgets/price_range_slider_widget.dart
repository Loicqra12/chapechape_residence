import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'dart:math' as math;

class PriceRangeSliderWidget extends StatelessWidget {
  final double min;
  final double max;
  final RangeValues values;
  final ValueChanged<RangeValues> onChanged;
  final int? divisions;
  final bool useLogarithmicScale;

  const PriceRangeSliderWidget({
    Key? key,
    required this.min,
    required this.max,
    required this.values,
    required this.onChanged,
    this.divisions,
    this.useLogarithmicScale = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Utilise une échelle logarithmique si demandé et si l'écart entre min et max est grand
    if (useLogarithmicScale && max / min > 100) {
      return _buildLogarithmicSlider(context);
    } else {
      return _buildLinearSlider(context);
    }
  }

  Widget _buildLinearSlider(BuildContext context) {
    return RangeSlider(
      min: min,
      max: max,
      values: values,
      divisions: divisions ?? (max ~/ 1000).toInt(),
      activeColor: AppTheme.primaryColor,
      inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      labels: RangeLabels(
        _formatPrice(values.start),
        _formatPrice(values.end),
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildLogarithmicSlider(BuildContext context) {
    // Convertir les valeurs réelles en pourcentage logarithmique pour l'affichage
    final double logMin = min > 0 ? min.log() : 0;
    final double logMax = max > 0 ? max.log() : 1;
    final double logRange = logMax - logMin;

    // Convertir les valeurs actuelles en position logarithmique (0-1)
    final double startLog = values.start > 0 ? values.start.log() : logMin;
    final double endLog = values.end > 0 ? values.end.log() : logMax;
    
    // Normaliser à un pourcentage (0-1) pour le slider
    final double startPercent = (startLog - logMin) / logRange;
    final double endPercent = (endLog - logMin) / logRange;
    
    // Créer les valeurs du RangeSlider (0-1)
    final normalizedValues = RangeValues(startPercent, endPercent);

    return RangeSlider(
      min: 0.0,
      max: 1.0,
      values: normalizedValues,
      divisions: 100, // Plus de divisions pour plus de précision
      activeColor: AppTheme.primaryColor,
      inactiveColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      labels: RangeLabels(
        _formatPrice(values.start),
        _formatPrice(values.end),
      ),
      onChanged: (RangeValues newNormalizedValues) {
        // Convertir les pourcentages normalisés en valeurs logarithmiques
        final newStartLog = logMin + (newNormalizedValues.start * logRange);
        final newEndLog = logMin + (newNormalizedValues.end * logRange);
        
        // Convertir de l'échelle logarithmique à l'échelle réelle
        final newStart = newStartLog.exp();
        final newEnd = newEndLog.exp();
        
        // Arrondir aux 1000 FCFA les plus proches pour faciliter la lecture
        final roundedStart = (newStart / 1000).round() * 1000.0;
        final roundedEnd = (newEnd / 1000).round() * 1000.0;
        
        onChanged(RangeValues(roundedStart, roundedEnd));
      },
    );
  }

  String _formatPrice(double value) {
    // Formater avec séparateurs de milliers
    return '${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
  }
}

// Extension pour faciliter les calculs logarithmiques
extension LogarithmicExtension on double {
  double log() {
    return this <= 0 ? 0 : math.log(this) / math.log(10);
  }

  double exp() {
    return this <= 0 ? 0 : math.exp(this);
  }

  double logBase(double base) {
    return this <= 0 ? 0 : math.log(this) / math.log(base);
  }

  double pow10() {
    return math.pow(10, this).toDouble();
  }

  double ln() {
    return this <= 0 ? 0 : math.log(this);
  }

  // Constante e
  static const double e = 2.718281828459045;
}
