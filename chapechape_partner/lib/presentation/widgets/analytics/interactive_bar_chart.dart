import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// Graphique en barres interactif avec tap pour détails
class InteractiveBarChart extends StatefulWidget {
  final List<BarChartDataPoint> data;
  final String title;
  final String yAxisLabel;
  final Color barColor;
  final Color? selectedBarColor;
  final bool showGrid;
  final double minY;
  final double maxY;
  final Function(BarChartDataPoint)? onBarTap;

  const InteractiveBarChart({
    super.key,
    required this.data,
    required this.title,
    this.yAxisLabel = '',
    this.barColor = AppColors.brandPrimary,
    this.selectedBarColor,
    this.showGrid = true,
    this.minY = 0,
    double? maxY,
    this.onBarTap,
  }) : maxY = maxY ?? 0;

  @override
  State<InteractiveBarChart> createState() => _InteractiveBarChartState();
}

class _InteractiveBarChartState extends State<InteractiveBarChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Aucune donnée disponible',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final maxYValue = widget.maxY > 0
        ? widget.maxY
        : widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

    final selectedColor = widget.selectedBarColor ?? widget.barColor.withOpacity(0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Graphique
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 8, bottom: 16),
            child: BarChart(
              BarChartData(
                minY: widget.minY,
                maxY: maxYValue,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    if (barTouchResponse == null ||
                        barTouchResponse.spot == null ||
                        event is! FlTapUpEvent) {
                      setState(() {
                        _touchedIndex = null;
                      });
                      return;
                    }

                    final touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    setState(() {
                      _touchedIndex = touchedIndex;
                    });

                    if (widget.onBarTap != null) {
                      widget.onBarTap!(widget.data[touchedIndex]);
                    }
                  },
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: widget.barColor.withOpacity(0.9),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dataPoint = widget.data[groupIndex];
                      return BarTooltipItem(
                        '${dataPoint.label}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: _formatValue(rod.toY),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: widget.showGrid,
                  drawVerticalLine: false,
                  horizontalInterval: maxYValue / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= widget.data.length) {
                          return const Text('');
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            widget.data[index].label,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: maxYValue / 5,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatValue(value),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    left: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                barGroups: widget.data.asMap().entries.map((entry) {
                  final index = entry.key;
                  final dataPoint = entry.value;
                  final isTouched = index == _touchedIndex;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: dataPoint.value,
                        color: isTouched ? selectedColor : widget.barColor,
                        width: isTouched ? 24 : 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxYValue,
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else {
      return value.toStringAsFixed(0);
    }
  }
}

/// Modèle de données pour une barre du graphique
class BarChartDataPoint {
  final String label;
  final double value;
  final Color? color;
  final Map<String, dynamic>? metadata;

  BarChartDataPoint({
    required this.label,
    required this.value,
    this.color,
    this.metadata,
  });
}

