import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/services/shared_preferences_service.dart';

class StorageCacheScreen extends StatefulWidget {
  const StorageCacheScreen({super.key});

  @override
  State<StorageCacheScreen> createState() => _StorageCacheScreenState();
}

class _StorageCacheScreenState extends State<StorageCacheScreen> {
  static const Color goldColor = Color(0xFFFFD700);
  static const Color orangeColor = Color(0xFFFF8C00);
  static const Color blackColor = Color(0xFF1A1A1A);
  static const Color greyColor = Color(0xFFE0E0E0);

  bool _isLoading = true;
  String _cacheSize = "0 Ko";
  String _preferencesSize = "0 Ko";
  bool _clearingCache = false;
  bool _clearingPreferences = false;

  @override
  void initState() {
    super.initState();
    _loadStorageInfo();
  }

  Future<void> _loadStorageInfo() async {
    setState(() {
      _isLoading = true;
    });

    // Récupération de l'information sur le stockage
    try {
      final cacheService = await CacheService.getInstance();
      final cacheSize = await cacheService.getCacheSize();
      
      final prefsService = await SharedPreferencesService.getInstance();
      final prefsSize = await prefsService.getSize();

      setState(() {
        _cacheSize = _formatBytes(cacheSize);
        _preferencesSize = _formatBytes(prefsSize);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _cacheSize = "Erreur";
        _preferencesSize = "Erreur";
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return "$bytes o";
    } else if (bytes < 1024 * 1024) {
      return "${(bytes / 1024).toStringAsFixed(1)} Ko";
    } else if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo";
    } else {
      return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} Go";
    }
  }

  Future<void> _clearCache() async {
    setState(() {
      _clearingCache = true;
    });

    try {
      final cacheService = await CacheService.getInstance();
      await cacheService.clearCache();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache effacé avec succès'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'effacement du cache: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _clearingCache = false;
        });
        _loadStorageInfo();
      }
    }
  }

  Future<void> _clearPreferences() async {
    setState(() {
      _clearingPreferences = true;
    });

    // Afficher un dialogue d'avertissement
    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les préférences?'),
        content: const Text(
          'Cette action va réinitialiser toutes vos préférences d\'application, y compris les paramètres de thème, de langue et vos sessions sauvegardées. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (shouldClear != true) {
      setState(() {
        _clearingPreferences = false;
      });
      return;
    }

    try {
      final prefsService = await SharedPreferencesService.getInstance();
      await prefsService.clear();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Préférences réinitialisées'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réinitialisation: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _clearingPreferences = false;
        });
        _loadStorageInfo();
      }
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
        title: const Text('Stockage et Cache'),
        backgroundColor: goldColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: blackColor),
            onPressed: _loadStorageInfo,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: AppSpacing.pagePadding,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Gérez l\'espace de stockage utilisé par l\'application.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ),
                
                // Carte d'information sur le cache
                _buildStorageCard(
                  title: 'Cache des données',
                  subtitle: 'Données temporaires stockées pour améliorer les performances',
                  icon: Icons.storage,
                  size: _cacheSize,
                  onClear: _clearingCache ? null : _clearCache,
                  isClearing: _clearingCache,
                ),
                
                AppSpacing.verticalMd,
                
                // Carte d'information sur les préférences
                _buildStorageCard(
                  title: 'Préférences utilisateur',
                  subtitle: 'Paramètres et données personnalisées',
                  icon: Icons.settings,
                  size: _preferencesSize,
                  onClear: _clearingPreferences ? null : _clearPreferences,
                  isClearing: _clearingPreferences,
                  clearButtonText: 'Réinitialiser',
                  clearButtonColor: Colors.red,
                ),
                
                AppSpacing.verticalLg,
                
                // Information sur le stockage
                Card(
                  color: greyColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Padding(
                    padding: AppSpacing.pagePadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(AppSpacing.smd),
                              decoration: BoxDecoration(
                                color: orangeColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: orangeColor,
                              ),
                            ),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'À propos du stockage',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        AppSpacing.verticalMd,
                        Text(
                          'Le cache contient des données temporaires qui aident l\'application à fonctionner plus rapidement. Vous pouvez l\'effacer à tout moment sans perdre d\'informations importantes.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        AppSpacing.verticalSm,
                        Text(
                          'Les préférences contiennent vos paramètres personnalisés. La réinitialisation restaurera tous les paramètres par défaut.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStorageCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String size,
    required VoidCallback? onClear,
    required bool isClearing,
    String clearButtonText = 'Effacer',
    Color clearButtonColor = orangeColor,
  }) {
    return Card(
      elevation: 1,
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
                Container(
                  padding: EdgeInsets.all(AppSpacing.smd),
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: goldColor,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AppSpacing.verticalXs,
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.verticalMd,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Taille: $size',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton(
                  onPressed: onClear,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: clearButtonColor,
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  child: isClearing
                      ? SizedBox(
                          width: AppSpacing.md + AppSpacing.xs,
                          height: AppSpacing.md + AppSpacing.xs,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(clearButtonText),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 