import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart' as booking_events;
import 'package:chapechape_client/core/blocs/booking/booking_state.dart' as booking_states;
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/presentation/widgets/reservation_timer_widget.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';
import 'package:chapechape_client/core/models/reservation_status.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/presentation/widgets/common/empty_state_widget.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedFilter;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<BookingBloc>().add(booking_events.LoadUserBookings());
  }

  void _loadBookings() {
    context.read<BookingBloc>().add(booking_events.LoadUserBookings());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey[600],
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          tabs: const [
            Tab(text: 'Toutes'),
            Tab(text: 'À venir'),
            Tab(text: 'Passées'),
          ],
          onTap: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedFilter = null;
                  break;
                case 1:
                  _selectedFilter = 'upcoming';
                  break;
                case 2:
                  _selectedFilter = 'past';
                  break;
              }
            });
            _loadBookings();
          },
        ),
        Expanded(
          child: BlocConsumer<BookingBloc, booking_states.BookingState>(
            listener: (context, state) {
              setState(() {
                _isLoading = state is booking_states.BookingLoading;
              });

              if (state is booking_states.BookingError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              } else if (state is booking_states.BookingApproved ||
                         state is booking_states.BookingRejected ||
                         state is booking_states.BookingExpired) {
                _loadBookings();
              }
            },
            builder: (context, state) {
              if (state is booking_states.BookingLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (state is booking_states.UserBookingsLoaded) {
                return LoadingOverlay(
                  isLoading: _isLoading,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingList(state, null),
                      _buildBookingList(state, 'upcoming'),
                      _buildBookingList(state, 'past'),
                    ],
                  ),
                );
              }

              return const Center(
                child: Text('Chargement des réservations...'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingList(booking_states.BookingState state, String? filter) {
    if (state is booking_states.UserBookingsLoaded) {
      final bookings = _filterBookings(state.bookings, filter);

      if (bookings.isEmpty) {
        final imagePath = filter == 'upcoming'
            ? 'assets/images/empty_states/empty_Avenir_illustration.png'
            : filter == 'past'
                ? 'assets/images/empty_states/empty_passee_illustration.png'
                : 'assets/images/empty_states/empty_Toutes_illustration.png';

        final title = filter == 'upcoming'
            ? 'Aucune réservation à venir'
            : filter == 'past'
                ? 'Aucune réservation passée'
                : 'Aucune réservation';

        return EmptyStateWidget(
          imagePath: imagePath,
          title: title,
          subtitle:
              'Commencez votre aventure ! Réservez votre première résidence dès maintenant',
          action: ElevatedButton.icon(
            onPressed: () {
              context.goNamed('home');
            },
            icon: const Icon(Icons.search),
            label: const Text('Trouver une résidence'),
            style: ElevatedButton.styleFrom(
              padding: AppSpacing.buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          _loadBookings();
        },
        child: ListView.builder(
          padding: EdgeInsets.all(AppSpacing.sm),
          itemCount: bookings.length,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildBookingCard(bookings[index]);
          },
        ),
      );
    }

    return const Center(
      child: Text('Chargement des réservations...'),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(booking.status);
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            context.go('/booking-details/${booking.id}');
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête coloré selon le statut
              Container(
                padding: AppSpacing.buttonPadding,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            booking.residenceName ?? 'Résidence non spécifiée',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd + AppSpacing.sm),
                          ),
                          child: Text(
                            _getStatusText(booking.status),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Timer compact pour les réservations avec timers actifs
                    if (BookingHelpers.hasActiveTimer(booking)) ...[
                      AppSpacing.verticalSm,
                      Align(
                        alignment: Alignment.centerRight,
                        child: ReservationTimerWidget(
                          booking: booking,
                          displayMode: ReservationTimerDisplayMode.compact,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Détails de la réservation
              Padding(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.calendar_today,
                      '${dateFormat.format(booking.checkIn)} - ${dateFormat.format(booking.checkOut)}',
                    ),
                    AppSpacing.verticalSm,
                    _buildInfoRow(
                      Icons.people,
                      '${booking.numberOfGuests} personnes',
                    ),
                    AppSpacing.verticalSm,
                    _buildInfoRow(
                      Icons.nights_stay,
                      '${booking.nights} nuits',
                    ),
                    Divider(height: AppSpacing.lg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Prix total',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${booking.totalPrice.toStringAsFixed(0)} FCFA',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.verticalSm,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Statut de paiement',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: booking.isPaid ? AppTheme.successColor : Colors.orange,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd + AppSpacing.sm),
                          ),
                          child: Text(
                            booking.isPaid ? 'Payé' : 'En attente',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Actions
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: () {
                        context.go('/booking-details/${booking.id}');
                      },
                      child: const Text('Détails'),
                    ),
                    if (booking.status == ReservationStatusCanon.paymentPending)
                      ElevatedButton(
                        onPressed: () {
                          context.go('/payment/${booking.id}');
                        },
                        child: const Text('Payer'),
                      ),
                    if (booking.status == 'confirmed' && 
                        booking.checkIn.isAfter(DateTime.now()))
                      TextButton(
                        onPressed: () {
                          context.go('/booking-modify/${booking.id}');
                        },
                        child: const Text('Modifier'),
                      ),
                    if (booking.status == 'pending' || booking.status == 'confirmed')
                      TextButton(
                        onPressed: () {
                          _showCancelDialog(booking.id);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Annuler'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette réservation ? Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BookingBloc>().add(
                booking_events.CancelBooking(bookingId: bookingId),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  List<Booking> _filterBookings(List<Booking> bookings, String? filter) {
    if (filter == null) return bookings;

    final now = DateTime.now();
    
    if (filter == 'upcoming') {
      return bookings.where((b) => ReservationStatusCanon.isUpcoming(
            b.status,
            b.checkIn,
            now,
          )).toList();
    } else if (filter == 'past') {
      return bookings.where((b) => ReservationStatusCanon.isPast(
            b.status,
            b.checkOut,
            now,
          )).toList();
    }
    
    return bookings;
  }



  String _getStatusText(String status) {
    return BookingHelpers.getStatusLabel(status);
  }

  Color _getStatusColor(String status) {
    return BookingHelpers.getStatusColor(status);
  }


} 