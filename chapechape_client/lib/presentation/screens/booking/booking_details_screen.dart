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
import 'package:chapechape_client/presentation/widgets/reservation_timer_widget.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
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
    
    // Rejoindre la salle WebSocket pour les mises à jour temps réel
    context.read<BookingBloc>().joinBookingRoom(_bookingId);
  }

  @override
  void dispose() {
    // Quitter la salle WebSocket lors de la destruction de l'écran
    context.read<BookingBloc>().leaveBookingRoom(_bookingId);
    super.dispose();
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

  /// Construit le widget de timer selon le statut de la réservation
  Widget? _buildTimerWidget(Booking booking) {
    // Utiliser notre nouvelle API ReservationTimerWidget avec displayMode
    if (BookingHelpers.hasActiveTimer(booking)) {
      return Column(
        children: [
          ReservationTimerWidget(
            booking: booking,
            displayMode: ReservationTimerDisplayMode.full,
            onExpired: () => _handleTimerExpired(booking),
            onRetry: () => _handleRetryAction(booking),
          ),
          AppSpacing.verticalMd,
        ],
      );
    }

    return null;
  }

  void _handleHostApprovalExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La demande d\'approbation a expiré. Vous pouvez créer une nouvelle réservation.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _cancelReservationRequest() {
    if (_booking != null) {
      context.read<BookingBloc>().add(
        CancelBooking(bookingId: _booking!.id, reason: 'Annulée par l\'utilisateur'),
      );
    }
  }

  void _modifyReservationDates() {
    if (_booking != null) {
      context.push('/booking-modify/${_booking!.id}');
    }
  }

  void _handlePaymentExpired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le délai de paiement est dépassé.'),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  /// Gère l'expiration des timers (SLA hôte ou paiement)
  void _handleTimerExpired(Booking booking) {
    final timerType = BookingHelpers.getActiveTimerType(booking);
    
    if (timerType == 'host_approval') {
      _handleHostApprovalExpired();
    } else if (timerType == 'payment') {
      _handlePaymentExpired();
    }
    
    // Recharger les détails de la réservation pour mettre à jour l'état
    context.read<BookingBloc>().add(
      LoadBookingDetails(bookingId: _bookingId),
    );
  }

  /// Gère les actions de retry selon le type de timer
  void _handleRetryAction(Booking booking) {
    final timerType = BookingHelpers.getActiveTimerType(booking);
    
    if (timerType == 'host_approval') {
      // Proposer de créer une nouvelle réservation
      _showNewBookingDialog();
    } else if (timerType == 'payment') {
      // Rediriger vers le paiement
      _navigateToPayment();
    }
  }

  /// Affiche un dialog pour proposer une nouvelle réservation
  void _showNewBookingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créer une nouvelle réservation?'),
        content: const Text(
          'L\'hôte n\'a pas approuvé votre demande dans les délais. '
          'Souhaitez-vous créer une nouvelle réservation?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_booking?.residenceId != null) {
                context.go('/residence/${_booking!.residenceId}');
              }
            },
            child: const Text('Nouvelle réservation'),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment() {
    if (_booking != null) {
      context.go('/payment/${_booking!.id}');
    }
  }

  void _requestExtendDeadline() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande d\'extension envoyée.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(
        // Même fond que le scaffold (thème clair : gris très léger), pas `surface` blanc pur
        // — évite la bande blanche qui tranche avec le reste de l’écran.
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: onSurface,
        elevation: 0,
        iconTheme: IconThemeData(color: onSurface),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: onSurface,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // Fallback vers l'écran des réservations
              context.go('/bookings');
            }
          },
        ),
        title: Text(
          'Détails de la réservation',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        actions: [
          if (_booking?.status == 'pending' || _booking?.status == 'confirmed')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/booking-modify/${widget.bookingId}'),
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
          } else if (state is BookingApproved) {
            // Navigation automatique vers l'écran d'approbation
            context.go('/booking-approved/${state.bookingId}');
          } else if (state is BookingRejected) {
            // Navigation automatique vers l'écran de rejet
            context.go('/booking-rejected/${state.bookingId}');
          } else if (state is BookingExpired) {
            // Navigation automatique vers l'écran d'expiration
            context.go('/booking-expired/${state.bookingId}');
          }
        },
        builder: (context, state) {
          if (state is BookingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is BookingDetailsLoaded) {
            final booking = state.booking;
            final policy = state.cancellationPolicy;

            return SafeArea(
              child: SingleChildScrollView(
                padding: AppSpacing.pagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Informations de base
                    Card(
                      child: Padding(
                        padding: AppSpacing.cardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Réservation #${booking.id.substring(0, 8)}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            AppSpacing.verticalMd,
                            _buildDetailRow(
                              'Statut',
                              _getStatusText(booking.status),
                              _getStatusColor(context, booking.status),
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

                    // Timer Widget conditionnel
                    if (_buildTimerWidget(booking) != null) ...[
                      AppSpacing.verticalMd,
                      _buildTimerWidget(booking)!,
                    ],

                    AppSpacing.verticalLg,

                    // Politique d'annulation
                    if (policy != null)
                      CancellationPolicyDetailsWidget(
                        policy: policy,
                        checkInDate: booking.checkIn,
                        totalPrice: booking.totalPrice,
                      ),

                    AppSpacing.verticalLg,

                    // Historique des modifications
                    if (booking.modifications != null && booking.modifications!.isNotEmpty) ...[
                      Text(
                        'Historique des modifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      AppSpacing.verticalMd,
                      ModificationHistoryWidget(
                        modifications: booking.modifications!,
                        bookingId: booking.id,
                      ),
                    ],

                    AppSpacing.verticalLg,

                    // Actions
                    if (booking.status == 'pending' || booking.status == 'confirmed')
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: _showCancellationDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Annuler la réservation'),
                        ),
                      ),
                  ],
                ),
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
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
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
      case 'awaiting_approval':
        return 'En attente d\'approbation';
      case 'pending_payment':
        return 'En attente de paiement';
      case 'confirmed':
        return 'Confirmée';
      case 'cancelled':
        return 'Annulée';
      case 'completed':
        return 'Terminée';
      case 'refunded':
        return 'Remboursée';
      case 'rejected':
        return 'Refusée';
      case 'expired':
        return 'Expirée';
      default:
        return status;
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'awaiting_approval':
        return const Color(0xFFD69E2E); // Orange/Ambre pour SLA hôte
      case 'pending_payment':
        return const Color(0xFFE53E3E); // Rouge pour paiement
      case 'confirmed':
        return AppTheme.primaryColor;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.green;
      case 'refunded':
        return Colors.blue;
      case 'rejected':
        return Colors.red[700]!;
      case 'expired':
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
} 