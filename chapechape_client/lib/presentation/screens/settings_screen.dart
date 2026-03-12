import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/presentation/screens/settings/temperature_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/display_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/storage_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/about_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/notification_settings_screen.dart';
import 'package:chapechape_client/presentation/screens/settings/language_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: ListView(
        padding: AppSpacing.pagePadding.copyWith(
          bottom: AppSpacing.pagePadding.bottom + safeBottom + 8,
        ),
        children: [
          _buildSectionHeader(context, 'Paramètres de l\'appareil'),
          _buildSettingTile(context, 'Appareils connectés', Icons.devices, () {}),
          _buildSettingTile(
            context,
            'Température',
            Icons.thermostat_outlined,
            () => context.push('/profile/settings/temperature'),
          ),
          _buildSettingTile(
            context,
            'Affichage',
            Icons.brightness_6_outlined,
            () => context.push('/profile/settings/display'),
          ),
          _buildSettingTile(
            context,
            'Notifications',
            Icons.notifications_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
          _buildSettingTile(
            context,
            'Stockage et cache',
            Icons.storage_outlined,
            () => context.push('/profile/settings/storage'),
          ),
          _buildSettingTile(
            context,
            'Langue',
            Icons.language_outlined,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageScreen(),
                ),
              );
            },
          ),
          _buildSettingTile(
            context,
            'À propos',
            Icons.info_outline,
            () => context.push('/profile/settings/about'),
          ),
          AppSpacing.verticalLg,
          _buildSectionHeader(context, 'Paramètres des e-mails'),
          _buildSettingTile(context, 'Fréquence des e-mails', Icons.schedule_outlined, () {}),
          _buildSettingTile(context, 'Types de notifications', Icons.mail_outline, () {}),
          _buildSettingTile(context, 'Format des e-mails', Icons.format_paint_outlined, () {}),
          AppSpacing.verticalLg,
          _buildSectionHeader(context, 'Compte et sécurité'),
          _buildSettingTile(context, 'Informations personnelles', Icons.person_outline, () {}),
          _buildSettingTile(context, 'Mot de passe', Icons.lock_outline, () => context.push('/password-change')),
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

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}