import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DurationSelector extends StatefulWidget {
  final void Function(Duration) onDurationChanged;
  final Duration initialDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final Duration step;

  const DurationSelector({
    Key? key,
    required this.onDurationChanged,
    this.initialDuration = const Duration(hours: 1),
    this.minDuration = const Duration(hours: 1),
    this.maxDuration = const Duration(hours: 24),
    this.step = const Duration(hours: 1),
  }) : super(key: key);

  @override
  State<DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<DurationSelector> {
  late Duration _selectedDuration;

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDuration;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    return '$hours ${hours == 1 ? 'heure' : 'heures'}';
  }

  void _incrementDuration() {
    if (_selectedDuration + widget.step <= widget.maxDuration) {
      setState(() {
        _selectedDuration += widget.step;
        widget.onDurationChanged(_selectedDuration);
      });
    }
  }

  void _decrementDuration() {
    if (_selectedDuration - widget.step >= widget.minDuration) {
      setState(() {
        _selectedDuration -= widget.step;
        widget.onDurationChanged(_selectedDuration);
      });
    }
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Durée de séjour',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                onPressed: _decrementDuration,
                icon: Icons.remove,
                enabled: _selectedDuration - widget.step >= widget.minDuration,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_selectedDuration),
                      style: AppTheme.headingMedium,
                    ),
                    Text(
                      'Durée minimale: ${_formatDuration(widget.minDuration)}',
                      style: AppTheme.bodySmall.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              _buildControlButton(
                onPressed: _incrementDuration,
                icon: Icons.add,
                enabled: _selectedDuration + widget.step <= widget.maxDuration,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.blue[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Ajustez la durée selon vos besoins',
                style: AppTheme.bodySmall.copyWith(
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required bool enabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: enabled ? Colors.blue[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? Colors.blue[100]! : Colors.grey[300]!,
            ),
          ),
          child: Icon(
            icon,
            color: enabled ? Colors.blue[600] : Colors.grey[400],
            size: 24,
          ),
        ),
      ),
    );
  }
}
