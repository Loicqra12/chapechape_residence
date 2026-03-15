import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
import '../../core/services/logger_service.dart';
import 'package:intl/intl.dart';

class DateRangePickerWidget extends StatefulWidget {
  final DateTimeRange? initialDateRange;
  final Function(DateTimeRange?) onDateRangeSelected;

  const DateRangePickerWidget({
    Key? key,
    this.initialDateRange,
    required this.onDateRangeSelected,
  }) : super(key: key);

  @override
  State<DateRangePickerWidget> createState() => _DateRangePickerWidgetState();
}

class _DateRangePickerWidgetState extends State<DateRangePickerWidget> with SingleTickerProviderStateMixin {
  DateTimeRange? _selectedDateRange;
  late TabController _tabController;
  bool _isFlexibleDates = false;
  
  // Service de journalisation
  final _logger = LoggerService();
  
  // Options pour les dates flexibles
  String _selectedFlexibleOption = 'Un weekend';
  DateTime? _selectedMonthDate;
  String _selectedMonthFormatted = '';
  int _selectedMonthIndex = 0;
  
  // Options pour les dates exactes
  String _selectedFlexibility = 'Dates exactes';
  
  final List<Map<String, String>> _flexibleOptions = [
    {'text': 'Un weekend', 'value': 'weekend'},
    {'text': 'Une semaine', 'value': 'week'},
    {'text': 'Un mois', 'value': 'month'},
  ];
  
  final List<String> _flexibilityOptions = [
    'Dates exactes',
    '±1 jour',
    '±2 jours',
    '±3 jours',
  ];

  @override
  void initState() {
    super.initState();
    
    // Valider la plage de dates initiale
    final now = DateTime.now();
    if (widget.initialDateRange != null) {
      // Si les dates initiales sont dans le passé, les ajuster au présent
      if (widget.initialDateRange!.start.isBefore(now)) {
        final endDelta = widget.initialDateRange!.duration;
        _selectedDateRange = DateTimeRange(
          start: now,
          end: now.add(endDelta),
        );
        _logger.info('DateRangePickerWidget: Dates initiales ajustées car dans le passé - Durée préservée: ${endDelta.inDays} jours');
      } else {
        _selectedDateRange = widget.initialDateRange;
        _logger.info('DateRangePickerWidget: Dates initiales valides - Plage: ${DateFormat('dd/MM/yyyy').format(widget.initialDateRange!.start)} à ${DateFormat('dd/MM/yyyy').format(widget.initialDateRange!.end)}');
      }
    } else {
      _logger.debug('DateRangePickerWidget: Aucune date initiale fournie');
    }
    
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Initialiser le mois sélectionné au mois courant
    _selectedMonthDate = DateTime(now.year, now.month, 1);
    _selectedMonthFormatted = _formatMonth(now);
  }

  @override
  void dispose() {
    _logger.debug('DateRangePickerWidget: Nettoyage des ressources');
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _isFlexibleDates = _tabController.index == 1;
    });
  }

  void _selectDateRange() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                children: [
                  _buildDragHandle(),
                  Text(
                    'Sélectionner des dates',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Navigation entre les modes calendrier et dates flexibles
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Calendrier'),
                      Tab(text: 'Dates flexibles'),
                    ],
                    labelColor: AppTheme.primaryColor,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    indicatorColor: AppTheme.primaryColor,
                  ),
                  
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Onglet Calendrier
                        _buildCalendarTab(setModalState),
                        
                        // Onglet Dates flexibles
                        _buildFlexibleDatesTab(setModalState),
                      ],
                    ),
                  ),
                  
                  // Barre de résumé et bouton de confirmation
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isFlexibleDates
                              ? '${_selectedFlexibleOption} en ${_selectedMonthFormatted.split(' ').first}'
                              : _getSelectedDateRangeText(),
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_isFlexibleDates) {
                                // Pour les dates flexibles, on crée une plage approximative
                                final now = DateTime.now();
                                final targetMonth = now.month + _selectedMonthIndex;
                                final targetYear = now.year + (targetMonth > 12 ? 1 : 0);
                                final adjustedMonth = targetMonth > 12 ? targetMonth - 12 : targetMonth;
                                
                                final firstDayOfMonth = DateTime(targetYear, adjustedMonth, 1);
                                DateTime startDate;
                                DateTime endDate;
                                
                                if (_selectedFlexibleOption == 'Un weekend') {
                                  // Premier week-end du mois
                                  startDate = _getFirstWeekendOfMonth(firstDayOfMonth);
                                  endDate = startDate.add(const Duration(days: 2));
                                } else if (_selectedFlexibleOption == 'Une semaine') {
                                  // Première semaine du mois
                                  startDate = firstDayOfMonth;
                                  endDate = startDate.add(const Duration(days: 7));
                                } else {
                                  // Tout le mois
                                  startDate = firstDayOfMonth;
                                  final lastDay = DateTime(targetYear, adjustedMonth + 1, 0).day;
                                  endDate = DateTime(targetYear, adjustedMonth, lastDay);
                                }
                                
                                _selectedDateRange = DateTimeRange(
                                  start: startDate,
                                  end: endDate,
                                );
                              }
                              
                              Navigator.pop(context);
                              widget.onDateRangeSelected(_selectedDateRange);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: AppTheme.textLight,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text(
                              _isFlexibleDates ? 'Sélectionner des dates' : 'Choisir des dates',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Construction de l'onglet calendrier
  Widget _buildCalendarTab(StateSetter setModalState) {
    // Normaliser la date à minuit pour éviter les problèmes de comparaison avec les heures
    final DateTime nowRaw = DateTime.now();
    final DateTime now = DateTime(nowRaw.year, nowRaw.month, nowRaw.day);
    
    _logger.debug('DateRangePickerWidget: Date normalisée: ${now.toString()}');
    
    // Si date initiale sélectionnée, la normaliser aussi à minuit
    DateTime? initialDateRaw = _selectedDateRange?.start;
    DateTime? initialDate;
    
    if (initialDateRaw != null) {
      initialDate = DateTime(initialDateRaw.year, initialDateRaw.month, initialDateRaw.day);
      _logger.debug('DateRangePickerWidget: Date initiale normalisée: ${initialDate.toString()}');
    }
    
    // Vérifier si la date initiale est valide (pas avant aujourd'hui)
    final validInitialDate = (initialDate != null && !initialDate.isBefore(now))
        ? initialDate
        : now;
        
    _logger.debug('DateRangePickerWidget: Date initiale valide: ${validInitialDate.toString()}');
    
    return Column(
      children: [
        Expanded(
          child: CalendarDatePicker(
            initialDate: validInitialDate,
            firstDate: now,
            lastDate: now.add(const Duration(days: 365 * 2)),
            onDateChanged: (date) {
              setModalState(() {
                if (_selectedDateRange == null) {
                  _selectedDateRange = DateTimeRange(
                    start: date,
                    end: date.add(const Duration(days: 2)),
                  );
                } else if (_selectedDateRange!.start.year == date.year && 
                          _selectedDateRange!.start.month == date.month && 
                          _selectedDateRange!.start.day == date.day ||
                          _selectedDateRange!.end.year == date.year && 
                          _selectedDateRange!.end.month == date.month && 
                          _selectedDateRange!.end.day == date.day) {
                  _selectedDateRange = null;
                } else if (date.isBefore(_selectedDateRange!.start)) {
                  _selectedDateRange = DateTimeRange(
                    start: date,
                    end: _selectedDateRange!.end,
                  );
                } else {
                  _selectedDateRange = DateTimeRange(
                    start: _selectedDateRange!.start,
                    end: date,
                  );
                }
                
                if (_selectedDateRange != null) {
                  _logger.info('DateRangePickerWidget: Sélection de dates mise à jour: ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} à ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}');
                } else {
                  _logger.info('DateRangePickerWidget: Sélection de dates effacée');
                }
              });
            },
            selectableDayPredicate: (date) {
              // Ne permettre que les dates à partir d'aujourd'hui (comparaison sur les jours uniquement)
              return date.isAtSameMomentAs(now) || date.isAfter(now);
            },
          ),
        ),
        
        // Options de flexibilité pour les dates exactes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _flexibilityOptions.map((option) {
                final isSelected = _selectedFlexibility == option;
                final scheme = Theme.of(context).colorScheme;
                final primaryColor = Theme.of(context).primaryColor;
                final borderColor = scheme.outline;
                final backgroundColor = isSelected 
                    ? primaryColor.withOpacity(0.1) 
                    : scheme.surfaceContainerLow;
                final textColor = isSelected 
                    ? primaryColor 
                    : scheme.onSurface.withOpacity(0.85);
                    
                return GestureDetector(
                  onTap: () {
                    setModalState(() {
                      _selectedFlexibility = option;
                      _logger.info('DateRangePickerWidget: Flexibilité sélectionnée: $_selectedFlexibility');
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? primaryColor : borderColor,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      color: backgroundColor,
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Construction de l'onglet dates flexibles
  Widget _buildFlexibleDatesTab(StateSetter setModalState) {
    // Générer les 3 prochains mois
    final DateTime nowRaw = DateTime.now();
    final DateTime now = DateTime(nowRaw.year, nowRaw.month, nowRaw.day);
    final months = List.generate(3, (index) {
      final month = DateTime(now.year, now.month + index);
      return {
        'date': month,
        'formatted': _formatMonth(month),
      };
    });

    // Thème et couleurs
    final scheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor = scheme.outline;
    final backgroundColor = scheme.surfaceContainerLow;
    final textColor = scheme.onSurface;
    final headingColor = scheme.onSurface;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Options de durée
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _flexibleOptions.map((option) {
                  final isSelected = _selectedFlexibleOption == option['text'];
                  final optionBgColor = isSelected 
                      ? primaryColor.withOpacity(0.1) 
                      : backgroundColor;
                  final optionTextColor = isSelected 
                      ? primaryColor 
                      : textColor;
                      
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _selectedFlexibleOption = option['text']!;
                        _logger.info('DateRangePickerWidget: Option flexible sélectionnée: ${option['text']}');
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8, bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? primaryColor : borderColor,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        color: optionBgColor,
                      ),
                      child: Text(
                        option['text']!,
                        style: TextStyle(
                          color: optionTextColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Sélection des mois
            Text(
              'Mois',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: headingColor,
              ),
              semanticsLabel: 'Sélection du mois',
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 20) / 3;
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: months.map((month) {
                    final DateTime monthDate = month['date'] as DateTime;
                    final isSelected = _selectedMonthDate != null && 
                        monthDate.month == _selectedMonthDate!.month && 
                        monthDate.year == _selectedMonthDate!.year;
                    final monthBgColor = isSelected 
                        ? primaryColor.withOpacity(0.1) 
                        : backgroundColor;
                    final monthTextColor = isSelected 
                        ? primaryColor 
                        : textColor;
                        
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            _selectedMonthDate = null;
                            _selectedMonthFormatted = '';
                            _selectedMonthIndex = 0;
                            _logger.info('DateRangePickerWidget: Sélection de mois effacée');
                          } else {
                            _selectedMonthDate = monthDate;
                            _selectedMonthFormatted = month['formatted'] as String;
                            _selectedMonthIndex = months.indexOf(month);
                            _logger.info('DateRangePickerWidget: Mois sélectionné: ${month['formatted']}');
                          }
                        });
                      },
                      child: Container(
                        width: itemWidth,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? primaryColor : borderColor,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: monthBgColor,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          month['formatted'] as String,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: monthTextColor,
                            fontSize: 14,
                          ),
                          semanticsLabel: 'Mois de ${month['formatted']}',
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 5,
      width: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(2.5),
      ),
    );
  }

  // Fonction pour obtenir le premier week-end d'un mois
  DateTime _getFirstWeekendOfMonth(DateTime date) {
    // Trouver le premier samedi du mois
    int daysUntilWeekend = (DateTime.saturday - date.weekday) % 7;
    return date.add(Duration(days: daysUntilWeekend));
  }

  String _formatMonth(DateTime date) {
    return DateFormat('MMM yyyy', 'fr_FR').format(date);
  }

  String _getSelectedDateRangeText() {
    if (_selectedDateRange == null) {
      return 'Aucune date sélectionnée';
    }
    
    final start = DateFormat('d MMM', 'fr_FR').format(_selectedDateRange!.start);
    final end = DateFormat('d MMM', 'fr_FR').format(_selectedDateRange!.end);
    final nights = _selectedDateRange!.duration.inDays;
    return '$start - $end (${nights > 1 ? '$nights nuits' : '1 nuit'})';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor = scheme.outline;
    final textColor = _selectedDateRange != null
        ? scheme.onSurface
        : scheme.onSurface.withOpacity(0.7);
    final backgroundColor = scheme.surface;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectDateRange,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
            color: backgroundColor,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 20, color: primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedDateRange != null
                    ? _getSelectedDateRangeText()
                    : 'Sélectionner des dates',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  semanticsLabel: _selectedDateRange != null
                    ? 'Dates sélectionnées: ${_getSelectedDateRangeText()}'
                    : 'Appuyez pour sélectionner des dates',
                ),
              ),
              if (_selectedDateRange != null)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateRange = null;
                      widget.onDateRangeSelected(null);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.clear, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
