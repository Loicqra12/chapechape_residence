import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive_utils.dart';
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
  
  // Options pour les dates flexibles
  String _selectedFlexibleOption = 'Un weekend';
  String _selectedMonth = '';
  int _selectedMonthIndex = 0;
  
  // Options pour les dates exactes
  String _selectedFlexibility = 'Dates exactes';
  
  final List<String> _flexibleOptions = ['Un weekend', 'Une semaine', 'Un mois'];
  final List<String> _flexibilityOptions = ['Dates exactes', '± 1 jour', '± 2 jours', '± 3 jours'];

  @override
  void initState() {
    super.initState();
    _selectedDateRange = widget.initialDateRange;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    
    // Initialiser le mois sélectionné au mois courant
    final now = DateTime.now();
    _selectedMonth = _formatMonth(now);
  }

  @override
  void dispose() {
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
                    unselectedLabelColor: Colors.grey,
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
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
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
                              ? '$_selectedFlexibleOption en ${_selectedMonth.split(' ').first}'
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
                              foregroundColor: Colors.white,
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
    return Column(
      children: [
        Expanded(
          child: CalendarDatePicker(
            initialDate: _selectedDateRange?.start ?? DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            onDateChanged: (date) {
              setModalState(() {
                if (_selectedDateRange == null) {
                  _selectedDateRange = DateTimeRange(
                    start: date,
                    end: date.add(const Duration(days: 2)),
                  );
                } else if (_selectedDateRange!.start == date || 
                          _selectedDateRange!.end == date) {
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
              });
            },
            selectableDayPredicate: (date) {
              // Vous pouvez ajouter une logique pour désactiver certaines dates
              return true;
            },
          ),
        ),
        
        // Options de flexibilité pour les dates exactes
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _flexibilityOptions.map((option) {
                final isSelected = _selectedFlexibility == option;
                return GestureDetector(
                  onTap: () {
                    setModalState(() {
                      _selectedFlexibility = option;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryColor : Colors.black,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
    final now = DateTime.now();
    final months = List.generate(3, (index) {
      final month = DateTime(now.year, now.month + index);
      return {
        'date': month,
        'formatted': _formatMonth(month),
      };
    });

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Options de durée
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _flexibleOptions.map((option) {
                  final isSelected = _selectedFlexibleOption == option;
                  return GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _selectedFlexibleOption = option;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text(
              'Quand voulez-vous partir ?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Choisissez 3 mois au maximum',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            
            const SizedBox(height: 16),
            // Sélection des mois
            Row(
              children: months.map((month) {
                final isSelected = _selectedMonth == month['formatted'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _selectedMonth = month['formatted'] as String;
                        _selectedMonthIndex = months.indexOf(month);
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.calendar_today, size: 30),
                          const SizedBox(height: 8),
                          Text(
                            (month['formatted'] as String).split(' ').first,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            (month['formatted'] as String).split(' ').last,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
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
        color: Colors.grey[300],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _selectDateRange,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(10),
          ),
            child: Row(
              children: [
              Icon(Icons.calendar_today, size: 20, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedDateRange != null
                      ? _getSelectedDateRangeText()
                      : 'Sélectionner des dates',
                    style: TextStyle(
                    color: _selectedDateRange != null ? Colors.black : Colors.grey,
                    ),
                  ),
                ),
                if (_selectedDateRange != null)
                  IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        _selectedDateRange = null;
                      widget.onDateRangeSelected(null);
                    });
                    },
                  ),
              ],
          ),
        ),
      ),
    );
  }
}
