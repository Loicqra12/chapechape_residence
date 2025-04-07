import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/repositories/notification_repository.dart';
import '../../../core/models/notification/notification_preference.dart';
import '../../../core/config/twilio_config.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late NotificationPreference _preferences;
  bool _isLoading = true;
  String? _userId;
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
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Récupérer l'ID de l'utilisateur depuis le stockage
      _userId = 'user_123'; // Temporaire pour la démo
      
      final repository = Provider.of<NotificationRepository>(context, listen: false);
      _preferences = await repository.getUserPreferences(_userId!);
      
      _phoneController.text = _preferences.phoneNumber ?? '';
      _emailController.text = _preferences.email ?? '';
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du chargement des préférences: $e')),
      );
      setState(() {
        _isLoading = false;
        _preferences = NotificationPreference.defaultForUser(_userId ?? 'unknown');
      });
    }
  }
  
  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = Provider.of<NotificationRepository>(context, listen: false);
      
      // Créer une nouvelle instance avec les valeurs mises à jour
      final updatedPreferences = _preferences.copyWith(
        phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        updatedAt: DateTime.now(),
      );
      
      final success = await repository.updatePreferences(updatedPreferences);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préférences enregistrées avec succès')),
        );
        setState(() {
          _preferences = updatedPreferences;
          _isLoading = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'enregistrer les préférences')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Préférences de notification'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'Canaux de notification',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: TwilioConfig.availableChannels.map((channel) {
                          final title = channel == 'push'
                              ? 'Notifications push'
                              : channel == 'sms'
                                  ? 'SMS'
                                  : 'Email';
                          final subtitle = channel == 'sms'
                              ? 'Des frais peuvent s\'appliquer'
                              : channel == 'email'
                                  ? 'Notifications par email'
                                  : 'Notifications sur l\'appareil';
                          
                          return SwitchListTile(
                            title: Text(title),
                            subtitle: Text(subtitle),
                            value: _preferences.channels[channel] ?? false,
                            onChanged: (value) {
                              setState(() {
                                final updatedChannels = Map<String, bool>.from(_preferences.channels);
                                updatedChannels[channel] = value;
                                _preferences = _preferences.copyWith(
                                  channels: updatedChannels,
                                );
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Types de notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Résidences',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildNotificationTypeTile(
                            'residence_created',
                            'Création de résidence',
                            'Lorsqu\'une nouvelle résidence est créée',
                          ),
                          _buildNotificationTypeTile(
                            'residence_updated',
                            'Mise à jour de résidence',
                            'Lorsqu\'une résidence est modifiée',
                          ),
                          _buildNotificationTypeTile(
                            'residence_deleted',
                            'Suppression de résidence',
                            'Lorsqu\'une résidence est supprimée',
                          ),
                          
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Réservations',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildNotificationTypeTile(
                            'booking_created',
                            'Nouvelle réservation',
                            'Lorsqu\'une nouvelle réservation est effectuée',
                          ),
                          _buildNotificationTypeTile(
                            'booking_confirmed',
                            'Réservation confirmée',
                            'Lorsqu\'une réservation est confirmée',
                          ),
                          _buildNotificationTypeTile(
                            'booking_canceled',
                            'Réservation annulée',
                            'Lorsqu\'une réservation est annulée',
                          ),
                          
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Communications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildNotificationTypeTile(
                            'message_received',
                            'Nouveau message',
                            'Lorsqu\'un nouveau message est reçu',
                          ),
                          _buildNotificationTypeTile(
                            'review_received',
                            'Nouvel avis',
                            'Lorsqu\'un nouvel avis est publié',
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Coordonnées pour les notifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Numéro de téléphone (pour SMS)',
                              hintText: 'Ex: +22501234567',
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && !value.startsWith('+')) {
                                return 'Le numéro doit commencer par + et le code pays';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email (pour notifications par email)',
                              hintText: 'Ex: exemple@chapechape.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && !value.contains('@')) {
                                return 'Veuillez entrer un email valide';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Heures de silence',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text(
                            'Définissez une plage horaire pendant laquelle vous ne recevrez pas de notifications SMS',
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Début',
                                  ),
                                  value: _preferences.quietHoursStart,
                                  items: List.generate(24, (index) {
                                    return DropdownMenuItem<int>(
                                      value: index,
                                      child: Text('${index}h00'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _preferences = _preferences.copyWith(
                                          quietHoursStart: value,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Fin',
                                  ),
                                  value: _preferences.quietHoursEnd,
                                  items: List.generate(24, (index) {
                                    return DropdownMenuItem<int>(
                                      value: index,
                                      child: Text('${index}h00'),
                                    );
                                  }),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _preferences = _preferences.copyWith(
                                          quietHoursEnd: value,
                                        );
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _savePreferences,
                    child: const Text('Enregistrer les préférences'),
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildNotificationTypeTile(String type, String title, String subtitle) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: _preferences.types[type] ?? true,
      onChanged: (value) {
        setState(() {
          final updatedTypes = Map<String, bool>.from(_preferences.types);
          updatedTypes[type] = value;
          _preferences = _preferences.copyWith(
            types: updatedTypes,
          );
        });
      },
    );
  }
} 