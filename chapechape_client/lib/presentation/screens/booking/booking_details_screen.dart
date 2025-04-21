import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/models/cancellation_policy_model.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart';
import 'package:chapechape_client/core/blocs/booking/booking_state.dart';
import 'package:chapechape_client/presentation/widgets/modification_history_widget.dart';
import 'package:chapechape_client/presentation/widgets/booking_cancellation_dialog.dart';
import 'package:chapechape_client/config/theme.dart';
import 'package:intl/intl.dart';
import '../../widgets/cancellation_policy_details_widget.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late String _bookingId;
  Booking? _booking;
  CancellationPolicy? _cancellationPolicy;

  @override
  void initState() {
    super.initState();
    _bookingId = widget.bookingId;
    context.read<BookingBloc>().add(
      LoadBookingDetails(bookingId: _bookingId),
    );
  }

  void _showCancellationDialog() {
    if (_booking == null || _cancellationPolicy == null) return;

    showDialog(
      context: context,
      builder: (context) => BookingCancellationDialog(
        booking: _booking!,
        policy: _cancellationPolicy!,
        onConfirm: (reason) {
          Navigator.of(context).pop();
          context.read<BookingBloc>().add(
            CancelBooking(
              bookingId: _booking!.id,
              reason: reason,
            ),
          );
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la réservation'),
        actions: [
          if (_booking?.status == 'pending' || _booking?.status == 'confirmed')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/bookings/${widget.bookingId}/modify'),
            ),
        ],
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingDetailsLoaded) {
            setState(() {
              _booking = state.booking;
              _cancellationPolicy = state.cancellationPolicy;
            });
          } else if (state is BookingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookingDetailsLoaded) {
            final booking = state.booking;
            final policy = state.cancellationPolicy;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informations de base
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Réservation #${booking.id.substring(0, 8)}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            'Statut',
                            _getStatusText(booking.status),
                            _getStatusColor(booking.status),
                          ),
                          _buildDetailRow(
                            'Date d\'arrivée',
                            DateFormat('dd/MM/yyyy').format(booking.checkIn),
                          ),
                          _buildDetailRow(
                            'Date de départ',
                            DateFormat('dd/MM/yyyy').format(booking.checkOut),
                          ),
                          _buildDetailRow(
                            'Nombre de voyageurs',
                            booking.numberOfGuests.toString(),
                          ),
                          if (booking.specialRequests != null)
                            _buildDetailRow(
                              'Demandes spéciales',
                              booking.specialRequests!,
                            ),
                          _buildDetailRow(
                            'Prix total',
                            '${booking.totalPrice.toStringAsFixed(2)} FCFA',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Politique d'annulation
                  CancellationPolicyDetailsWidget(
                    policy: policy,
                    checkInDate: booking.checkIn,
                    totalPrice: booking.totalPrice,
                  ),

                  const SizedBox(height: 24),

                  // Historique des modifications
                  if (booking.modifications != null && booking.modifications!.isNotEmpty) ...[
                    Text(
                      'Historique des modifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ModificationHistoryWidget(
                      modifications: booking.modifications!,
                      bookingId: booking.id,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions
                  if (booking.status == 'pending' || booking.status == 'confirmed')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _showCancellationDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Annuler la réservation'),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Impossible de charger les détails de la réservation'),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
      case 'refunded':
        return 'Remboursée';
      default:
        return status;
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
        return Colors.green;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
} 