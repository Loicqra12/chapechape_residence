import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/booking_model.dart';
import 'package:chapechape_client/core/utils/booking_helpers.dart';
import 'package:chapechape_client/presentation/widgets/payment/payment_timer_widget.dart';
import 'package:chapechape_client/presentation/widgets/booking/reservation_status_badge.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';

/// Écran de paiement en attente avec timer et instructions
/// Affiché lorsqu'un paiement est en cours de traitement ou en attente
class PaymentPendingScreen extends StatefulWidget {
  final String bookingId;
  final String? paymentId;
  final Booking? booking;

  const PaymentPendingScreen({
    super.key,
    required this.bookingId,
    this.paymentId,
    this.booking,
  });

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _statusCheckTimer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Animation pour les éléments pulsants
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);

    // Charger les données de paiement
    _loadPaymentData();

    // Vérifier le statut périodiquement
    _startStatusChecking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _loadPaymentData() {
    if (widget.paymentId != null) {
      context.read<PaymentBloc>().add(
            CheckPaymentStatus(paymentId: widget.paymentId!),
          );
    }
  }

  void _startStatusChecking() {
    // Vérifier le statut toutes les 10 secondes
    _statusCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadPaymentData(),
    );
  }

  void _onTimerExpired() {
    // Quand le timer expire, vérifier le statut une dernière fois
    if (widget.paymentId != null) {
      context.read<PaymentBloc>().add(
            CheckPaymentStatus(paymentId: widget.paymentId!),
          );
    }

    // Afficher dialog d'expiration
    _showExpiredDialog();
  }

  void _onExtendDeadline() {
    // TODO: Implémenter l'extension du délai
    // Pour l'instant, afficher un message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demande d\'extension envoyée au partenaire'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.timer_off, color: Colors.red, size: 48),
        title: const Text('Délai de paiement expiré'),
        content: const Text(
          'Le délai de paiement pour cette réservation a expiré. '
          'Votre réservation a été automatiquement annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/bookings'),
            child: const Text('Mes Réservations'),
          ),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Accueil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Paiement en Attente'),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentConfirmed) {
            // Paiement confirmé, rediriger vers la page de succès
            context.go('/payment/success/${state.payment.id}');
          } else if (state is PaymentError) {
            // Erreur de paiement
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is PaymentCancelled) {
            // Paiement annulé
            context.go('/bookings');
          }

          setState(() {
            _isLoading = state is PaymentLoading;
          });
        },
        builder: (context, state) {
          return LoadingOverlay(
            isLoading: _isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Status badge
                  if (widget.booking != null)
                    Center(
                      child: widget.booking!.paymentStatusBadge(
                        size: BadgeSize.large,
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Timer principal
                  if (widget.booking != null &&
                      BookingHelpers.hasPaymentTimer(widget.booking!))
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _pulseAnimation.value,
                        child: PaymentTimerWidget(
                          booking: widget.booking!,
                          onTimerExpired: _onTimerExpired,
                          onExtendDeadline: _onExtendDeadline,
                          size: 180,
                          primaryColor: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Instructions de paiement
                  _buildPaymentInstructions(),

                  const SizedBox(height: 24),

                  // Informations de la réservation
                  if (widget.booking != null) _buildBookingInfo(),

                  const SizedBox(height: 24),

                  // Actions rapides
                  _buildQuickActions(),

                  const SizedBox(height: 32),

                  // Support et aide
                  _buildSupportSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Instructions de Paiement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
            const Divider(height: 32),
            _buildInstructionStep(
              step: '1',
              title: 'Vérifiez votre téléphone',
              description:
                  'Une notification Mobile Money a été envoyée sur votre téléphone.',
              icon: Icons.phone_android,
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              step: '2',
              title: 'Confirmez le paiement',
              description:
                  'Suivez les instructions sur votre téléphone pour confirmer le paiement.',
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 16),
            _buildInstructionStep(
              step: '3',
              title: 'Attendez la confirmation',
              description:
                  'Nous confirmerons automatiquement votre réservation une fois le paiement reçu.',
              icon: Icons.verified,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le paiement sera automatiquement annulé si vous ne confirmez pas dans les délais.',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep({
    required String step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numéro de l'étape
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Contenu
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingInfo() {
    final booking = widget.booking!;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails de la Réservation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            _buildInfoRow('Résidence', booking.residenceName),
            _buildInfoRow(
                'Check-in', BookingHelpers.formatDate(booking.checkIn)),
            _buildInfoRow(
                'Check-out', BookingHelpers.formatDate(booking.checkOut)),
            _buildInfoRow(
                'Montant', '${booking.totalPrice.toStringAsFixed(0)} FCFA'),
            _buildInfoRow(
                'Mode', _getReservationModeLabel(booking.reservationMode)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions Rapides',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadPaymentData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Actualiser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (widget.paymentId != null) {
                        context.read<PaymentBloc>().add(
                              CancelPayment(paymentId: widget.paymentId!),
                            );
                      }
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Annuler'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.support_agent,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Besoin d\'aide ?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Si vous rencontrez des difficultés avec votre paiement, '
              'notre équipe support est là pour vous aider.',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/support'),
                icon: const Icon(Icons.chat),
                label: const Text('Contacter le Support'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retourne le libellé approprié pour le mode de réservation
  String _getReservationModeLabel(String mode) {
    switch (mode.toLowerCase()) {
      case 'instant':
        return 'Instantané';
      case 'approval_required':
        return 'Avec approbation';
      default:
        return 'Mode standard';
    }
  }
}
