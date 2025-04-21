import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:chapechape_client/presentation/screens/settings/temperature_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/display_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/storage_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color goldColor = Color(0xFFFFD700);
  static const Color darkGold = Color(0xFFCCAC00);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);
  static const Color greyColor = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: blackColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Paramètres'),
        backgroundColor: goldColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'Paramètres de l\'appareil'),
          _buildSettingItem(
            context,
            'Appareils connectés',
            'Gérer tous vos appareils connectés',
            Icons.devices,
            () {
              // Navigation vers les paramètres des appareils
            },
          ),
          _buildSettingItem(
            context,
            'Température',
            'Unités de température et préférences',
            Icons.thermostat_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TemperatureScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            context,
            'Affichage',
            'Thème, luminosité et taille de texte',
            Icons.brightness_6_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DisplayScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            context,
            'Notifications',
            'Gérer les notifications push',
            Icons.notifications_outlined,
            () {
              // Navigation vers les paramètres de notifications
            },
          ),
          _buildSettingItem(
            context,
            'Stockage et cache',
            'Gérer le stockage local et les données en cache',
            Icons.storage_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StorageScreen(),
                ),
              );
            },
          ),
          _buildSettingItem(
            context,
            'Langue',
            'Choisir la langue de l\'application',
            Icons.language_outlined,
            () {
              // Navigation vers les paramètres de langue
            },
          ),
          _buildSettingItem(
            context,
            'À propos',
            'Informations sur l\'application et mise à jour',
            Icons.info_outline,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Paramètres des e-mails'),
          _buildSettingItem(
            context,
            'Fréquence des e-mails',
            'Définir la fréquence de réception des e-mails',
            Icons.schedule_outlined,
            () {
              // Navigation vers les paramètres de fréquence des e-mails
            },
          ),
          _buildSettingItem(
            context,
            'Types de notifications',
            'Choisir les types d\'e-mails à recevoir',
            Icons.mail_outline,
            () {
              // Navigation vers les paramètres de types d'e-mails
            },
          ),
          _buildSettingItem(
            context,
            'Format des e-mails',
            'Configurer le format des e-mails reçus',
            Icons.format_paint_outlined,
            () {
              // Navigation vers les paramètres de format des e-mails
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Compte et sécurité'),
          _buildSettingItem(
            context,
            'Informations personnelles',
            'Modifier vos informations de profil',
            Icons.person_outline,
            () {
              // Navigation vers les paramètres de profil
            },
          ),
          _buildSettingItem(
            context,
            'Mot de passe',
            'Modifier votre mot de passe',
            Icons.lock_outline,
            () {
              // Navigation vers les paramètres de mot de passe
            },
          ),
          _buildSettingItem(
            context,
            'Déconnexion',
            'Se déconnecter de l\'application',
            Icons.logout,
            () {
              // Action de déconnexion
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: darkGold,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return Card(
      elevation: 0,
      color: greyColor.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : orangeColor,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : blackColor,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}