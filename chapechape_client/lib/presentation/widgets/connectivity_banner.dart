import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:chapechape_client/core/services/api_service.dart';
import 'package:chapechape_client/core/services/cache_service.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';

/// Widget affichant une bannière d'état de connexion
/// qui apparaît lorsque l'appareil est hors ligne
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  
  const ConnectivityBanner({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner> {
  late final ApiService _apiService;
  final CacheService _cacheService = CacheService();
  bool _isConnected = true;
  bool _wasOffline = false; // Nouveau : tracker si on était hors ligne
  bool _showSyncBanner = false; // Nouveau : contrôler l'affichage de la bannière sync
  final _connectivityChangeController = StreamController<bool>.broadcast();
  Timer? _connectivityTimer;
  
  @override
  void initState() {
    super.initState();
    
    // Initialiser l'ApiService correctement
    ApiService.initialize().then((service) {
      if (!mounted) return;
      _apiService = service;
      // Vérifier la connectivité immédiatement après l'initialisation
      _checkConnectivity();
    });
    
    // Vérification périodique de la connectivité
    _startPeriodicConnectivityCheck();
  }
  
  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivityChangeController.close();
    super.dispose();
  }
  
  // Lancer une vérification périodique simple de connectivité
  void _startPeriodicConnectivityCheck() {
    _connectivityTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _checkConnectivity();
      }
    });
    
    // Vérification initiale
    _checkConnectivity();
  }
  
  // Vérifier la connectivité de manière robuste
  Future<void> _checkConnectivity() async {
    if (!mounted) return;

    try {
      bool isNowConnected = false;
      
      // Vérifier d'abord la connectivité Internet générale
      try {
        final internetResponse = await http.get(
          Uri.parse('https://www.google.com'),
        ).timeout(const Duration(seconds: 3));
        
        if (internetResponse.statusCode == 200) {
          // Si Internet fonctionne, vérifier le serveur backend
          try {
            final result = await _apiService.getData('/ping');
            isNowConnected = result != null && !result.isNetworkError;
          } catch (serverError) {
            // Si le serveur ne répond pas mais qu'Internet fonctionne,
            // considérer comme connecté (problème serveur temporaire)
            isNowConnected = true;
          }
        }
      } catch (internetError) {
        // Pas de connexion Internet
        isNowConnected = false;
      }
      
      if (!mounted) return;

      // Mettre à jour l'état si changement
      if (isNowConnected != _isConnected) {
        setState(() {
          // Si on passe de hors ligne à en ligne, marquer qu'on était hors ligne
          if (!_isConnected && isNowConnected) {
            _wasOffline = true;
            _showSyncBanner = true; // Afficher la bannière de sync
            _autoHideSyncBanner(); // Auto-masquer après 10 secondes
          }
          // Si on passe de en ligne à hors ligne, marquer qu'on est hors ligne
          else if (_isConnected && !isNowConnected) {
            _wasOffline = true;
            _showSyncBanner = false; // Masquer la bannière de sync
          }
          
          _isConnected = isNowConnected;
        });
        _connectivityChangeController.add(isNowConnected);
      }
    } catch (e) {
      if (!mounted) return;

      // En cas d'erreur, considérer que nous sommes hors ligne
      if (_isConnected) {
        setState(() {
          _isConnected = false;
          _wasOffline = true;
          _showSyncBanner = false; // Masquer la bannière de sync
        });
        _connectivityChangeController.add(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bannière d'état de connexion
        AnimatedCrossFade(
          firstChild: _buildOfflineBanner(context),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isConnected 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
        
        // Contenu principal
        Expanded(child: widget.child),
        
        // Bouton de synchronisation quand la connexion est rétablie
        SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSyncButton(context),
            crossFadeState: _showSyncBanner
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.lightGold,
              Color(0xFFFFFBF5),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            ...AppTheme.softShadow,
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.wifi_off,
                color: AppTheme.primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vous êtes hors ligne',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Certaines fonctionnalités limitées sont disponibles',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              onPressed: () {
                _checkConnectivity();
              },
              tooltip: 'Vérifier la connexion',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E5),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.35),
            width: 1,
          ),
          boxShadow: [
            ...AppTheme.softShadow,
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.wifi,
                  color: AppTheme.primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Connexion rétablie',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Synchronisation des données disponible',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    setState(() {
                      _showSyncBanner = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Synchronisation en cours...'),
                        backgroundColor: AppTheme.infoColor,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    final success = await _apiService.synchronizeOfflineData();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Synchronisation terminée avec succès'
                              : 'Échec de la synchronisation',
                        ),
                        backgroundColor: success
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    if (mounted) setState(() => _wasOffline = false);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de la synchronisation: $e'),
                        backgroundColor: AppTheme.errorColor,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Synchroniser'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Auto-masquer la bannière après un délai
  void _autoHideSyncBanner() {
    if (_showSyncBanner) {
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _showSyncBanner) {
          setState(() {
            _showSyncBanner = false;
            _wasOffline = false;
          });
        }
      });
    }
  }
  
  // Vérifier si l'appareil était précédemment hors ligne
  bool _wasPreviouslyConnected() {
    // Cette implémentation simple ne garde pas d'historique
    // Dans une implémentation réelle, on utiliserait SharedPreferences
    return false; // On suppose que c'est la première connexion
  }
} 