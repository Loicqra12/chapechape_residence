import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/blocs/reservation/reservation_bloc.dart';
import '../../../core/models/reservation/reservation.dart';
import '../../../core/services/api/reservation_service.dart';
import '../../../core/services/api/api_service.dart';
import '../../widgets/layout/screen_app_bars.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReservationBloc(
        context.read<ReservationService>(),
      )..add(LoadMyReservations()),
      child: const _ReservationsView(),
    );
  }
}

class _ReservationsView extends StatefulWidget {
  const _ReservationsView();

  @override
  State<_ReservationsView> createState() => _ReservationsViewState();
}

class _ReservationsViewState extends State<_ReservationsView> {
  ReservationStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  void _loadReservations() {
    print("Chargement des réservations partenaire...");
    context.read<ReservationBloc>().add(LoadPartnerReservations());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ScreenAppBars.getReservationsAppBar(context),
          BlocBuilder<ReservationBloc, ReservationState>(
            builder: (context, state) {
              if (state is ReservationLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (state is ReservationError) {
                print("Erreur de chargement des réservations: ${state.message}");
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      state.message,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                );
              }

              if (state is ReservationLoaded) {
                print("Réservations chargées: ${state.reservations.length}");
                if (state.reservations.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text('Aucune réservation trouvée'),
                    ),
                  );
                }

                final filteredReservations = _selectedStatus != null
                    ? state.reservations
                        .where((r) => r.status == _selectedStatus)
                        .toList()
                    : state.reservations;

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reservation = filteredReservations[index];
                      return _ReservationCard(
                        reservation: reservation,
                        onStatusUpdate: (status) {
                          context.read<ReservationBloc>().add(
                                UpdateReservationStatus(
                                  reservation.id,
                                  status,
                                ),
                              );
                        },
                        onCancel: () {
                          context.read<ReservationBloc>().add(
                                CancelReservation(reservation.id),
                              );
                        },
                      );
                    },
                    childCount: filteredReservations.length,
                  ),
                );
              }

              return const SliverFillRemaining(
                child: Center(
                  child: Text('Chargement des réservations...'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final ReservationStatus? status = await showDialog<ReservationStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrer par statut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReservationStatus.values.map((status) {
            return ListTile(
              title: Text(status.displayName),
              leading: Icon(
                Icons.circle,
                color: Color(
                  int.parse(
                    status.color.replaceAll('#', '0xFF'),
                  ),
                ),
              ),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Tout afficher'),
          ),
        ],
      ),
    );

    if (mounted) {
      setState(() => _selectedStatus = status);
    }
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final Function(ReservationStatus) onStatusUpdate;
  final VoidCallback onCancel;

  const _ReservationCard({
    required this.reservation,
    required this.onStatusUpdate,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = Color(
      int.parse(
        reservation.status.color.replaceAll('#', '0xFF'),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.go('/reservations/${reservation.id}');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                reservation.residenceImage,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reservation.residenceName,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          reservation.status.displayName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        reservation.clientName[0].toUpperCase(),
                      ),
                    ),
                    title: Text(reservation.clientName),
                    subtitle: Text(reservation.clientPhone),
                  ),
                  
                  const Divider(),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _DetailItem(
                          icon: Icons.calendar_today,
                          label: 'Dates',
                          value: reservation.formattedDates,
                        ),
                      ),
                      Expanded(
                        child: _DetailItem(
                          icon: Icons.people,
                          label: 'Voyageurs',
                          value: '${reservation.guestsCount} personne${reservation.guestsCount > 1 ? 's' : ''}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _DetailItem(
                          icon: Icons.attach_money,
                          label: 'Montant',
                          value: reservation.formattedTotalAmount,
                        ),
                      ),
                      Expanded(
                        child: _DetailItem(
                          icon: Icons.access_time,
                          label: 'Créée le',
                          value: reservation.formattedCreatedAt,
                        ),
                      ),
                    ],
                  ),
                  
                  if (reservation.notes != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reservation.notes!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (reservation.status != ReservationStatus.cancelled)
                        TextButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.cancel),
                          label: const Text('Annuler'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<ReservationStatus>(
                        itemBuilder: (context) {
                          return ReservationStatus.values
                              .where((s) => s != reservation.status)
                              .map((status) {
                            return PopupMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 12,
                                    color: Color(
                                      int.parse(
                                        status.color.replaceAll('#', '0xFF'),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(status.displayName),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        onSelected: onStatusUpdate,
                        child: TextButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.edit),
                          label: const Text('Changer le statut'),
                        ),
                      ),
                    ],
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

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
