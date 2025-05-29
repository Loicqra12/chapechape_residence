import 'package:flutter/material.dart';
import '../../core/config/app_config_manager.dart';

/// Widget permettant de basculer entre HTTP et HTTPS
/// Utile pendant la phase de développement pour tester l'API
class HttpToggleSwitch extends StatefulWidget {
  const HttpToggleSwitch({Key? key}) : super(key: key);

  @override
  State<HttpToggleSwitch> createState() => _HttpToggleSwitchState();
}

class _HttpToggleSwitchState extends State<HttpToggleSwitch> {
  bool _isHttps = AppConfigManager.useSecureConnection;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration API',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Protocole: ${_isHttps ? "HTTPS" : "HTTP"}',
                  style: TextStyle(
                    color: _isHttps ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _isHttps,
                  activeColor: Colors.green,
                  onChanged: (value) async {
                    await AppConfigManager.toggleSecureConnection();
                    setState(() {
                      _isHttps = AppConfigManager.useSecureConnection;
                    });
                    // Afficher un message pour informer l'utilisateur qu'un redémarrage peut être nécessaire
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'API configurée en ${_isHttps ? "HTTPS" : "HTTP"}. Un redémarrage peut être nécessaire.',
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'URL API: ${AppConfigManager.apiUrl}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
