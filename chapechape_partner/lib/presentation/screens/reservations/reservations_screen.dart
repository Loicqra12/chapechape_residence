import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/blocs/reservation/reservation_bloc.dart';
import '../../../core/models/reservation/reservation.dart';
import '../../widgets/layout/screen_app_bars.dart';
import '../../widgets/calendar/reservation_calendar_widget.dart';
import '../../widgets/skeletons/skeletons.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ReservationsView();
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
          ScreenAppBars.getReservationsAppBar(
            context,
            reservationBloc: context.read<ReservationBloc>(),
            onCalendarTap: () {
              if (_tabController.index == 1) {
                _tabController.animateTo(0);
              } else {
                _tabController.animateTo(1);
              }
            },
          ),
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
                  return SliverFillRemaining(
                    child: _buildEmptyReservationsState(context),
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

  Widget _buildEmptyReservationsState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/illustrations/empty_reservation.png',
                width: MediaQuery.of(context).size.width * 0.65,
                height: MediaQuery.of(context).size.width * 0.65,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.calendar_today_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Aucune réservation trouvée',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Vous n\'avez pas encore de réservations. Les demandes de réservation apparaîtront ici.',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _reservationStatusIcon(ReservationStatus status) {
  switch (status) {
    case ReservationStatus.pending:
      return Icons.schedule_rounded;
    case ReservationStatus.confirmed:
      return Icons.check_circle_rounded;
    case ReservationStatus.cancelled:
      return Icons.cancel_rounded;
    case ReservationStatus.completed:
      return Icons.done_all_rounded;
    case ReservationStatus.awaitingApproval:
      return Icons.pending_actions_rounded;
    case ReservationStatus.paymentPending:
      return Icons.payments_rounded;
    case ReservationStatus.rejected:
      return Icons.block_rounded;
    case ReservationStatus.paymentExpired:
      return Icons.timer_off_rounded;
    case ReservationStatus.paymentProcessing:
      return Icons.sync_rounded;
    case ReservationStatus.inStay:
      return Icons.hotel_rounded;
    case ReservationStatus.expired:
      return Icons.event_busy_rounded;
    case ReservationStatus.refunded:
      return Icons.currency_exchange_rounded;
  }
}

Color _reservationStatusColor(ReservationStatus status) {
  return Color(int.parse(status.color.replaceAll('#', '0xFF')));
}

Future<void> _openReservationActionsSheet(
  BuildContext context, {
  required Reservation reservation,
  required void Function(ReservationStatus) onStatusUpdate,
  required VoidCallback onCancel,
}) {
  final theme = Theme.of(context);
  final others = ReservationStatus.values
      .where((s) => s != reservation.status)
      .toList()
    ..sort((a, b) => a.displayName.compareTo(b.displayName));

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.paddingOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Changer le statut',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reservation.residenceName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              _reservationStatusIcon(reservation.status),
                              color: theme.colorScheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Statut actuel',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    reservation.status.displayName,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    ...others.map((status) {
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _reservationStatusIcon(status),
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          status.displayName,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.outline,
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(sheetContext).pop();
                          onStatusUpdate(status);
                        },
                      );
                    }),
                    if (reservation.status != ReservationStatus.cancelled) ...[
                      const Divider(height: 24),
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.cancel_outlined,
                            color: theme.colorScheme.error,
                            size: 22,
                          ),
                        ),
                        title: Text(
                          'Annuler la réservation',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.error,
                          ),
                        ),
                        onTap: () async {
                          Navigator.of(sheetContext).pop();
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Annuler la réservation'),
                              content: const Text(
                                'Cette action est en général irréversible. Confirmer l\'annulation ?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('Non'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error,
                                    foregroundColor: theme.colorScheme.onError,
                                  ),
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  child: const Text('Annuler'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            onCancel();
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final void Function(ReservationStatus) onStatusUpdate;
  final VoidCallback onCancel;

  const _ReservationCard({
    required this.reservation,
    required this.onStatusUpdate,
    required this.onCancel,
  });

  void _goDetails(BuildContext context) {
    context.go('/reservations/${reservation.id}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _reservationStatusColor(reservation.status);

    return Card(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.45),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _goDetails(context),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: Image.network(
                        reservation.residenceImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.home_work_outlined,
                            size: 36,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _goDetails(context),
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                reservation.residenceName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            tooltip: 'Actions',
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _openReservationActionsSheet(
                                context,
                                reservation: reservation,
                                onStatusUpdate: onStatusUpdate,
                                onCancel: onCancel,
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _goDetails(context),
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CompactInfoRow(
                              icon: Icons.person_outline_rounded,
                              text: reservation.clientName,
                            ),
                            const SizedBox(height: 4),
                            _CompactInfoRow(
                              icon: Icons.calendar_today_rounded,
                              text: reservation.formattedDates,
                            ),
                            const SizedBox(height: 4),
                            _CompactInfoRow(
                              icon: Icons.people_outline_rounded,
                              text:
                                  '${reservation.guestsCount} personne${reservation.guestsCount > 1 ? 's' : ''}',
                            ),
                            if (reservation.notes != null &&
                                reservation.notes!.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _CompactInfoRow(
                                icon: Icons.notes_rounded,
                                text: reservation.notes!.trim(),
                                maxLines: 1,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _goDetails(context),
              behavior: HitTestBehavior.opaque,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      reservation.clientPhone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        reservation.formattedTotalAmount,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Total séjour',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _goDetails(context),
              behavior: HitTestBehavior.opaque,
              child: Align(
                alignment: Alignment.centerRight,
                child: _StatusPill(
                  label: reservation.status.displayName,
                  color: statusColor,
                  icon: _reservationStatusIcon(reservation.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _CompactInfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.25,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
