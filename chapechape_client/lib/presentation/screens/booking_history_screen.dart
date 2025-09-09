import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart';
import 'package:chapechape_client/core/blocs/booking/booking_state.dart';
import 'package:chapechape_client/core/models/booking_model.dart';

import 'package:chapechape_client/config/theme.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Toutes', 'À venir', 'Passées', 'Annulées'];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBookings();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _loadBookings() {
    context.read<BookingBloc>().add(LoadUserBookings());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingBloc, BookingState>(
      builder: (context, state) {
        return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des réservations'),
              backgroundColor: AppTheme.primaryColor,
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.black,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.black54,
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingList(state, null), // Toutes
                _buildBookingList(state, 'upcoming'), // À venir
                _buildBookingList(state, 'past'), // Passées
                _buildBookingList(state, 'cancelled'), // Annulées
              ],
            ),
        );
      },
    );
  }
  
  Widget _buildBookingList(BookingState state, String? filter) {
    if (state is UserBookingsLoaded) {
      final bookings = _filterBookings(state.bookings, filter);
      
      if (bookings.isEmpty) {
        return _buildEmptyState(filter);
      }
      
      return RefreshIndicator(
        onRefresh: () async {
          _loadBookings();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return _buildBookingCard(bookings[index]);
          },
        ),
      );
    } else if (state is BookingError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBookings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    } else {
      return const Center(
        child: Text('Chargement des réservations...'),
      );
    }
  }
  
  List<Booking> _filterBookings(List<Booking> bookings, String? filter) {
    if (filter == null) {
      return bookings;
    }
    
    final now = DateTime.now();
    
    switch (filter) {
      case 'upcoming':
        return bookings.where((booking) => 
          booking.checkIn.isAfter(now) || 
          (booking.checkIn.isBefore(now) && booking.checkOut.isAfter(now))
        ).toList();
      case 'past':
        return bookings.where((booking) => 
          booking.checkOut.isBefore(now) && 
          booking.cancellationReason == null
        ).toList();
      case 'cancelled':
        return bookings.where((booking) => 
          booking.cancellationReason != null
        ).toList();
      default:
        return bookings;
    }
  }
  
  Widget _buildEmptyState(String? filter) {
    String message;
    IconData icon;
    
    switch (filter) {
      case 'upcoming':
        message = 'Vous n\'avez pas de réservations à venir';
        icon = Icons.event_available;
        break;
      case 'past':
        message = 'Vous n\'avez pas de réservations passées';
        icon = Icons.history;
        break;
      case 'cancelled':
        message = 'Vous n\'avez pas de réservations annulées';
        icon = Icons.cancel;
        break;
      default:
        message = 'Vous n\'avez pas encore effectué de réservation';
        icon = Icons.calendar_today;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('Découvrir des résidences'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBookingCard(Booking booking) {
    final now = DateTime.now();
    final isUpcoming = booking.checkIn.isAfter(now) || 
                       (booking.checkIn.isBefore(now) && booking.checkOut.isAfter(now));
    final isPast = booking.checkOut.isBefore(now) && booking.cancellationReason == null;
    final isCancelled = booking.cancellationReason != null;
    
    Color statusColor;
    String statusText;
    
    if (isCancelled) {
      statusColor = Colors.red;
      statusText = 'Annulée';
    } else if (isUpcoming) {
      if (booking.checkIn.isBefore(now)) {
        statusColor = Colors.green;
        statusText = 'En cours';
      } else {
        statusColor = Colors.orange;
        statusText = 'À venir';
      }
    } else if (isPast) {
      statusColor = Colors.blue;
      statusText = 'Terminée';
    } else {
      statusColor = Colors.grey;
      statusText = 'Indéterminé';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.read<BookingBloc>().add(LoadBookingDetails(bookingId: booking.id));
          context.go('/bookings/${booking.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entête avec ID et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Réservation #${booking.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Dates de séjour
              Row(
                children: [
                  const Icon(Icons.date_range, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd MMM yyyy').format(booking.checkIn)} - ${DateFormat('dd MMM yyyy').format(booking.checkOut)}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Nombre de personnes
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${booking.numberOfGuests} ${booking.numberOfGuests > 1 ? 'personnes' : 'personne'}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Prix total
              Row(
                children: [
                  const Icon(Icons.payment, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    NumberFormat.currency(
                      symbol: 'FCFA ',
                      decimalDigits: 0,
                      locale: 'fr_FR',
                    ).format(booking.totalPrice),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              
              // Afficher la raison d'annulation si applicable
              if (isCancelled && booking.cancellationReason != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison d\'annulation: ${booking.cancellationReason}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Actions selon le statut
              if (isUpcoming && !isCancelled) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        _showCancellationDialog(context, booking.id);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        context.go('/bookings/${booking.id}');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Détails'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _showCancellationDialog(BuildContext context, String bookingId) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnelle)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // Annuler la réservation
              context.read<BookingBloc>().add(
                CancelBooking(
                  bookingId: bookingId,
                  reason: reasonController.text.isNotEmpty ? reasonController.text : null,
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }
}