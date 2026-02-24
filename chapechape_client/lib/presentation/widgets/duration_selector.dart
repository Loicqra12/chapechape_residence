import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Option de durée de séjour
class DurationOption {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final int? minHours;
  final int? maxHours;
  final int? minDays;
  final int? maxDays;
  final List<String> periods; // ['hour', 'day', 'week', 'month']

  const DurationOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    this.minHours,
    this.maxHours,
    this.minDays,
    this.maxDays,
    required this.periods,
  });

  /// Calcule le nombre total d'heures pour cette durée
  int getTotalHours() {
    if (minHours != null) return minHours!;
    if (minDays != null) return minDays! * 24;
    return 24;
  }

  /// Calcule le nombre total de jours pour cette durée
  int getTotalDays() {
    if (minDays != null) return minDays!;
    if (minHours != null) return (minHours! / 24).ceil();
    return 1;
  }
}

/// Sélecteur de durée multi-période (hour/day/week/month)
class DurationSelector extends StatefulWidget {
  final Function(DurationOption)? onDurationChanged;
  final DurationOption? initialDuration;

  const DurationSelector({
    Key? key,
    this.onDurationChanged,
    this.initialDuration,
  }) : super(key: key);

  @override
  State<DurationSelector> createState() => _DurationSelectorState();
}

class _DurationSelectorState extends State<DurationSelector> {
  DurationOption? _selectedDuration;

  // Options de durée prédéfinies (contexte ivoirien)
  static const List<DurationOption> _availableDurations = [
    DurationOption(
      id: 'hours_1_6',
      label: 'Quelques heures',
      subtitle: '1 à 6h',
      icon: Icons.access_time,
      minHours: 1,
      maxHours: 6,
      periods: ['hour'],
    ),
    DurationOption(
      id: 'hours_6_24',
      label: 'Une journée',
      subtitle: "Jusqu'à 24h",
      icon: Icons.wb_sunny,
      minHours: 6,
      maxHours: 24,
      periods: ['hour', 'day'],
    ),
    DurationOption(
      id: 'days_2_6',
      label: 'Plusieurs jours',
      subtitle: '2 à 6 jours',
      icon: Icons.event,
      minDays: 2,
      maxDays: 6,
      periods: ['day'],
    ),
    DurationOption(
      id: 'week',
      label: 'Une semaine',
      subtitle: '7 jours',
      icon: Icons.date_range,
      minDays: 7,
      maxDays: 7,
      periods: ['week', 'day'],
    ),
    DurationOption(
      id: 'weeks_2_4',
      label: 'Plusieurs semaines',
      subtitle: '14 à 28 jours',
      icon: Icons.calendar_today,
      minDays: 14,
      maxDays: 28,
      periods: ['week', 'month'],
    ),
    DurationOption(
      id: 'month_plus',
      label: 'Un mois ou plus',
      subtitle: '30+ jours',
      icon: Icons.calendar_month,
      minDays: 30,
      periods: ['month'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDuration = widget.initialDuration;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section
        Row(
          children: [
            Icon(Icons.schedule, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Combien de temps ?',
              style: TextStyle(
                color: Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Liste horizontale des options
        SizedBox(
          height: 132,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDurations.length,
            itemBuilder: (context, index) {
              final duration = _availableDurations[index];
              final isSelected = _selectedDuration?.id == duration.id;

              return Padding(
                padding: EdgeInsets.only(right: index < _availableDurations.length - 1 ? 12 : 0),
                child: _buildDurationCard(duration, isSelected),
              );
            },
          ),
        ),

        // Indicateur de sélection
        if (_selectedDuration != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Durée sélectionnée : ${_selectedDuration!.label.toLowerCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDurationCard(DurationOption duration, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDuration = duration;
        });
        if (widget.onDurationChanged != null) {
          widget.onDurationChanged!(duration);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              duration.icon,
              size: 24,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
            const SizedBox(height: 6),
            Text(
              duration.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[800],
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              duration.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : Colors.grey[600],
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
