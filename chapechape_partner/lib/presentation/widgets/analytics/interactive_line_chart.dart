import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Graphique en ligne interactif avec zoom et tap pour détails
class InteractiveLineChart extends StatefulWidget {
  final List<ChartDataPoint> data;
  final String title;
  final String yAxisLabel;
  final Color lineColor;
  final Color gradientStartColor;
  final Color gradientEndColor;
  final bool showDots;
  final bool showGrid;
  final double minY;
  final double maxY;
  final Function(ChartDataPoint)? onPointTap;

  const InteractiveLineChart({
    super.key,
    required this.data,
    required this.title,
    this.yAxisLabel = '',
    this.lineColor = Colors.blue,
    Color? gradientStartColor,
    Color? gradientEndColor,
    this.showDots = true,
    this.showGrid = true,
    this.minY = 0,
    double? maxY,
    this.onPointTap,
  })  : gradientStartColor = gradientStartColor ?? Colors.blue,
        gradientEndColor = gradientEndColor ?? Colors.transparent,
        maxY = maxY ?? 0;

  @override
  State<InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<InteractiveLineChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
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
            child: LineChart(
              LineChartData(
                minY: widget.minY,
                maxY: maxYValue,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                    if (touchResponse == null || touchResponse.lineBarSpots == null) {
                      setState(() {
                        _touchedIndex = null;
                      });
                      return;
                    }

                    final spot = touchResponse.lineBarSpots!.first;
                    setState(() {
                      _touchedIndex = spot.spotIndex;
                    });

                    if (event is FlTapUpEvent && widget.onPointTap != null) {
                      widget.onPointTap!(widget.data[spot.spotIndex]);
                    }
                  },
                  getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((index) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: widget.lineColor.withOpacity(0.5),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 8,
                              color: widget.lineColor,
                              strokeWidth: 3,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: widget.lineColor.withOpacity(0.9),
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final dataPoint = widget.data[barSpot.spotIndex];
                        return LineTooltipItem(
                          '${dataPoint.label}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: _formatValue(barSpot.y),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      }).toList();
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
                      reservedSize: 30,
                      interval: 1,
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
                lineBarsData: [
                  LineChartBarData(
                    spots: widget.data
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                        .toList(),
                    isCurved: true,
                    color: widget.lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: widget.showDots,
                      getDotPainter: (spot, percent, barData, index) {
                        final isSelected = index == _touchedIndex;
                        return FlDotCirclePainter(
                          radius: isSelected ? 6 : 4,
                          color: isSelected ? widget.lineColor : Colors.white,
                          strokeWidth: 2,
                          strokeColor: widget.lineColor,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.gradientStartColor.withOpacity(0.3),
                          widget.gradientEndColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
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

/// Modèle de données pour un point du graphique
class ChartDataPoint {
  final String label;
  final double value;
  final DateTime? date;
  final Map<String, dynamic>? metadata;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.date,
    this.metadata,
  });
}

