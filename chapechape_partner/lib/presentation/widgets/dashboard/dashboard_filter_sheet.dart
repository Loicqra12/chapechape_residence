import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/blocs/dashboard/dashboard_bloc.dart';

class DashboardFilterSheet extends StatefulWidget {
  final String currentPeriod;
  final String? startDate;
  final String? endDate;

  const DashboardFilterSheet({
    super.key, 
    required this.currentPeriod,
    this.startDate,
    this.endDate,
  });

  @override
  State<DashboardFilterSheet> createState() => _DashboardFilterSheetState();
}

class _DashboardFilterSheetState extends State<DashboardFilterSheet> {
  late String selectedPeriod;
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;
  
  final List<String> periodOptions = [
    'today',
    'week',
    'month',
    'quarter',
    'year',
    'custom',
  ];

  final Map<String, String> periodLabels = {
    'today': 'Aujourd\'hui',
    'week': 'Cette semaine',
    'month': 'Ce mois',
    'quarter': 'Ce trimestre',
    'year': 'Cette année',
    'custom': 'Période personnalisée',
  };

  @override
  void initState() {
    super.initState();
    selectedPeriod = widget.currentPeriod;
    
    // Convertir les dates string en DateTime si disponibles
    if (widget.startDate != null) {
      try {
        selectedStartDate = DateTime.parse(widget.startDate!);
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    }
    
    if (widget.endDate != null) {
      try {
        selectedEndDate = DateTime.parse(widget.endDate!);
      } catch (e) {
        // Ignorer les erreurs de parsing
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtrer le tableau de bord',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Période',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: periodOptions.map((period) {
              return ChoiceChip(
                label: Text(periodLabels[period] ?? period),
                selected: selectedPeriod == period,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      selectedPeriod = period;
                      
                      // Réinitialiser les dates si ce n'est pas une période personnalisée
                      if (period != 'custom') {
                        selectedStartDate = null;
                        selectedEndDate = null;
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
          if (selectedPeriod == 'custom') ...[
            const SizedBox(height: 16),
            const Text(
              'Plage de dates',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de début',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        selectedStartDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedStartDate!)
                            : 'Sélectionner',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date de fin',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        selectedEndDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedEndDate!)
                            : 'Sélectionner',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilter,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Appliquer les filtres'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? selectedStartDate ?? DateTime.now()
          : selectedEndDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          selectedStartDate = picked;
          // Ajuster la date de fin si elle est antérieure à la date de début
          if (selectedEndDate != null && selectedEndDate!.isBefore(picked)) {
            selectedEndDate = picked;
          }
        } else {
          selectedEndDate = picked;
          // Ajuster la date de début si elle est postérieure à la date de fin
          if (selectedStartDate != null && selectedStartDate!.isAfter(picked)) {
            selectedStartDate = picked;
          }
        }
      });
    }
  }

  void _applyFilter() {
    // Format des dates pour l'API
    final String? formattedStartDate = selectedStartDate != null 
        ? DateFormat('yyyy-MM-dd').format(selectedStartDate!) 
        : null;
        
    final String? formattedEndDate = selectedEndDate != null 
        ? DateFormat('yyyy-MM-dd').format(selectedEndDate!) 
        : null;
        
    // Dispatch l'événement pour changer la période
    context.read<DashboardBloc>().add(
      ChangePeriod(
        period: selectedPeriod,
        startDate: formattedStartDate,
        endDate: formattedEndDate,
      ),
    );
    
    // Fermer le bottom sheet
    Navigator.pop(context);
  }
}
