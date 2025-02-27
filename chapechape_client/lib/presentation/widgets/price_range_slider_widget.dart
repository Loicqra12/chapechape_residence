import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PriceRangeSliderWidget extends StatefulWidget {
  final double min;
  final double max;
  final Function(RangeValues)? onChanged;
  final RangeValues? initialRange;
  final String currency;

  const PriceRangeSliderWidget({
    Key? key,
    this.min = 0,
    this.max = 1000000,
    this.onChanged,
    this.initialRange,
    this.currency = 'FCFA',
  }) : super(key: key);

  @override
  State<PriceRangeSliderWidget> createState() => _PriceRangeSliderWidgetState();
}

class _PriceRangeSliderWidgetState extends State<PriceRangeSliderWidget> {
  late RangeValues _currentRangeValues;

  @override
  void initState() {
    super.initState();
    _currentRangeValues = widget.initialRange ??
        RangeValues(widget.min, widget.max);
  }

  String _formatPrice(double value) {
    return '${value.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        )} ${widget.currency}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatPrice(_currentRangeValues.start),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatPrice(_currentRangeValues.end),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _currentRangeValues,
            min: widget.min,
            max: widget.max,
            divisions: 100,
            activeColor: AppTheme.primaryColor,
            inactiveColor: Colors.grey[300],
            labels: RangeLabels(
              _formatPrice(_currentRangeValues.start),
              _formatPrice(_currentRangeValues.end),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _currentRangeValues = values;
              });
              if (widget.onChanged != null) {
                widget.onChanged!(values);
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min: ${_formatPrice(widget.min)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                'Max: ${_formatPrice(widget.max)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
