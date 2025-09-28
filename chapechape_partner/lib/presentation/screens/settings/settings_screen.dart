import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/theme/theme_bloc.dart';
import '../../../core/blocs/settings/settings_bloc.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/auth/auth_event.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/common/dialogs/confirmation_dialog.dart';
import '../../widgets/common/watermark_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  bool _smsNotificationsEnabled = false;
  bool _dataLimitMode = false;
  bool _offlineMode = false;
  String _selectedLanguage = 'Français';
  String _selectedCurrency = 'XOF (CFA)';
  String _selectedPaymentMethod = 'Wave';
  String _appVersion = '1.0.0';
  String _buildNumber = '1';
  final List<String> _availableLanguages = ['Français', 'English'];
  final List<String> _availableCurrencies = ['XOF (CFA)', 'EUR (€)', 'USD (Dollar)'];
  final List<String> _availablePaymentMethods = ['Wave', 'Orange Money', 'MTN Money', 'Moov Money', 'Carte bancaire', 'Virement bancaire'];
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _smsNotificationsEnabled = prefs.getBool('sms_notifications_enabled') ?? false;
      _dataLimitMode = prefs.getBool('data_limit_mode') ?? false;
      _offlineMode = prefs.getBool('offline_mode') ?? false;
      _selectedLanguage = prefs.getString('language') ?? 'Français';
      _selectedCurrency = prefs.getString('currency') ?? 'XOF (CFA)';
      _selectedPaymentMethod = prefs.getString('default_payment_method') ?? 'Wave';
    });
  }
  
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des informations de l\'app: $e');
      // Garder les valeurs par défaut
    }
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('sms_notifications_enabled', _smsNotificationsEnabled);
    await prefs.setBool('data_limit_mode', _dataLimitMode);
    await prefs.setBool('offline_mode', _offlineMode);
    await prefs.setString('language', _selectedLanguage);
    await prefs.setString('currency', _selectedCurrency);
    await prefs.setString('default_payment_method', _selectedPaymentMethod);
    
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
          
          // Paramètres régionaux
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
                    'Paramètres régionaux',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Devise par défaut'),
                  subtitle: Text(_selectedCurrency),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sélectionner une devise'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _availableCurrencies.map((currency) {
                            return RadioListTile<String>(
                              title: Text(currency),
                              value: currency,
                              groupValue: _selectedCurrency,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCurrency = value!;
                                });
                                Navigator.pop(context);
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Devise mise à jour'),
                                    backgroundColor: Colors.green,
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
                  title: const Text('Méthode de paiement préférée'),
                  subtitle: Text(_selectedPaymentMethod),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Méthode de paiement par défaut'),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _availablePaymentMethods.map((method) {
                              return RadioListTile<String>(
                                title: Text(method),
                                value: method,
                                groupValue: _selectedPaymentMethod,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                  Navigator.pop(context);
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Méthode de paiement mise à jour'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          ),
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
          
          // Paramètres réseau et données
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
                    'Réseau et données',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Mode économie de données'),
                  subtitle: const Text('Réduire l\'utilisation des données mobiles'),
                  value: _dataLimitMode,
                  onChanged: (bool value) {
                    setState(() {
                      _dataLimitMode = value;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? 'Mode économie de données activé' : 'Mode économie de données désactivé'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Mode hors ligne'),
                  subtitle: const Text('Accéder aux données sans connexion internet'),
                  value: _offlineMode,
                  onChanged: (bool value) {
                    setState(() {
                      _offlineMode = value;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? 'Mode hors ligne activé' : 'Mode hors ligne désactivé'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Gérer le stockage'),
                  subtitle: const Text('Gérer les données mises en cache'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Gérer le stockage'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Vider le cache'),
                              subtitle: const Text('Effacer les données temporaires'),
                              leading: const Icon(Icons.cleaning_services),
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Implémenter la suppression du cache
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cache vidé avec succès'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              title: const Text('Télécharger les données essentielles'),
                              subtitle: const Text('Pour utilisation hors ligne'),
                              leading: const Icon(Icons.download),
                              onTap: () {
                                Navigator.pop(context);
                                // TODO: Implémenter le téléchargement des données
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Téléchargement des données essentielles en cours...'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('FERMER'),
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
                  title: const Text('Notifications SMS'),
                  subtitle: const Text('Recevoir des notifications par SMS (utile en cas de connexion internet limitée)'),
                  value: _smsNotificationsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _smsNotificationsEnabled = value;
                    });
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value ? 'Notifications SMS activées' : 'Notifications SMS désactivées'),
                        backgroundColor: Colors.green,
                      ),
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
                              backgroundColor: Colors.blue,
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
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      : null,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Alertes coupure d\'eau/électricité'),
                  subtitle: const Text('Recevoir des notifications en cas de coupure d\'eau ou d\'électricité'),
                  value: _notificationsEnabled,
                  onChanged: _notificationsEnabled
                      ? (bool value) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cette option est liée aux notifications push'),
                              backgroundColor: Colors.blue,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                  child: Text(
                    'Légal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Politique de confidentialité'),
                  subtitle: const Text('Comment nous protégeons vos données'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    const privacyUrl = 'https://presentation.chapechaperesidence.com/politique-de-confidentialite';
                    final Uri uri = Uri.parse(privacyUrl);
                    try {
                      if (await canLaunchUrl(uri)) {
                        // Utiliser platformDefault au lieu de externalApplication pour éviter l'erreur component name
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossible d\'ouvrir la page de confidentialité'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Erreur URL: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Conditions d\'utilisation'),
                  subtitle: const Text('Règles d\'utilisation du service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    const termsUrl = 'https://presentation.chapechaperesidence.com/conditions';
                    final Uri uri = Uri.parse(termsUrl);
                    try {
                      if (await canLaunchUrl(uri)) {
                        // Utiliser platformDefault au lieu de externalApplication pour éviter l'erreur component name
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossible d\'ouvrir les conditions d\'utilisation'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Erreur URL: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Règlement de la plateforme'),
                  subtitle: const Text('Normes spécifiques à ChapeChape Residence'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    const rulesUrl = 'https://presentation.chapechaperesidence.com/conditions';
                    final Uri uri = Uri.parse(rulesUrl);
                    try {
                      if (await canLaunchUrl(uri)) {
                        // Utiliser platformDefault au lieu de externalApplication pour éviter l'erreur component name
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Impossible d\'ouvrir le règlement de la plateforme'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Erreur URL: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: ${e.toString()}'),
                          backgroundColor: Colors.red,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
                  child: Text(
                    'À propos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('À propos de ChapeChape Residence'),
                  subtitle: const Text('Informations sur l\'application'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'ChapeChape Residence Partner',
                      applicationVersion: '$_appVersion (build $_buildNumber)',
                      applicationIcon: Image.asset(
                        'assets/images/logo.png',
                        width: 50,
                        height: 50,
                      ),
                      applicationLegalese: '© 2024 ChapeChape Residence. Tous droits réservés.',
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'ChapeChape Residence Partner est une application qui permet aux propriétaires et gestionnaires de résidences de gérer leurs logements, réservations et paiements.',
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'L\'application est spécialement conçue pour le marché africain, avec des fonctionnalités adaptées aux réalités locales comme la gestion des méthodes de paiement mobile (Wave, Orange Money, MTN Money), l\'information sur les infrastructures (eau, électricité), et le mode hors ligne pour les zones à connectivité limitée.',
                        ),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Contactez-nous'),
                  subtitle: const Text('Besoin d\'aide ou de renseignements?'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Contactez-nous'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Email'),
                              subtitle: const Text('support@chapechaperesidence.com'),
                              leading: const Icon(Icons.email_outlined),
                              onTap: () async {
                                final Uri emailUri = Uri(
                                  scheme: 'mailto',
                                  path: 'support@chapechaperesidence.com',
                                  queryParameters: {
                                    'subject': 'Contact depuis l\'application Partner',
                                  },
                                );
                                
                                try {
                                  if (await canLaunchUrl(emailUri)) {
                                    await launchUrl(emailUri, mode: LaunchMode.platformDefault);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Impossible d\'ouvrir l\'application d\'email'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Erreur d\'email: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              title: const Text('Téléphone'),
                              subtitle: const Text('+225 07 48 00 10 42'),
                              leading: const Icon(Icons.phone_outlined),
                              onTap: () async {
                                final Uri phoneUri = Uri(
                                  scheme: 'tel',
                                  path: '+2250748001042',
                                );
                                
                                try {
                                  if (await canLaunchUrl(phoneUri)) {
                                    await launchUrl(phoneUri, mode: LaunchMode.platformDefault);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Impossible d\'ouvrir l\'application téléphone'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Erreur de téléphone: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                            ListTile(
                              title: const Text('Site web'),
                              subtitle: const Text('presentation.chapechaperesidence.com'),
                              leading: const Icon(Icons.language_outlined),
                              onTap: () async {
                                final Uri webUri = Uri.parse('https://presentation.chapechaperesidence.com');
                                
                                try {
                                  if (await canLaunchUrl(webUri)) {
                                    await launchUrl(webUri, mode: LaunchMode.platformDefault);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Impossible d\'ouvrir le site web'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Erreur de site web: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('FERMER'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Version de l\'application'),
                  subtitle: Text('$_appVersion (build $_buildNumber)'),
                  trailing: const Icon(Icons.info_outline),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Version $_appVersion - Build $_buildNumber'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                
                // Widget watermark de copyright
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: PartnerWatermarkWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
