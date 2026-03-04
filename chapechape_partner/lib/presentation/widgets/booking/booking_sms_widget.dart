import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/booking/booking.dart';
import '../../../core/services/notification/sms_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/text_styles.dart';

/// Widget permettant d'envoyer des SMS aux clients pour les réservations
class BookingSmsWidget extends StatelessWidget {
  final Booking booking;
  
  const BookingSmsWidget({
    Key? key,
    required this.booking,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final smsService = Provider.of<SmsService>(context, listen: false);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sms, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Notifications SMS',
                  style: AppTextStyles.mediumBold.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Envoyer un SMS au client concernant sa réservation',
              style: AppTextStyles.regular,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSmsButton(
                  context,
                  icon: Icons.check_circle,
                  label: 'Confirmation',
                  color: Colors.green,
                  onTap: () => _sendBookingNotification(
                    context, 
                    smsService, 
                    'confirmation',
                    'confirmation',
                  ),
                ),
                _buildSmsButton(
                  context,
                  icon: Icons.access_time,
                  label: 'Rappel',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => _sendBookingNotification(
                    context, 
                    smsService, 
                    'reminder',
                    'rappel',
                  ),
                ),
                _buildSmsButton(
                  context,
                  icon: Icons.payments,
                  label: 'Paiement',
                  color: Colors.orange,
                  onTap: () => _sendBookingNotification(
                    context, 
                    smsService, 
                    'payment',
                    'paiement',
                  ),
                ),
                _buildSmsButton(
                  context,
                  icon: Icons.cancel,
                  label: 'Annulation',
                  color: Colors.red,
                  onTap: () => _sendBookingNotification(
                    context, 
                    smsService, 
                    'cancellation',
                    'annulation',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Instructions de paiement',
                  style: AppTextStyles.mediumBold.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Envoyer des instructions de paiement spécifiques à l\'Afrique',
              style: AppTextStyles.regular,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSmsButton(
                  context,
                  icon: Icons.water_drop,
                  label: 'Wave',
                  color: const Color(0xFF1EAAF1),
                  onTap: () => _sendPaymentInstructions(context, smsService, 'wave'),
                ),
                _buildSmsButton(
                  context,
                  icon: Icons.phone_android,
                  label: 'Orange Money',
                  color: const Color(0xFFFF6600),
                  onTap: () => _sendPaymentInstructions(context, smsService, 'orange_money'),
                ),
                _buildSmsButton(
                  context,
                  icon: Icons.phone_android,
                  label: 'MTN Money',
                  color: const Color(0xFFFFCC00),
                  onTap: () => _sendPaymentInstructions(context, smsService, 'mtn_money'),
                ),
                _buildSmsButton(
                  context,
                  icon: Icons.phone_android,
                  label: 'Moov Money',
                  color: const Color(0xFF00B8F1),
                  onTap: () => _sendPaymentInstructions(context, smsService, 'moov_money'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCustomSmsButton(context, smsService),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onTap,
    );
  }

  Widget _buildCustomSmsButton(BuildContext context, SmsService smsService) {
    final textController = TextEditingController();
    
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Envoyer un SMS personnalisé'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Votre message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            actions: [
              TextButton(
                child: const Text('Annuler'),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text('Envoyer'),
                onPressed: () {
                  if (textController.text.isNotEmpty) {
                    _sendCustomSms(
                      context, 
                      smsService, 
                      textController.text,
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              'SMS personnalisé',
              style: AppTextStyles.regularBold.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendBookingNotification(
    BuildContext context,
    SmsService smsService,
    String notificationType,
    String notificationName,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Afficher un indicateur de chargement
    _showLoadingDialog(context);
    
    final success = await smsService.sendBookingNotification(
      booking.id,
      notificationType,
    );
    
    // Fermer l'indicateur de chargement
    Navigator.pop(context);
    
    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('SMS de $notificationName envoyé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Échec de l\'envoi du SMS de $notificationName'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendCustomSms(
    BuildContext context,
    SmsService smsService,
    String message,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (booking.client?.phoneNumber == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone du client manquant'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Afficher un indicateur de chargement
    _showLoadingDialog(context);
    
    final success = await smsService.sendSms(
      booking.client!.phoneNumber!,
      message,
    );
    
    // Fermer l'indicateur de chargement
    Navigator.pop(context);
    
    if (success) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('SMS personnalisé envoyé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Échec de l\'envoi du SMS personnalisé'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Envoi du SMS en cours...'),
          ],
        ),
      ),
    );
  }
  
  /// Envoie des instructions de paiement spécifiques aux méthodes africaines
  Future<void> _sendPaymentInstructions(
    BuildContext context,
    SmsService smsService,
    String paymentMethod,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Afficher un indicateur de chargement
    _showLoadingDialog(context);
    
    final success = await smsService.sendPaymentInstructions(
      booking.id,
      paymentMethod,
    );
    
    // Fermer l'indicateur de chargement
    Navigator.pop(context);
    
    // Formater le nom de la méthode de paiement pour l'affichage
    String paymentMethodName;
    switch (paymentMethod) {
      case 'wave':
        paymentMethodName = 'Wave';
        break;
      case 'orange_money':
        paymentMethodName = 'Orange Money';
        break;
      case 'mtn_money':
        paymentMethodName = 'MTN Money';
        break;
      case 'moov_money':
        paymentMethodName = 'Moov Money';
        break;
      default:
        paymentMethodName = paymentMethod;
    }
    
    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Instructions de paiement $paymentMethodName envoyées avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Échec de l\'envoi des instructions de paiement $paymentMethodName'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
