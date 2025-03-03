import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                SwitchListTile(
                  title: const Text('Mode sombre'),
                  subtitle: const Text('Activer le thème sombre'),
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (bool value) {
                    // TODO: Implémenter le changement de thème
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifications push'),
                  subtitle: const Text('Recevoir des notifications push'),
                  value: true,
                  onChanged: (bool value) {
                    // TODO: Implémenter les notifications
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Langue'),
                  subtitle: const Text('Français'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Implémenter le changement de langue
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                  onTap: () {
                    // TODO: Naviguer vers la page de confidentialité
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Conditions d\'utilisation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: Naviguer vers les conditions
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
