import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:math' show pi;
import 'package:chapechape_client/core/blocs/payment/payment_bloc.dart';
import 'package:chapechape_client/core/blocs/payment/payment_event.dart';
import 'package:chapechape_client/core/blocs/payment/payment_state.dart';
import 'package:chapechape_client/core/models/payment_model.dart';
import 'package:chapechape_client/presentation/widgets/loading_overlay.dart';
import 'package:chapechape_client/config/theme.dart';
import 'package:confetti/confetti.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final String paymentId;

  const PaymentSuccessScreen({
    Key? key,
    required this.paymentId,
  }) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  bool _isLoading = true;
  Payment? _payment;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 5),
    );
    _loadPaymentDetails();
  }

  void _loadPaymentDetails() {
    context.read<PaymentBloc>().add(
      CheckPaymentStatus(paymentId: widget.paymentId),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Paiement réussi'),
        elevation: 0,
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentLoading) {
            setState(() {
              _isLoading = true;
            });
          } else if (state is PaymentStatusChecked) {
            setState(() {
              _isLoading = false;
              _payment = state.payment;
            });
            // Lancer l'animation de confetti
            _confettiController.play();
          } else if (state is PaymentError) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              LoadingOverlay(
                isLoading: _isLoading,
                child: _payment == null
                    ? const Center(child: Text('Chargement des détails du paiement...'))
                    : _buildSuccessContent(),
              ),
              
              // Animation de confetti en haut de l'écran
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2, // vers le bas
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  maxBlastForce: 20,
                  minBlastForce: 10,
                  gravity: 0.1,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuccessContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSuccessHeader(),
          const SizedBox(height: 24),
          _buildPaymentDetails(),
          const SizedBox(height: 24),
          _buildNextStepsSection(),
          const SizedBox(height: 32),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Card(
      color: AppTheme.successColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.successColor,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              'Paiement réussi !',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.successColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Votre paiement a été traité avec succès',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    if (_payment == null) {
      return const Center(child: Text('Aucune information de paiement disponible'));
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails du paiement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 8),
            
            // Informations de base du paiement
            _buildDetailRow('Référence', _payment!.id),
            _buildDetailRow('Méthode', _payment!.method.displayName),
            _buildDetailRow('Statut', _getStatusText(_payment!.status)),
            _buildDetailRow('Date', DateFormat('dd/MM/yyyy à HH:mm').format(_payment!.createdAt)),
            if (_payment!.transactionId != null)
              _buildDetailRow('ID Transaction', _payment!.transactionId!),
            if (_payment!.bookingId != null)
              _buildDetailRow('Réservation', _payment!.bookingId!),
            if (_payment!.bookingResidenceName != null)
              _buildDetailRow('Résidence', _payment!.bookingResidenceName!),
              
            // Séparateur
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
              
            // Section détaillée des montants
            Text(
              'Récapitulatif financier',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Montant total
            _buildDetailRow(
              'Montant total', 
              currencyFormatter.format(_payment!.amount),
              valueStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            
            // Ajout de la commission si elle est disponible
            if (_payment!.commission != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow(
                'Frais de service (${(_payment!.commission!.rate * 100).toStringAsFixed(0)}%)', 
                '- ${currencyFormatter.format(_payment!.commission!.commissionAmount)}',
                valueStyle: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 4),
              const Divider(indent: 100, endIndent: 16, height: 16),
              _buildDetailRow(
                'Montant au partenaire', 
                currencyFormatter.format(_payment!.commission!.partnerAmount),
                valueStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label, 
    String value, {
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: labelStyle ?? const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prochaines étapes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            const SizedBox(height: 16),
            _buildStepItem(
              icon: Icons.email,
              title: 'Confirmation par e-mail',
              description: 'Un e-mail de confirmation a été envoyé à votre adresse.',
            ),
            const SizedBox(height: 16),
            _buildStepItem(
              icon: Icons.history,
              title: 'Historique des paiements',
              description: 'Vous pouvez retrouver ce paiement dans votre historique.',
            ),
            if (_payment!.bookingId != null) ...[
              const SizedBox(height: 16),
              _buildStepItem(
                icon: Icons.hotel,
                title: 'Réservation confirmée',
                description: 'Votre réservation est maintenant confirmée et garantie.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            if (_payment?.bookingId != null) {
              context.go('/booking-details/${_payment!.bookingId}');
            } else {
              context.go('/bookings');
            }
          },
          icon: const Icon(Icons.visibility),
          label: const Text('Voir ma réservation'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            context.go('/');
          },
          icon: const Icon(Icons.home),
          label: const Text('Retour à l\'accueil'),
        ),
      ],
    );
  }

  String _getStatusText(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.processing:
        return 'En cours';
      case PaymentStatus.succeeded:
        return 'Réussi';
      case PaymentStatus.failed:
        return 'Échoué';
      case PaymentStatus.refunded:
        return 'Remboursé';
      case PaymentStatus.cancelled:
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }
}