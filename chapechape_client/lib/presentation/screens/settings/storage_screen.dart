import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/services/shared_preferences_service.dart';
import 'package:chapechape_client/core/services/error_message_service.dart';
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
        ErrorMessageService.showSuccess(
          context,
          'Cache effacé avec succès',
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorMessageService.showError(
          context,
          e,
          contextType: 'cache_clear',
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
                padding: AppSpacing.pagePadding,
                children: [
                  // En-tête explicatif
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'Gérez l\'espace de stockage utilisé par l\'application.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                  ),
                  
                  // Graphique d'utilisation
                  _buildStorageGraph(),
                  
                  AppSpacing.verticalLg,
                  
                  // Carte du cache
                  _buildCacheCard(),
                  
                  AppSpacing.verticalMd,
                  
                  // Carte des données persistantes
                  _buildDataCard(),
                  
                  AppSpacing.verticalXl,
                  
                  // Actions avancées
                  Text(
                    'Actions avancées',
                    style: AppTextStyles.subtitle,
                  ),
                  
                  AppSpacing.verticalSmd,
                  
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Utilisation du stockage',
              style: AppTextStyles.subtitle,
            ),
            AppSpacing.verticalMd,
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
            AppSpacing.verticalMd,
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
        SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            Text(
              size,
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cached, color: orangeColor, size: 24),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Données du cache',
                  style: AppTextStyles.subtitle,
                ),
                const Spacer(),
                Text(
                  _cacheSize,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            AppSpacing.verticalSmd,
            Text(
              'Le cache contient des données temporaires comme les images et les réponses API. Effacer le cache peut aider si l\'application rencontre des problèmes ou pour libérer de l\'espace.',
              style: AppTextStyles.body,
            ),
            AppSpacing.verticalMd,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isClearingCache ? null : _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.smd),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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
                          SizedBox(width: AppSpacing.sm),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: orangeColor, size: 24),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Données de l\'application',
                  style: AppTextStyles.subtitle,
                ),
                const Spacer(),
                Text(
                  _appSize,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            AppSpacing.verticalSmd,
            Text(
              'Ces données incluent vos préférences, l\'historique local et d\'autres informations nécessaires au bon fonctionnement de l\'application.',
              style: AppTextStyles.body,
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
        ErrorMessageService.showSuccess(
          context,
          'Préférences réinitialisées avec succès',
        );
        
        await _loadStorageInfo();
      }
    } catch (e) {
      if (mounted) {
        ErrorMessageService.showError(
          context,
          e,
          contextType: 'cache_clear',
        );
      }
    }
  }
} 