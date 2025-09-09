import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/config/theme.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ModificationHistoryWidget extends StatefulWidget {
  final List<Map<String, dynamic>> modifications;
  final String bookingId;

  const ModificationHistoryWidget({
    Key? key,
    required this.modifications,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<ModificationHistoryWidget> createState() => _ModificationHistoryWidgetState();
}

class _ModificationHistoryWidgetState extends State<ModificationHistoryWidget> {
  String _selectedStatus = 'all';
  String _sortBy = 'date';
  bool _sortDescending = true;
  int _currentPage = 1;
  static const int _itemsPerPage = 5;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Rafraîchir toutes les 30 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      context.read<BookingBloc>().add(
        LoadBookingDetails(bookingId: widget.bookingId),
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredModifications {
    var filtered = widget.modifications;

    // Filtrer par statut
    if (_selectedStatus != 'all') {
      filtered = filtered.where((m) => m['status'] == _selectedStatus).toList();
    }

    // Trier
    filtered.sort((a, b) {
      if (_sortBy == 'date') {
        final dateA = DateTime.parse(a['modifiedAt']);
        final dateB = DateTime.parse(b['modifiedAt']);
        return _sortDescending ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
      } else if (_sortBy == 'fee') {
        final feeA = a['fee'] as double;
        final feeB = b['fee'] as double;
        return _sortDescending ? feeB.compareTo(feeA) : feeA.compareTo(feeB);
      }
      return 0;
    });

    return filtered;
  }

  List<Map<String, dynamic>> get _paginatedModifications {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredModifications.sublist(
      startIndex,
      endIndex > _filteredModifications.length ? _filteredModifications.length : endIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.modifications.isEmpty) {
      return const Center(
        child: Text('Aucune modification enregistrée'),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filtres et tri
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              // Filtre par statut
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tous')),
                    DropdownMenuItem(value: 'pending', child: Text('En attente')),
                    DropdownMenuItem(value: 'approved', child: Text('Approuvé')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejeté')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Tri
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Trier par',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'date', child: Text('Date')),
                    DropdownMenuItem(value: 'fee', child: Text('Frais')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Ordre de tri
              IconButton(
                icon: Icon(_sortDescending ? Icons.arrow_downward : Icons.arrow_upward),
                onPressed: () {
                  setState(() {
                    _sortDescending = !_sortDescending;
                    _currentPage = 1;
                  });
                },
              ),
            ],
          ),
        ),

        // Liste des modifications - Utilisation de Column au lieu de ListView pour éviter les conflits
        ..._paginatedModifications.map((modification) {
          final date = DateTime.parse(modification['modifiedAt']);
          final changes = modification['changes'] as Map<String, dynamic>;
          final fee = modification['fee'] as double;
          final status = modification['status'] as String;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      _buildStatusChip(status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...changes.entries.map((entry) => _buildChangeItem(
                    context,
                    entry.key,
                    entry.value['from'],
                    entry.value['to'],
                  )),
                  if (fee > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Frais de modification: ${fee.toStringAsFixed(2)} FCFA',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        // Pagination
        if (_filteredModifications.length > _itemsPerPage)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                        }
                      : null,
                ),
                Flexible(
                  child: Text(
                    'Page $_currentPage sur ${(_filteredModifications.length / _itemsPerPage).ceil()}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < (_filteredModifications.length / _itemsPerPage).ceil()
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'En attente';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approuvé';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejeté';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildChangeItem(
    BuildContext context,
    String field,
    dynamic oldValue,
    dynamic newValue,
  ) {
    String fieldLabel;
    String formatValue(dynamic value) {
      if (value == null) return 'Non spécifié';
      if (value is DateTime) {
        return DateFormat('dd/MM/yyyy').format(value);
      }
      return value.toString();
    }

    switch (field) {
      case 'checkIn':
        fieldLabel = 'Date d\'arrivée';
        break;
      case 'checkOut':
        fieldLabel = 'Date de départ';
        break;
      case 'numberOfGuests':
        fieldLabel = 'Nombre de voyageurs';
        break;
      case 'specialRequests':
        fieldLabel = 'Demandes spéciales';
        break;
      default:
        fieldLabel = field;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                fieldLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avant: ${formatValue(oldValue)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  Text(
                    'Après: ${formatValue(newValue)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 