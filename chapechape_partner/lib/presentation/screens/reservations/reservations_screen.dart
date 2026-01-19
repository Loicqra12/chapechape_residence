import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/blocs/reservation/reservation_bloc.dart';
import '../../../core/models/reservation/reservation.dart';
import '../../../core/services/api/reservation_service.dart';
import '../../../core/services/api/api_service.dart';
import '../../widgets/layout/screen_app_bars.dart';
import '../../widgets/calendar/reservation_calendar_widget.dart';
import '../../widgets/skeletons/skeletons.dart';

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

class _ReservationsViewState extends State<_ReservationsView> with SingleTickerProviderStateMixin {
  ReservationStatus? _selectedStatus;
  late TabController _tabController;
  DateTime? _selectedCalendarDay;
  List<Reservation> _selectedDayReservations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadReservations() {
    context.read<ReservationBloc>().add(LoadPartnerReservations());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          ScreenAppBars.getReservationsAppBar(context, reservationBloc: context.read<ReservationBloc>()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabsHeaderDelegate(
              TabBar(
                controller: _tabController,
                labelColor: theme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: theme.primaryColor,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.list),
                    text: 'Liste',
                  ),
                  Tab(
                    icon: Icon(Icons.calendar_month),
                    text: 'Calendrier',
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildListView(context, theme),
            _buildCalendarView(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, ThemeData theme) {
    return CustomScrollView(
      slivers: [
        BlocBuilder<ReservationBloc, ReservationState>(
            builder: (context, state) {
              if (state is ReservationLoading) {
                return const SliverFillRemaining(
                  child: ReservationListSkeleton(itemCount: 4),
                );
              }

              if (state is ReservationError) {
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

  Widget _buildCalendarView(BuildContext context, ThemeData theme) {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, state) {
        if (state is ReservationLoading) {
          return const Center(
            child: ReservationListSkeleton(itemCount: 3),
          );
        }

        if (state is ReservationError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadReservations,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (state is ReservationLoaded) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ReservationCalendarWidget(
              reservations: state.reservations,
              selectedDay: _selectedCalendarDay,
              onDaySelected: (day, reservations) {
                setState(() {
                  _selectedCalendarDay = day;
                  _selectedDayReservations = reservations;
                });
              },
            ),
          );
        }

        return const Center(
          child: Text('Aucune donnée disponible'),
        );
      },
    );
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

  /// Retourne l'icône appropriée pour chaque statut
  IconData _getStatusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Icons.schedule;
      case ReservationStatus.confirmed:
        return Icons.check_circle;
      case ReservationStatus.cancelled:
        return Icons.cancel;
      case ReservationStatus.completed:
        return Icons.done_all;
      case ReservationStatus.awaitingApproval:
        return Icons.pending_actions;
      case ReservationStatus.paymentPending:
        return Icons.payment;
      case ReservationStatus.rejected:
        return Icons.block;
      case ReservationStatus.paymentExpired:
        return Icons.timer_off;
      case ReservationStatus.paymentProcessing:
        return Icons.sync;
      case ReservationStatus.inStay:
        return Icons.hotel;
      case ReservationStatus.expired:
        return Icons.event_busy;
      case ReservationStatus.refunded:
        return Icons.money_off;
    }
  }

  /// Convertit la couleur hex en Color
  Color _getStatusColor(ReservationStatus status) {
    return Color(
      int.parse(
        status.color.replaceAll('#', '0xFF'),
      ),
    );
  }

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
                  
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (reservation.status != ReservationStatus.cancelled)
                        TextButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Annuler'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      PopupMenuButton<ReservationStatus>(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        itemBuilder: (context) {
                          final currentStatusColor = _getStatusColor(reservation.status);
                          final currentStatusIcon = _getStatusIcon(reservation.status);
                          
                          return [
                            // Statut actuel (non cliquable, grisé)
                            PopupMenuItem<ReservationStatus>(
                              enabled: false,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: currentStatusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      currentStatusIcon,
                                      size: 18,
                                      color: currentStatusColor.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Statut actuel',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          reservation.status.displayName,
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Séparateur
                            const PopupMenuDivider(),
                            // Autres statuts disponibles
                            ...ReservationStatus.values
                                .where((s) => s != reservation.status)
                                .map((status) {
                              final statusColor = _getStatusColor(status);
                              final statusIcon = _getStatusIcon(status);
                              
                              return PopupMenuItem<ReservationStatus>(
                                value: status,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Semantics(
                                  label: 'Changer le statut à ${status.displayName}',
                                  button: true,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          statusIcon,
                                          size: 18,
                                          color: statusColor,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          status.displayName,
                                          style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ];
                        },
                        onSelected: (status) {
                          HapticFeedback.mediumImpact();
                          onStatusUpdate(status);
                        },
                        child: Semantics(
                          label: 'Changer le statut de la réservation',
                          button: true,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.edit, size: 18),
                                const SizedBox(width: 4),
                                const Text('Statut'),
                              ],
                            ),
                          ),
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

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabsHeaderDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabsHeaderDelegate oldDelegate) => false;
}
