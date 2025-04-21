import 'package:flutter/material.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/services/shared_preferences_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  static const Color goldColor = Color(0xFFFFD700);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);
  static const Color greyColor = Color(0xFFE0E0E0);
  
  bool _isLoading = true;
  bool _isClearingCache = false;
  String _cacheSize = "0 B";
  String _appSize = "0 B";
  int _totalSize = 0;
  
  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Obtenir le répertoire temporaire où est stocké le cache
      final tempDir = await getTemporaryDirectory();
      int cacheSize = await _calculateDirSize(tempDir);
      
      // Obtenir le répertoire d'application
      final appDir = await getApplicationDocumentsDirectory();
      int appSize = await _calculateDirSize(appDir);
      
      _totalSize = cacheSize + appSize;
      
      setState(() {
        _cacheSize = _formatBytes(cacheSize, 2);
        _appSize = _formatBytes(appSize, 2);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _cacheSize = "Erreur";
        _appSize = "Erreur";
        _isLoading = false;
      });
    }
  }
  
  Future<int> _calculateDirSize(Directory dir) async {
    int totalSize = 0;
    try {
      if (dir.existsSync()) {
        dir
            .listSync(recursive: true, followLinks: false)
            .forEach((FileSystemEntity entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
    } catch (e) {
      // Ignore les erreurs d'accès
    }
    return totalSize;
  }
  
  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(decimals)) + ' ' + suffixes[i];
  }
  
  Future<void> _clearCache() async {
    setState(() {
      _isClearingCache = true;
    });
    
    try {
      // Effacer le cache
      final cacheService = CacheService();
      await cacheService.clear();
      
      // Effacer le répertoire temporaire
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((file) {
          if (file is File) {
            try {
              file.deleteSync();
            } catch (e) {
              // Ignorer les erreurs d'accès
            }
          }
        });
      }
      
      // Actualiser les informations
      await _loadStorageInfo();
      
      // Afficher une confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache effacé avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'effacement du cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isClearingCache = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: blackColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Stockage et cache'),
        backgroundColor: goldColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStorageInfo,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // En-tête explicatif
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      'Gérez l\'espace de stockage utilisé par l\'application.',
                      style: TextStyle(fontSize: 16.0, color: Colors.grey),
                    ),
                  ),
                  
                  // Graphique d'utilisation
                  _buildStorageGraph(),
                  
                  const SizedBox(height: 24),
                  
                  // Carte du cache
                  _buildCacheCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Carte des données persistantes
                  _buildDataCard(),
                  
                  const SizedBox(height: 32),
                  
                  // Actions avancées
                  const Text(
                    'Actions avancées',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Réinitialiser toutes les préférences'),
                    subtitle: const Text('Efface tous les paramètres personnalisés'),
                    onTap: _showResetConfirmation,
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildStorageGraph() {
    return Card(
      elevation: 0,
      color: greyColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Utilisation du stockage',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.7,
                      backgroundColor: Colors.grey[300],
                      color: orangeColor,
                      minHeight: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStorageItem('Cache', _cacheSize, Colors.amber),
                _buildStorageItem('App', _appSize, Colors.green),
                _buildStorageItem('Total', _formatBytes(_totalSize, 2), orangeColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStorageItem(String label, String size, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              size,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCacheCard() {
    return Card(
      elevation: 0,
      color: greyColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cached, color: orangeColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Données du cache',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _cacheSize,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Le cache contient des données temporaires comme les images et les réponses API. Effacer le cache peut aider si l\'application rencontre des problèmes ou pour libérer de l\'espace.',
              style: TextStyle(fontSize: 14.0),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isClearingCache ? null : _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isClearingCache
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Effacement en cours...'),
                        ],
                      )
                    : const Text('Effacer le cache'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDataCard() {
    return Card(
      elevation: 0,
      color: greyColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: orangeColor, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Données de l\'application',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  _appSize,
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Ces données incluent vos préférences, l\'historique local et d\'autres informations nécessaires au bon fonctionnement de l\'application.',
              style: TextStyle(fontSize: 14.0),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les préférences'),
        content: const Text(
          'Êtes-vous sûr de vouloir réinitialiser toutes les préférences ? Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetPreferences();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _resetPreferences() async {
    try {
      final prefs = await SharedPreferencesService.getInstance();
      await prefs.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences réinitialisées avec succès'),
            duration: Duration(seconds: 2),
          ),
        );
        
        await _loadStorageInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la réinitialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 