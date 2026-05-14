import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/config/app_config_manager.dart';
import 'package:chapechape_client/core/services/ip_detection_service.dart';

class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({Key? key}) : super(key: key);

  @override
  _ServerConfigScreenState createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  bool _useCustomServerUrl = false;
  bool _isLoading = false;
  bool _isServerReachable = false;
  String _statusMessage = '';
  List<String> _detectedIps = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() {
      _isLoading = true;
    });

    // Charger la configuration actuelle
    _useCustomServerUrl = AppConfigManager.useCustomServerUrl;
    _ipController.text = AppConfigManager.serverIp;
    _portController.text = AppConfigManager.serverPort.toString();

    // Vérifier si le serveur est accessible
    await _checkServerStatus();

    // Détecter les adresses IP locales
    final ipService = await IpDetectionService.initialize();
    _detectedIps = await ipService.detectLocalIps();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkServerStatus() async {
    setState(() {
      _statusMessage = 'Vérification de la connexion au serveur...';
    });

    final isReachable = await AppConfigManager.isServerReachable();

    setState(() {
      _isServerReachable = isReachable;
      _statusMessage = isReachable
          ? 'Serveur accessible ✅'
          : 'Serveur inaccessible ❌';
    });
  }

  Future<void> _autoDetectServer() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Détection automatique du serveur...';
    });

    final success = await AppConfigManager.autoDetectServerIp();

    if (success) {
      // Mettre à jour les contrôleurs avec les nouvelles valeurs
      _ipController.text = AppConfigManager.serverIp;
      _portController.text = AppConfigManager.serverPort.toString();
      
      setState(() {
        _statusMessage = 'Serveur détecté automatiquement ✅';
      });
      
      // Vérifier si le serveur est accessible
      await _checkServerStatus();
    } else {
      setState(() {
        _statusMessage = 'Échec de la détection automatique ❌';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveConfig() async {
    // Valider l'adresse IP
    final ipPattern = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
    if (!ipPattern.hasMatch(_ipController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adresse IP invalide')),
      );
      return;
    }

    // Valider le port
    final port = int.tryParse(_portController.text);
    if (port == null || port <= 0 || port > 65535) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Port invalide (1-65535)')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Enregistrement de la configuration...';
    });

    // Enregistrer la configuration
    await AppConfigManager.setUseCustomServerUrl(_useCustomServerUrl);
    await AppConfigManager.setServerIp(_ipController.text);
    await AppConfigManager.setServerPort(port);

    // Vérifier si le serveur est accessible
    await _checkServerStatus();

    setState(() {
      _isLoading = false;
      _statusMessage = 'Configuration enregistrée ✅';
    });

    // Afficher un message de succès
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration enregistrée avec succès')),
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Configuration du serveur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _checkServerStatus,
            tooltip: 'Vérifier la connexion',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statut du serveur
                  Container(
                    width: double.infinity,
                    padding: AppSpacing.cardPadding,
                    decoration: BoxDecoration(
                      color: _isServerReachable
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: _isServerReachable
                            ? Colors.green
                            : Colors.red,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _isServerReachable
                                ? Colors.green
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        AppSpacing.verticalSm,
                        Text(
                          'URL API: ${AppConfigManager.apiUrl}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalLg,

                  // Mode de configuration
                  SwitchListTile(
                    title: const Text('Utiliser une URL personnalisée'),
                    subtitle: const Text(
                        'Activer pour configurer manuellement l\'adresse du serveur'),
                    value: _useCustomServerUrl,
                    onChanged: (value) {
                      setState(() {
                        _useCustomServerUrl = value;
                      });
                    },
                  ),
                  const Divider(),
                  AppSpacing.verticalMd,

                  // Configuration manuelle
                  Text(
                    'Configuration du serveur',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppSpacing.verticalMd,
                  TextField(
                    controller: _ipController,
                    decoration: InputDecoration(
                      labelText: 'Adresse IP du serveur',
                      hintText: '192.168.1.78',
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.computer),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _useCustomServerUrl,
                  ),
                  AppSpacing.verticalMd,
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '4000',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                    enabled: _useCustomServerUrl,
                  ),
                  AppSpacing.verticalLg,

                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Détection automatique'),
                          onPressed: _isLoading ? null : _autoDetectServer,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.smd),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('Enregistrer'),
                          onPressed: _isLoading ? null : _saveConfig,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.smd),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.verticalLg,

                  // Adresses IP détectées
                  if (_detectedIps.isNotEmpty) ...[
                    Text(
                      'Adresses IP détectées',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.verticalSm,
                    ...List.generate(
                      _detectedIps.length,
                      (index) => ListTile(
                        leading: const Icon(Icons.lan),
                        title: Text(_detectedIps[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.content_copy),
                          onPressed: () {
                            _ipController.text = _detectedIps[index];
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Adresse IP copiée')),
                            );
                          },
                          tooltip: 'Utiliser cette IP',
                        ),
                        dense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
