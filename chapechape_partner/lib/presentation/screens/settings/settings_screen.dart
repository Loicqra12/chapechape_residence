import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/theme/theme_bloc.dart';
import '../../../core/blocs/settings/settings_bloc.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/auth/auth_event.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/dialogs/confirmation_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
  
  // Méthode factory pour créer l'écran avec son propre BlocProvider
  static Widget withBloc(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) {
            try {
              return context.read<ThemeBloc>();
            } catch (_) {
              return ThemeBloc();
            }
          },
        ),
        BlocProvider<SettingsBloc>(
          create: (context) {
            try {
              return context.read<SettingsBloc>();
            } catch (_) {
              return SettingsBloc();
            }
          },
        ),
        BlocProvider<AuthBloc>(
          create: (context) {
            try {
              return context.read<AuthBloc>();
            } catch (_) {
              // Fall back to original AuthBloc if needed
              return context.read<AuthBloc>();
            }
          },
        ),
      ],
      child: const SettingsScreen(),
    );
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'Français';
  final List<String> _availableLanguages = ['Français', 'English'];
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _selectedLanguage = prefs.getString('language') ?? 'Français';
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('language', _selectedLanguage);
    
    // Afficher un message de confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paramètres enregistrés'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: Text(
              'Enregistrer',
              style: TextStyle(color: theme.colorScheme.onPrimary),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Paramètres d'affichage
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                  child: Text(
                    'Affichage',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Mode sombre'),
                  subtitle: const Text('Activer le thème sombre'),
                  value: _isDarkMode,
                  onChanged: (bool value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    // Mettre à jour le thème via le BLoC
                    if (value) {
                      context.read<ThemeBloc>().add(const ThemeChanged(ThemeMode.dark));
                    } else {
                      context.read<ThemeBloc>().add(const ThemeChanged(ThemeMode.light));
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Langue'),
                  subtitle: Text(_selectedLanguage),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sélectionner une langue'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _availableLanguages.map((language) {
                            return RadioListTile<String>(
                              title: Text(language),
                              value: language,
                              groupValue: _selectedLanguage,
                              onChanged: (value) {
                                setState(() {
                                  _selectedLanguage = value!;
                                });
                                Navigator.pop(context);
                                
                                // Afficher un message indiquant que le changement de langue sera appliqué au redémarrage
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Le changement de langue sera appliqué au prochain redémarrage'),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('ANNULER'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Taille du texte'),
                  subtitle: const Text('Normal'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Taille du texte'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile(
                              title: const Text('Petite'),
                              value: 'small',
                              groupValue: 'normal',
                              onChanged: (value) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cette fonctionnalité sera disponible prochainement'),
                                  ),
                                );
                              },
                            ),
                            RadioListTile(
                              title: const Text('Normal'),
                              value: 'normal',
                              groupValue: 'normal',
                              onChanged: (value) {
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile(
                              title: const Text('Grande'),
                              value: 'large',
                              groupValue: 'normal',
                              onChanged: (value) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cette fonctionnalité sera disponible prochainement'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('ANNULER'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Paramètres de notifications
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                  child: Text(
                    'Notifications',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Notifications push'),
                  subtitle: const Text('Recevoir des notifications push'),
                  value: _notificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    
                    // Mettre à jour les paramètres de notification via le BLoC
                    context.read<SettingsBloc>().add(
                      ToggleNotifications(enabled: value),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifications de réservation'),
                  subtitle: const Text('Recevoir des notifications pour les nouvelles réservations'),
                  value: _notificationsEnabled,
                  onChanged: _notificationsEnabled
                      ? (bool value) {
                          // Cette option est liée à l'option principale
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cette option est liée aux notifications push'),
                            ),
                          );
                        }
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifications de paiement'),
                  subtitle: const Text('Recevoir des notifications pour les paiements'),
                  value: _notificationsEnabled,
                  onChanged: _notificationsEnabled
                      ? (bool value) {
                          // Cette option est liée à l'option principale
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cette option est liée aux notifications push'),
                            ),
                          );
                        }
                      : null,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Confidentialité et conditions
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Confidentialité'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    const privacyUrl = 'https://www.chapechape.com/privacy';
                    if (await canLaunch(privacyUrl)) {
                      await launch(privacyUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible d\'ouvrir la page de confidentialité'),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Conditions d\'utilisation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    const termsUrl = 'https://www.chapechape.com/terms';
                    if (await canLaunch(termsUrl)) {
                      await launch(termsUrl);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impossible d\'ouvrir les conditions d\'utilisation'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Compte
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                  child: Text(
                    'Compte',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Déconnexion'),
                  leading: Icon(
                    Icons.logout,
                    color: theme.colorScheme.error,
                  ),
                  textColor: theme.colorScheme.error,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        title: 'Déconnexion',
                        content: 'Êtes-vous sûr de vouloir vous déconnecter ?',
                        confirmText: 'DÉCONNEXION',
                        cancelText: 'ANNULER',
                        confirmColor: theme.colorScheme.error,
                        onConfirm: () {
                          // Déconnexion via le BLoC
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Supprimer mon compte'),
                  leading: Icon(
                    Icons.delete_forever,
                    color: theme.colorScheme.error,
                  ),
                  textColor: theme.colorScheme.error,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => ConfirmationDialog(
                        title: 'Supprimer le compte',
                        content: 'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.',
                        confirmText: 'SUPPRIMER',
                        cancelText: 'ANNULER',
                        confirmColor: theme.colorScheme.error,
                        onConfirm: () {
                          // Demander le mot de passe pour confirmer
                          Navigator.pop(context);
                          
                          showDialog(
                            context: context,
                            builder: (context) {
                              final passwordController = TextEditingController();
                              
                              return AlertDialog(
                                title: const Text('Confirmer la suppression'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Veuillez entrer votre mot de passe pour confirmer la suppression de votre compte.'),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Mot de passe',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('ANNULER'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Supprimer le compte via le BLoC
                                      if (passwordController.text.isNotEmpty) {
                                        context.read<AuthBloc>().add(
                                          AuthDeleteAccountRequested(
                                            password: passwordController.text,
                                          ),
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Veuillez entrer votre mot de passe'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                    ),
                                    child: const Text('SUPPRIMER'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // À propos
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: theme.colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('À propos de ChapeChape'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'ChapeChape Partner',
                      applicationVersion: '1.0.0',
                      applicationIcon: Image.asset(
                        'assets/images/logo.png',
                        width: 50,
                        height: 50,
                      ),
                      applicationLegalese: '© 2024 ChapeChape. Tous droits réservés.',
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'ChapeChape Partner est une application qui permet aux partenaires de gérer leurs résidences et réservations.',
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Version de l\'application'),
                  subtitle: const Text('1.0.0 (build 101)'),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Vous utilisez la dernière version'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
