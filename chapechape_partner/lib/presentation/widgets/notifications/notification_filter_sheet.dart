import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/notification/notification_bloc.dart';
import '../../../core/blocs/notification/notification_event.dart';

class NotificationFilterSheet extends StatefulWidget {
  const NotificationFilterSheet({super.key});

  @override
  State<NotificationFilterSheet> createState() => _NotificationFilterSheetState();
}

class _NotificationFilterSheetState extends State<NotificationFilterSheet> {
  // Type de notification sélectionné
  String? _selectedType;
  
  // État de lecture sélectionné
  String? _selectedReadStatus;
  
  // Dates de filtrage
  DateTime? _startDate;
  DateTime? _endDate;

  // Types de notifications disponibles
  final List<Map<String, String>> _notificationTypes = [
    {'value': 'all', 'label': 'Toutes les notifications'},
    {'value': 'booking', 'label': 'Réservations'},
    {'value': 'payment', 'label': 'Paiements'},
    {'value': 'message', 'label': 'Messages'},
    {'value': 'reminder', 'label': 'Rappels'},
    {'value': 'support', 'label': 'Support'},
    {'value': 'system', 'label': 'Système'},
  ];

  // Options d'état de lecture
  final List<Map<String, String>> _readStatusOptions = [
    {'value': 'all', 'label': 'Toutes les notifications'},
    {'value': 'read', 'label': 'Lues'},
    {'value': 'unread', 'label': 'Non lues'},
  ];

  @override
  void initState() {
    super.initState();
    // Valeurs par défaut
    _selectedType = 'all';
    _selectedReadStatus = 'all';
    
    // Dates par défaut: derniers 30 jours
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
  }

  // Applique les filtres et ferme la feuille
  void _applyFilter() {
    // Déterminer si on filtre par statut de lecture
    final bool? isRead;
    if (_selectedReadStatus == 'all') {
      isRead = null;
    } else {
      isRead = _selectedReadStatus == 'read';
    }
    
    // Créer un événement de filtrage avec les valeurs sélectionnées
    context.read<NotificationBloc>().add(
      FilterNotifications(
        type: _selectedType == 'all' ? null : _selectedType,
        isRead: isRead,
        startDate: _startDate,
        endDate: _endDate,
      ),
    );
    
    Navigator.pop(context);
  }

  // Réinitialise les filtres aux valeurs par défaut
  void _resetFilters() {
    setState(() {
      _selectedType = 'all';
      _selectedReadStatus = 'all';
      _endDate = DateTime.now();
      _startDate = _endDate!.subtract(const Duration(days: 30));
    });
  }

  // Sélection d'une date de début
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: _endDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  // Sélection d'une date de fin
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtrer les notifications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Filtre par type
          const Text('Type de notification'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: _notificationTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['value'],
                child: Text(type['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Filtre par statut de lecture
          const Text('Statut de lecture'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedReadStatus,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: _readStatusOptions.map((status) {
              return DropdownMenuItem<String>(
                value: status['value'],
                child: Text(status['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedReadStatus = value;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Filtre par date
          const Text('Période'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectStartDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      _startDate != null
                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                          : 'Date de début',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: _selectEndDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text(
                      _endDate != null
                          ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                          : 'Date de fin',
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Réinitialiser'),
              ),
              ElevatedButton(
                onPressed: _applyFilter,
                child: const Text('Appliquer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
