import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/config/theme.dart';

class PaymentFailedScreen extends StatelessWidget {
  final String? paymentId;
  final String? transactionId;
  final String? method;
  final String? phoneNumber;
  final double? amount;
  final String? reservationId;
  final String? failureReason;
  final bool isExpired;

  const PaymentFailedScreen({
    Key? key,
    this.paymentId,
    this.transactionId,
    this.method,
    this.phoneNumber,
    this.amount,
    this.reservationId,
    this.failureReason,
    this.isExpired = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Empêcher le retour accidentel - rediriger vers home
        context.go('/home');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
          title: Text(
            isExpired ? 'Paiement expiré' : 'Paiement échoué',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          automaticallyImplyLeading: false, // Pas de bouton retour
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Animation d'erreur
              _buildErrorAnimation(),

              const SizedBox(height: 32),

              // Message principal
              _buildErrorMessage(context),

              const SizedBox(height: 32),

              // Détails si disponibles
              if (transactionId != null || failureReason != null)
                _buildErrorDetails(context),

              const SizedBox(height: 40),

              // Boutons d'action
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red.withOpacity(0.1),
        border: Border.all(color: Colors.red, width: 3),
      ),
      child: const Icon(
        Icons.error_outline,
        size: 60,
        color: Colors.red,
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    String title = isExpired ? 'Temps expiré' : 'Paiement échoué';
    String message = isExpired
        ? 'Le délai de paiement a expiré. Vous pouvez réessayer avec la même méthode ou en choisir une autre.'
        : 'Le paiement n\'a pas abouti. Vérifiez vos informations et réessayez.';

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (failureReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        failureReason!,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDetails(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détails',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 20),
            if (transactionId != null)
              _buildDetailRow('Transaction', transactionId!),
            if (method != null)
              _buildDetailRow('Méthode', _getMethodDisplayName()),
            if (amount != null)
              _buildDetailRow('Montant', '${amount!.toStringAsFixed(0)} FCFA'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton Réessayer (prioritaire)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _retryPayment(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer avec la même méthode'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Bouton Changer de méthode
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _changePaymentMethod(context),
            icon: const Icon(Icons.payment),
            label: const Text('Choisir une autre méthode'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Bouton Annuler (retour home)
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home),
            label: const Text('Retour à l\'accueil'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _retryPayment(BuildContext context) {
    // Retourner à l'écran de paiement avec les infos préremplies
    if (reservationId != null) {
      context.go('/payment/$reservationId', extra: {
        'prefillMethod': method,
        'prefillPhoneNumber': phoneNumber,
        'retryAttempt': true,
      });
    } else {
      context.go('/home');
    }
  }

  void _changePaymentMethod(BuildContext context) {
    // Retourner à l'écran de paiement sans préremplir la méthode
    if (reservationId != null) {
      context.go('/payment/$reservationId', extra: {
        'prefillPhoneNumber': phoneNumber, // Garder le numéro
        'changeMethod': true,
      });
    } else {
      context.go('/home');
    }
  }

  String _getMethodDisplayName() {
    switch (method) {
      case 'wave':
        return 'Wave';
      case 'om':
        return 'Orange Money';
      case 'momo':
        return 'Moov Money';
      case 'mtn_money':
        return 'MTN Money';
      default:
        return 'Paiement mobile';
    }
  }
}
