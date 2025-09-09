import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/residence_model.dart';

/// Widget pour sélection flexible des dates selon la résidence
/// Supporte : horaire (1h, 2h, 3h+), journalier (demi-journée, jour, weekend)
class FlexibleBookingDateSelector extends StatefulWidget {
  final Residence residence;
  final Function(DateTime checkIn, DateTime checkOut, String bookingType, Map<String, dynamic> pricing) onDatesSelected;
  final DateTime? initialCheckIn;
  final DateTime? initialCheckOut;

  const FlexibleBookingDateSelector({
    Key? key,
    required this.residence,
    required this.onDatesSelected,
    this.initialCheckIn,
    this.initialCheckOut,
  }) : super(key: key);

  @override
  State<FlexibleBookingDateSelector> createState() => _FlexibleBookingDateSelectorState();
}

class _FlexibleBookingDateSelectorState extends State<FlexibleBookingDateSelector> {
  String _selectedBookingType = 'day'; // 'hour', 'day', 'week', 'month'
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  int _selectedHours = 1;
  String _selectedDayType = 'full'; // 'half', 'full', 'weekend'
  
  @override
  void initState() {
    super.initState();
    _initializeFromResidence();
    _selectedDate = widget.initialCheckIn ?? DateTime.now().add(Duration(days: 1));
  }

  /// Initialiser le type de réservation selon la résidence
  void _initializeFromResidence() {
    // Déterminer le type de réservation disponible selon les tarifs de la résidence
    if (widget.residence.hourlyRates != null && 
        (widget.residence.hourlyRates!.oneHour > 0 || 
         widget.residence.hourlyRates!.twoHours > 0)) {
      _selectedBookingType = 'hour';
    } else if (widget.residence.dailyRates != null && 
               (widget.residence.dailyRates!.halfDay > 0 || 
                widget.residence.dailyRates!.fullDay > 0)) {
      _selectedBookingType = 'day';
    } else {
      _selectedBookingType = 'day'; // Par défaut
    }
  }

  /// Calculer le prix selon le type de réservation
  double _calculatePrice() {
    switch (_selectedBookingType) {
      case 'hour':
        return _calculateHourlyPrice();
      case 'day':
        return _calculateDailyPrice();
      case 'week':
        return widget.residence.price * 7 * 0.9; // 10% réduction semaine
      case 'month':
        return widget.residence.price * 30 * 0.8; // 20% réduction mois
      default:
        return widget.residence.price;
    }
  }

  double _calculateHourlyPrice() {
    final hourlyRates = widget.residence.hourlyRates;
    if (hourlyRates == null) return widget.residence.price;

    switch (_selectedHours) {
      case 1:
        return hourlyRates.oneHour > 0 ? hourlyRates.oneHour : widget.residence.price / 24;
      case 2:
        return hourlyRates.twoHours > 0 ? hourlyRates.twoHours : (widget.residence.price / 24) * 2;
      case 3:
        return hourlyRates.threeHours > 0 ? hourlyRates.threeHours : (widget.residence.price / 24) * 3;
      default:
        final baseRate = hourlyRates.threeHours > 0 ? hourlyRates.threeHours : (widget.residence.price / 24) * 3;
        final additionalHours = _selectedHours - 3;
        final additionalRate = hourlyRates.additionalHour > 0 ? hourlyRates.additionalHour : (widget.residence.price / 24);
        return baseRate + (additionalHours * additionalRate);
    }
  }

  double _calculateDailyPrice() {
    final dailyRates = widget.residence.dailyRates;
    if (dailyRates == null) return widget.residence.price;

    switch (_selectedDayType) {
      case 'half':
        return dailyRates.halfDay > 0 ? dailyRates.halfDay : widget.residence.price * 0.6;
      case 'full':
        return dailyRates.fullDay > 0 ? dailyRates.fullDay : widget.residence.price;
      case 'weekend':
        return dailyRates.weekend > 0 ? dailyRates.weekend : widget.residence.price * 1.2;
      default:
        return widget.residence.price;
    }
  }

  void _updateSelection() {
    DateTime checkIn;
    DateTime checkOut;

    switch (_selectedBookingType) {
      case 'hour':
        if (_selectedDate != null && _startTime != null) {
          checkIn = DateTime(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
            _startTime!.hour,
            _startTime!.minute,
          );
          checkOut = checkIn.add(Duration(hours: _selectedHours));
        } else {
          return;
        }
        break;
      case 'day':
        if (_selectedDate != null) {
          if (_selectedDayType == 'half') {
            checkIn = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 14, 0); // 14h
            checkOut = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 18, 0); // 18h
          } else {
            checkIn = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 10, 0); // 10h
            checkOut = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day + 1, 10, 0); // 10h lendemain
          }
        } else {
          return;
        }
        break;
      default:
        if (_selectedDate != null) {
          checkIn = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 15, 0);
          final duration = _selectedBookingType == 'week' ? 7 : 30;
          checkOut = checkIn.add(Duration(days: duration));
        } else {
          return;
        }
    }

    final pricing = {
      'bookingType': _selectedBookingType,
      'price': _calculatePrice(),
      'details': _getPricingDetails(),
    };

    widget.onDatesSelected(checkIn, checkOut, _selectedBookingType, pricing);
  }

  Map<String, dynamic> _getPricingDetails() {
    switch (_selectedBookingType) {
      case 'hour':
        return {
          'hours': _selectedHours,
          'pricePerHour': _calculatePrice() / _selectedHours,
        };
      case 'day':
        return {
          'dayType': _selectedDayType,
          'pricePerDay': _calculatePrice(),
        };
      default:
        return {
          'type': _selectedBookingType,
          'basePrice': widget.residence.price,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Options de réservation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildBookingTypeSelector(),
            const SizedBox(height: 16),
            _buildDateSelector(),
            const SizedBox(height: 16),
            if (_selectedBookingType == 'hour') _buildHourlyOptions(),
            if (_selectedBookingType == 'day') _buildDailyOptions(),
            const SizedBox(height: 16),
            _buildPricingSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTypeSelector() {
    final availableTypes = <String, String>{};
    
    // Ajouter les types selon la résidence
    if (widget.residence.hourlyRates != null && 
        (widget.residence.hourlyRates!.oneHour > 0 || widget.residence.hourlyRates!.twoHours > 0)) {
      availableTypes['hour'] = 'Réservation horaire';
    }
    
    availableTypes['day'] = 'Réservation journalière';
    availableTypes['week'] = 'Réservation hebdomadaire';
    availableTypes['month'] = 'Réservation mensuelle';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de réservation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: availableTypes.entries.map((entry) {
            return FilterChip(
              label: Text(entry.value),
              selected: _selectedBookingType == entry.key,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedBookingType = entry.key;
                    _updateSelection();
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date de réservation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(
                  _selectedDate != null 
                    ? DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate!)
                    : 'Sélectionner une date',
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Durée (heures)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _selectedHours.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: '$_selectedHours h',
                onChanged: (value) {
                  setState(() {
                    _selectedHours = value.round();
                    _updateSelection();
                  });
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$_selectedHours h'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectStartTime,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      Text(_startTime?.format(context) ?? 'Heure de début'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de journée',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Demi-journée'),
              selected: _selectedDayType == 'half',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDayType = 'half';
                    _updateSelection();
                  });
                }
              },
            ),
            FilterChip(
              label: const Text('Journée complète'),
              selected: _selectedDayType == 'full',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDayType = 'full';
                    _updateSelection();
                  });
                }
              },
            ),
            FilterChip(
              label: const Text('Weekend'),
              selected: _selectedDayType == 'weekend',
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDayType = 'weekend';
                    _updateSelection();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingSummary() {
    final price = _calculatePrice();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimation du prix',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat.currency(locale: 'fr_FR', symbol: 'F CFA', decimalDigits: 0).format(price)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            _getPricingDescription(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getPricingDescription() {
    switch (_selectedBookingType) {
      case 'hour':
        return 'Pour $_selectedHours heure${_selectedHours > 1 ? 's' : ''}';
      case 'day':
        return _selectedDayType == 'half' ? 'Pour une demi-journée' : 
               _selectedDayType == 'weekend' ? 'Pour le weekend' : 'Pour une journée complète';
      case 'week':
        return 'Pour une semaine (réduction 10%)';
      case 'month':
        return 'Pour un mois (réduction 20%)';
      default:
        return '';
    }
  }

  void _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _updateSelection();
      });
    }
  }

  void _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        _startTime = time;
        _updateSelection();
      });
    }
  }


}

/// Extension pour ajouter les champs de tarification flexible au modèle Residence
extension ResidenceFlexiblePricing on Residence {
  HourlyRates? get hourlyRates {
    // ✅ CORRECTION : Utiliser les vrais champs du modèle
    if (pricePeriod == 'hour' || hourlyRate > 0) {
      return HourlyRates(
        oneHour: hourlyRate > 0 ? hourlyRate : price,
        twoHours: hourlyRate > 0 ? hourlyRate * 2 : price * 2,
        threeHours: hourlyRate > 0 ? hourlyRate * 3 : price * 3,
        additionalHour: hourlyRate > 0 ? hourlyRate : price,
      );
    }
    return null;
  }

  DailyRates? get dailyRates {
    // ✅ CORRECTION : Utiliser les vrais champs du modèle
    if (pricePeriod == 'day' || halfDayRate > 0 || fullDayRate > 0) {
      return DailyRates(
        halfDay: halfDayRate > 0 ? halfDayRate : price * 0.6,
        fullDay: fullDayRate > 0 ? fullDayRate : price,
        weekend: weekendRate > 0 ? weekendRate : price * 1.2,
      );
    }
    return null;
  }
}

/// Modèles pour les tarifs horaires et journaliers
class HourlyRates {
  final double oneHour;
  final double twoHours; 
  final double threeHours;
  final double additionalHour;

  const HourlyRates({
    this.oneHour = 0,
    this.twoHours = 0,
    this.threeHours = 0,
    this.additionalHour = 0,
  });

  factory HourlyRates.fromJson(Map<String, dynamic> json) {
    return HourlyRates(
      oneHour: (json['oneHour'] ?? 0).toDouble(),
      twoHours: (json['twoHours'] ?? 0).toDouble(),
      threeHours: (json['threeHours'] ?? 0).toDouble(),
      additionalHour: (json['additionalHour'] ?? 0).toDouble(),
    );
  }
}

class DailyRates {
  final double halfDay;
  final double fullDay;
  final double weekend;

  const DailyRates({
    this.halfDay = 0,
    this.fullDay = 0,
    this.weekend = 0,
  });

  factory DailyRates.fromJson(Map<String, dynamic> json) {
    return DailyRates(
      halfDay: (json['halfDay'] ?? 0).toDouble(),
      fullDay: (json['fullDay'] ?? 0).toDouble(),
      weekend: (json['weekend'] ?? 0).toDouble(),
    );
  }
}
