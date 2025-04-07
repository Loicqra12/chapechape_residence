import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart' as booking_events;
import 'package:chapechape_client/core/blocs/booking/booking_state.dart' as booking_states;
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/config/theme.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
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
      ),
      body: BlocConsumer<BookingBloc, booking_states.BookingState>(
        listener: (context, state) {
          setState(() {
            _isLoading = state is booking_states.BookingLoading;
          });

          if (state is booking_states.BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is booking_states.BookingLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is booking_states.UserBookingsLoaded) {
            final List<Booking> bookings = state.bookings;

            if (bookings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 72,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucune réservation trouvée',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Vous n\'avez pas encore de réservations',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return LoadingOverlay(
              isLoading: _isLoading,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Onglet "Toutes"
                  _buildBookingList(state, null),
                  // Onglet "À venir"
                  _buildBookingList(state, 'upcoming'),
                  // Onglet "Passées"
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/residences');
        },
        child: const Icon(Icons.add),
        tooltip: 'Nouvelle réservation',
      ),
    );
  }

  Widget _buildBookingList(booking_states.BookingState state, String? filter) {
    if (state is booking_states.UserBookingsLoaded) {
      final bookings = _filterBookings(state.bookings, filter);

      if (bookings.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune réservation ${_getFilterText(filter)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.go('/residences');
                },
                icon: const Icon(Icons.search),
                label: const Text('Trouver une résidence'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          _loadBookings();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: bookings.length,
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
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: () {
          context.go('/booking-details/${booking.id}');
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête coloré selon le statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.residenceName ?? 'Résidence non spécifiée',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Détails de la réservation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${dateFormat.format(booking.checkIn)} - ${dateFormat.format(booking.checkOut)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${booking.numberOfGuests} personnes',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.nights_stay, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${booking.nights} nuits',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const Divider(height: 24),
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
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Statut de paiement',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: booking.isPaid ? AppTheme.successColor : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          booking.isPaid ? 'Payé' : 'En attente',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      context.go('/booking-details/${booking.id}');
                    },
                    child: const Text('Détails'),
                  ),
                  if (!booking.isPaid)
                    TextButton(
                      onPressed: () {
                        context.go('/booking-payment/${booking.id}');
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
      return bookings.where((b) => b.checkIn.isAfter(now) || 
                                 b.status == 'pending' || 
                                 b.status == 'confirmed').toList();
    } else if (filter == 'past') {
      return bookings.where((b) => b.checkOut.isBefore(now) || 
                                 b.status == 'completed' || 
                                 b.status == 'cancelled').toList();
    }
    
    return bookings;
  }

  String _getFilterText(String? filter) {
    if (filter == 'upcoming') return 'à venir';
    if (filter == 'past') return 'passée';
    return 'trouvée';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'cancelled':
        return 'Annulée';
      case 'completed':
        return 'Terminée';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return AppTheme.primaryColor;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return AppTheme.successColor;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 