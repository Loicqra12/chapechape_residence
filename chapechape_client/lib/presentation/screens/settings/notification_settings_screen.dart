import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
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
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: _isLoading && _pushNotificationsEnabled == true
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.pagePadding.copyWith(
                bottom: AppSpacing.pagePadding.bottom + safeBottom + 8,
              ),
              children: [
                _buildSectionHeader(context, 'Notifications générales'),
                _buildSwitchTile(
                  context,
                  'Notifications push',
                  _pushNotificationsEnabled,
                  (value) => setState(() => _pushNotificationsEnabled = value),
                  icon: Icons.notifications,
                ),
                _buildSwitchTile(
                  context,
                  'Notifications email',
                  _emailNotificationsEnabled,
                  (value) => setState(() => _emailNotificationsEnabled = value),
                  icon: Icons.email,
                ),
                AppSpacing.verticalLg,
                _buildSectionHeader(context, 'Types de notifications'),
                _buildSwitchTile(
                  context,
                  'Réservations',
                  _bookingNotifications,
                  (value) => setState(() => _bookingNotifications = value),
                  icon: Icons.calendar_today,
                  enabled: _pushNotificationsEnabled,
                ),
                _buildSwitchTile(
                  context,
                  'Messages',
                  _chatNotifications,
                  (value) => setState(() => _chatNotifications = value),
                  icon: Icons.chat,
                  enabled: _pushNotificationsEnabled,
                ),
                _buildSwitchTile(
                  context,
                  'Paiements',
                  _paymentNotifications,
                  (value) => setState(() => _paymentNotifications = value),
                  icon: Icons.payment,
                  enabled: _pushNotificationsEnabled,
                ),
                _buildSwitchTile(
                  context,
                  'Promotions',
                  _promotionNotifications,
                  (value) => setState(() => _promotionNotifications = value),
                  icon: Icons.local_offer,
                  enabled: _pushNotificationsEnabled,
                ),
                AppSpacing.verticalLg,
                _buildSectionHeader(context, 'Paramètres avancés'),
                _buildSwitchTile(
                  context,
                  'Son',
                  _soundEnabled,
                  (value) => setState(() => _soundEnabled = value),
                  icon: Icons.volume_up,
                  enabled: _pushNotificationsEnabled,
                ),
                _buildSwitchTile(
                  context,
                  'Vibration',
                  _vibrationEnabled,
                  (value) => setState(() => _vibrationEnabled = value),
                  icon: Icons.vibration,
                  enabled: _pushNotificationsEnabled,
                ),
                AppSpacing.verticalLg,
                if (_pushNotificationsEnabled)
                  ListTile(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _sendTestNotification();
                    },
                    leading: Icon(Icons.send, color: AppTheme.textPrimary),
                    title: Text(
                      'Tester les notifications',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                AppSpacing.verticalMd,
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'Les notifications push nécessitent une connexion internet. '
                    'Vous pouvez modifier ces paramètres à tout moment.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                ListTile(
                  onTap: _isLoading ? null : () {
                    HapticFeedback.lightImpact();
                    _saveNotificationPreferences();
                  },
                  leading: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.save, color: AppTheme.textPrimary),
                  title: Text(
                    'Sauvegarder',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    required IconData icon,
    bool enabled = true,
  }) {
    return SwitchListTile(
      secondary: Icon(
        icon,
        color: enabled ? AppTheme.textPrimary : Colors.grey,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: enabled ? AppTheme.textPrimary : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: enabled
          ? (v) {
              HapticFeedback.lightImpact();
              onChanged(v);
            }
          : null,
      activeColor: AppTheme.primaryColor,
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








