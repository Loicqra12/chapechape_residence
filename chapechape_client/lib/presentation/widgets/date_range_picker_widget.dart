import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class DateRangePickerWidget extends StatefulWidget {
  final Function(DateTimeRange)? onDateRangeSelected;
  final DateTimeRange? initialDateRange;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final int minimumNights;

  const DateRangePickerWidget({
    Key? key,
    this.onDateRangeSelected,
    this.initialDateRange,
    this.firstDate,
    this.lastDate,
    this.minimumNights = 1,
  }) : super(key: key);

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.initialDateRange;
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: widget.firstDate ?? DateTime.now(),
      lastDate: widget.lastDate ?? DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Vérifier la durée minimale
      final nights = picked.end.difference(picked.start).inDays;
      if (nights < widget.minimumNights) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('La durée minimale de séjour est de ${widget.minimumNights} nuit${widget.minimumNights > 1 ? 's' : ''}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _selectedDateRange = picked;
      });
      if (widget.onDateRangeSelected != null) {
        widget.onDateRangeSelected!(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd('fr');

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showDateRangePicker,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                        ? '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}'
                        : 'Sélectionner les dates',
                    style: TextStyle(
                      color: _selectedDateRange != null
                          ? Colors.black
                          : Colors.grey[600],
                    ),
                  ),
                ),
                if (_selectedDateRange != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      });
                      if (widget.onDateRangeSelected != null) {
                        widget.onDateRangeSelected!(DateTimeRange(
                          start: DateTime.now(),
                          end: DateTime.now().add(const Duration(days: 1)),
                        ));
                      }
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
