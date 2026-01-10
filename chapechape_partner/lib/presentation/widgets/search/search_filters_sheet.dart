import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/services/global_search_service.dart';

/// Feuille de filtres avancés pour la recherche
class SearchFiltersSheet extends StatefulWidget {
  final SearchFilters? currentFilters;
  final SearchCategory currentCategory;
  final Function(SearchFilters) onApplyFilters;
  final VoidCallback onClearFilters;

  const SearchFiltersSheet({
    super.key,
    this.currentFilters,
    required this.currentCategory,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends State<SearchFiltersSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _status;
  double? _minPrice;
  double? _maxPrice;
  String? _city;

  @override
  void initState() {
    super.initState();
    // Initialiser avec les filtres existants
    if (widget.currentFilters != null) {
      _startDate = widget.currentFilters!.startDate;
      _endDate = widget.currentFilters!.endDate;
      _status = widget.currentFilters!.status;
      _minPrice = widget.currentFilters!.minPrice;
      _maxPrice = widget.currentFilters!.maxPrice;
      _city = widget.currentFilters!.city;
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
    }
  }

  void _applyFilters() {
    final filters = SearchFilters(
      startDate: _startDate,
      endDate: _endDate,
      status: _status,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      city: _city,
    );

    widget.onApplyFilters(filters);
    Navigator.pop(context);
  }

  void _clearAllFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _status = null;
      _minPrice = null;
      _maxPrice = null;
      _city = null;
    });

    widget.onClearFilters();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtres',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Contenu des filtres
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtres de dates
                  _buildSectionTitle('Période'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateField(
                          label: 'Date début',
                          date: _startDate,
                          onTap: _selectStartDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDateField(
                          label: 'Date fin',
                          date: _endDate,
                          onTap: _selectEndDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filtre de statut
                  _buildSectionTitle('Statut'),
                  Wrap(
                    spacing: 8,
                    children: _getStatusOptions().map((status) {
                      final isSelected = _status == status;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(status),
                        onSelected: (selected) {
                          setState(() {
                            _status = selected ? status : null;
                          });
                        },
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: theme.colorScheme.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Filtre de prix
                  _buildSectionTitle('Prix (FCFA/nuit)'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Prix min',
                            border: OutlineInputBorder(),
                            prefixText: '',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _minPrice = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Prix max',
                            border: OutlineInputBorder(),
                            prefixText: '',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _maxPrice = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filtre de ville
                  _buildSectionTitle('Ville'),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    onChanged: (value) {
                      _city = value.isEmpty ? null : value;
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearAllFilters,
                    child: const Text('Effacer tout'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    child: const Text('Appliquer les filtres'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null ? DateFormat('dd/MM/yyyy').format(date) : '',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  List<String> _getStatusOptions() {
    switch (widget.currentCategory) {
      case SearchCategory.residences:
        return ['Actif', 'Inactif', 'En maintenance'];
      case SearchCategory.reservations:
        return ['Confirmé', 'En attente', 'Annulé', 'Terminé'];
      case SearchCategory.messages:
        return ['Non lu', 'Lu', 'Archivé'];
      case SearchCategory.notifications:
        return ['Non lu', 'Lu'];
      default:
        return ['Actif', 'Inactif'];
    }
  }
}


