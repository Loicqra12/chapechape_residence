import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chapechape_partner/core/services/onesignal_service.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/models/notification/notification_preference.dart';
import '../../../core/config/twilio_config.dart';

/// Préférences Partner — push distant via backend (source de vérité),
/// SMS / heures de silence en local (NotificationRepository).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final OneSignalService _oneSignalService = OneSignalService();
  bool _isLoading = true;
  String? _userId;

  bool _pushEnabled = true;
  bool _emailEnabled = true;
  bool _bookings = true;
  bool _messages = true;
  bool _payments = true;
  bool _promotions = true;
  bool _system = true;

  NotificationPreference _localPrefs = NotificationPreference.defaultForUser('unknown');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    try {
      final remote = await _oneSignalService.getNotificationPreferences();
      final settings = remote['notificationSettings'] as Map<String, dynamic>? ?? {};
      final categories = settings['categories'] as Map<String, dynamic>? ?? {};

      _pushEnabled = settings['pushEnabled'] as bool? ?? true;
      _emailEnabled = settings['emailEnabled'] as bool? ?? true;
      _bookings = categories['bookings'] as bool? ?? true;
      _messages = categories['messages'] as bool? ?? true;
      _payments = categories['payments'] as bool? ?? true;
      _promotions = categories['promotions'] as bool? ?? true;
      _system = categories['system'] as bool? ?? true;

      final repository = Provider.of<NotificationRepository>(context, listen: false);
      _userId = null;
      _localPrefs = await repository.getUserPreferences('partner');
      _phoneController.text = _localPrefs.phoneNumber ?? '';
      _emailController.text = _localPrefs.email ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement préférences: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _oneSignalService.updateNotificationPreferences(
        pushEnabled: _pushEnabled,
        emailEnabled: _emailEnabled,
        categories: {
          'bookings': _bookings,
          'messages': _messages,
          'payments': _payments,
          'promotions': _promotions,
          'system': _system,
        },
      );

      final repository = Provider.of<NotificationRepository>(context, listen: false);
      final updatedLocal = _localPrefs.copyWith(
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        updatedAt: DateTime.now(),
      );
      await repository.updatePreferences(updatedLocal);
      _localPrefs = updatedLocal;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préférences enregistrées avec succès')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur enregistrement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _remoteSwitch(String title, String subtitle, bool value, ValueChanged<bool> onChanged, {bool enabled = true}) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Préférences de notification')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Notifications push distantes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        _remoteSwitch(
                          'Notifications push',
                          'Push OneSignal contrôlé par le serveur',
                          _pushEnabled,
                          (v) => setState(() => _pushEnabled = v),
                        ),
                        _remoteSwitch(
                          'Notifications email',
                          'Emails transactionnels et inbox',
                          _emailEnabled,
                          (v) => setState(() => _emailEnabled = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Catégories push',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Card(
                    child: Column(
                      children: [
                        _remoteSwitch('Réservations', 'bookings', _bookings, (v) => setState(() => _bookings = v), enabled: _pushEnabled),
                        _remoteSwitch('Messages', 'messages', _messages, (v) => setState(() => _messages = v), enabled: _pushEnabled),
                        _remoteSwitch('Paiements', 'payments', _payments, (v) => setState(() => _payments = v), enabled: _pushEnabled),
                        _remoteSwitch('Promotions', 'promotions', _promotions, (v) => setState(() => _promotions = v), enabled: _pushEnabled),
                        _remoteSwitch('Système', 'system', _system, (v) => setState(() => _system = v), enabled: _pushEnabled),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Préférences locales (SMS)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Canaux SMS et heures de silence — stockés sur l\'appareil uniquement',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: TwilioConfig.availableChannels
                            .where((c) => c == 'sms')
                            .map((channel) => SwitchListTile(
                                  title: const Text('SMS'),
                                  subtitle: const Text('Des frais peuvent s\'appliquer'),
                                  value: _localPrefs.channels[channel] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      final updated = Map<String, bool>.from(_localPrefs.channels);
                                      updated[channel] = value;
                                      _localPrefs = _localPrefs.copyWith(channels: updated);
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(labelText: 'Téléphone (SMS)'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(labelText: 'Email contact local'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _savePreferences,
                    child: const Text('Enregistrer les préférences'),
                  ),
                ],
              ),
            ),
    );
  }
}
