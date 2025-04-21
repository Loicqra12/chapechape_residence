import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:chapechape_client/core/blocs/booking/booking_bloc.dart';
import 'package:chapechape_client/core/blocs/booking/booking_event.dart' as booking_events;
import 'package:chapechape_client/core/blocs/booking/booking_state.dart' as booking_states;
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/config/theme.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String bookingId;

  const BookingConfirmationScreen({
    Key? key,
    required this.bookingId,
  }) : super(key: key);

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  Booking? _booking;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  void _loadBookingDetails() {
    context.read<BookingBloc>().add(
      booking_events.LoadBookingDetails(bookingId: widget.bookingId),
    );
  }

  void _initiatePayment() {
    if (_booking != null) {
      context.read<PaymentBloc>().add(
        PreparePayment(
          reservationId: _booking!.id,
          method: PaymentMethod.mobileMoney,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation de réservation'),
        elevation: 0,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: MultiBlocListener(
          listeners: [
            BlocListener<BookingBloc, booking_states.BookingState>(
              listener: (context, state) {
                setState(() {
                  _isLoading = state is booking_states.BookingLoading;
                });

                if (state is booking_states.BookingDetailsLoaded) {
                  setState(() {
                    _booking = state.booking;
                  });
                } else if (state is booking_states.BookingError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
            BlocListener<PaymentBloc, PaymentState>(
              listener: (context, state) {
                setState(() {
                  _isLoading = state is PaymentLoading;
                });

                if (state is PaymentIntentCreated) {
                  // Rediriger vers l'écran de paiement
                  context.go('/payment/${state.paymentIntent.id}');
                } else if (state is PaymentError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message)),
                  );
                }
              },
            ),
          ],
          child: _booking == null
              ? const Center(child: Text('Chargement des détails...'))
              : _buildBookingConfirmation(),
        ),
      ),
    );
  }

  Widget _buildBookingConfirmation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSuccessHeader(),
          const SizedBox(height: 24),
          _buildBookingDetails(),
          const SizedBox(height: 24),
          _buildPaymentSection(),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
    if (_booking == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Chargement des informations...')),
        ),
      );
    }
    
    return Card(
      color: AppTheme.successColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.successColor,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Réservation créée avec succès !',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Référence: ${_booking!.id}',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetails() {
    if (_booking == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Chargement des détails...')),
        ),
      );
    }
    
    // Utiliser une variable locale pour éviter les accès répétés avec non-null assertion
    final booking = _booking!;
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails de la réservation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildDetailRow('Résidence', booking.residenceName),
            _buildDetailRow('Date d\'arrivée', dateFormat.format(booking.checkIn)),
            _buildDetailRow('Date de départ', dateFormat.format(booking.checkOut)),
            _buildDetailRow('Nombre de nuits', '${booking.nights}'),
            _buildDetailRow('Nombre de personnes', '${booking.numberOfGuests}'),
            _buildDetailRow('Statut', _getStatusText(booking.status)),
            _buildDetailRow('Prix total', '${booking.totalPrice.toStringAsFixed(0)} FCFA'),
            const SizedBox(height: 8),
            Text(
              'Détails de paiement',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            _buildDetailRow('Statut du paiement', _getPaymentStatusText(booking.isPaid)),
          ],
        ),
      ),
    );
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

  Widget _buildPaymentSection() {
    if (_booking == null) {
      return const SizedBox.shrink();
    }
    
    if (_booking!.isPaid) {
      return Card(
        color: AppTheme.successColor.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Icon(
                Icons.payment,
                color: AppTheme.successColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Réservation déjà payée',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Procéder au paiement',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Votre réservation est confirmée, mais elle ne sera garantie qu\'après le paiement. Veuillez procéder au paiement maintenant.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initiatePayment,
              icon: const Icon(Icons.payment),
              label: const Text('Payer maintenant'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                context.go('/bookings');
              },
              child: const Text('Payer plus tard'),
            ),
          ],
        ),
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
      default:
        return 'Inconnu';
    }
  }

  String _getPaymentStatusText(bool isPaid) {
    return isPaid ? 'Payé' : 'Non payé';
  }
} 