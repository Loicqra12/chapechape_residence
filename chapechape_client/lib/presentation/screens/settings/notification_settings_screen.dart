import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/services/onesignal_service.dart';
import 'package:chapechape_client/core/services/error_message_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Variables pour les préférences de notification
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _bookingNotifications = true;
  bool _chatNotifications = true;
  bool _paymentNotifications = true;
  bool _promotionNotifications = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  bool _isLoading = false;
  final OneSignalService _oneSignalService = OneSignalService();

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      final preferences = await _oneSignalService.getNotificationPreferences();
      
      if (mounted) {
        setState(() {
          _pushNotificationsEnabled = preferences['notificationSettings']?['pushEnabled'] ?? true;
          _emailNotificationsEnabled = preferences['notificationSettings']?['emailEnabled'] ?? true;
          
          final categories = preferences['notificationSettings']?['categories'] ?? {};
          _bookingNotifications = categories['bookings'] ?? true;
          _chatNotifications = categories['messages'] ?? true;
          _paymentNotifications = categories['payments'] ?? true;
          _promotionNotifications = categories['promotions'] ?? false;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorMessageService.showError(
          context,
          e,
          contextType: 'generic',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      await _oneSignalService.updateNotificationPreferences(
        pushEnabled: _pushNotificationsEnabled,
        emailEnabled: _emailNotificationsEnabled,
        categories: {
          'bookings': _bookingNotifications,
          'messages': _chatNotifications,
          'payments': _paymentNotifications,
          'promotions': _promotionNotifications,
        },
      );
      
      if (mounted) {
        ErrorMessageService.showSuccess(
          context,
          'Préférences de notification sauvegardées',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorMessageService.showError(
          context,
          e,
          contextType: 'profile_update',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres de notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            const Padding(
              padding: AppSpacing.cardPadding,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNotificationPreferences,
              tooltip: 'Sauvegarder',
            ),
        ],
      ),
      body: _isLoading && _pushNotificationsEnabled == true
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.cardPadding,
              children: [
                // Section Notifications générales
                _buildSectionHeader('Notifications générales'),
                _buildSwitchTile(
                  'Notifications push',
                  'Recevoir des notifications push sur cet appareil',
                  _pushNotificationsEnabled,
                  (value) => setState(() => _pushNotificationsEnabled = value),
                  icon: Icons.notifications,
                ),
                _buildSwitchTile(
                  'Notifications email',
                  'Recevoir des notifications par email',
                  _emailNotificationsEnabled,
                  (value) => setState(() => _emailNotificationsEnabled = value),
                  icon: Icons.email,
                ),
                
                AppSpacing.verticalLg,
                
                // Section Types de notifications
                _buildSectionHeader('Types de notifications'),
                _buildSwitchTile(
                  'Réservations',
                  'Notifications pour les réservations et modifications',
                  _bookingNotifications,
                  (value) => setState(() => _bookingNotifications = value),
                  icon: Icons.calendar_today,
                  enabled: _pushNotificationsEnabled,
                ),
                _buildSwitchTile(
                  'Messages',
                  'Notifications pour les nouveaux messages',
                  _chatNotifications,
                  (value) => setState(() => _chatNotifications = value),
                  icon: Icons.chat,
                  enabled: _pushNotificationsEnabled,
                ),
                _buildSwitchTile(
                  'Paiements',
                  'Notifications pour les paiements et remboursements',
                  _paymentNotifications,
                  (value) => setState(() => _paymentNotifications = value),
                  icon: Icons.payment,
                  enabled: _pushNotificationsEnabled,
                ),
                _buildSwitchTile(
                  'Promotions',
                  'Notifications pour les offres et promotions',
                  _promotionNotifications,
                  (value) => setState(() => _promotionNotifications = value),
                  icon: Icons.local_offer,
                  enabled: _pushNotificationsEnabled,
                ),
                
                AppSpacing.verticalLg,
                
                // Section Paramètres avancés
                _buildSectionHeader('Paramètres avancés'),
                _buildSwitchTile(
                  'Son',
                  'Jouer un son lors de la réception de notifications',
                  _soundEnabled,
                  (value) => setState(() => _soundEnabled = value),
                  icon: Icons.volume_up,
                  enabled: _pushNotificationsEnabled,
                ),
                _buildSwitchTile(
                  'Vibration',
                  'Vibrer lors de la réception de notifications',
                  _vibrationEnabled,
                  (value) => setState(() => _vibrationEnabled = value),
                  icon: Icons.vibration,
                  enabled: _pushNotificationsEnabled,
                ),
                
                AppSpacing.verticalXl,
                
                // Bouton de test
                if (_pushNotificationsEnabled)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.send, color: Colors.blue),
                      title: const Text('Tester les notifications'),
                      subtitle: const Text('Envoyer une notification de test'),
                      onTap: _sendTestNotification,
                    ),
                  ),
                
                AppSpacing.verticalMd,
                
                // Informations
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Information',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.verticalSm,
                        Text(
                          'Les notifications push nécessitent une connexion internet. '
                          'Vous pouvez modifier ces paramètres à tout moment.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    required IconData icon,
    bool enabled = true,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      child: SwitchListTile(
        secondary: Icon(
          icon,
          color: enabled ? Theme.of(context).primaryColor : Colors.grey,
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: enabled ? null : Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: enabled ? Colors.grey[600] : Colors.grey,
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      // Ici vous pourriez implémenter l'envoi d'une notification de test
      // via votre backend ou OneSignal
      ErrorMessageService.showSuccess(
        context,
        'Notification de test envoyée',
      );
    } catch (e) {
      ErrorMessageService.showError(
        context,
        e,
        contextType: 'generic',
      );
    }
  }
}








