import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_queue_service.dart';
import '../../../core/theme/colors.dart';
import 'package:go_router/go_router.dart';

/// Bannière affichée en haut de l'écran quand l'appareil est hors ligne
/// Affiche le nombre d'opérations en attente et permet de synchroniser
class OfflineStatusBanner extends StatefulWidget {
  const OfflineStatusBanner({super.key});

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  final ConnectivityService _connectivityService = ConnectivityService();
  final OfflineQueueService _queueService = OfflineQueueService();
  
  bool _isOnline = true;
  int _pendingOperationsCount = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _listenToConnectivity();
    _listenToQueueEvents();
  }

  Future<void> _initializeServices() async {
    _isOnline = _connectivityService.isOnline;
    await _updatePendingCount();
  }

  void _listenToConnectivity() {
    _connectivityService.status.listen((status) {
      if (mounted) {
        setState(() {
          _isOnline = status == NetworkStatus.online;
        });
      }
    });
  }

  void _listenToQueueEvents() {
    _queueService.queueEvents.listen((event) {
      if (mounted) {
        switch (event.type) {
          case QueueEventType.operationEnqueued:
          case QueueEventType.operationCompleted:
          case QueueEventType.queueProcessed:
          case QueueEventType.queueCleared:
            _updatePendingCount();
            break;
          default:
            break;
        }
      }
    });
  }

  Future<void> _updatePendingCount() async {
    final stats = await _queueService.getQueueStats();
    if (mounted) {
      setState(() {
        _pendingOperationsCount = stats.pending;
      });
    }
  }

  Future<void> _syncNow() async {
    if (!_isOnline) {
      _showMessage('Impossible de synchroniser: vous êtes hors ligne', isError: true);
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await _queueService.forceProcessQueue();
      _showMessage('Synchronisation réussie !', isError: false);
      await _updatePendingCount();
    } catch (e) {
      _showMessage('Erreur lors de la synchronisation: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _showMessage(String message, {required bool isError}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _viewPendingOperations() {
    context.push('/settings/offline-operations');
  }

  @override
  Widget build(BuildContext context) {
    // Ne rien afficher si en ligne et aucune opération en attente
    if (_isOnline && _pendingOperationsCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.orange[100] : Colors.red[100],
        border: Border(
          bottom: BorderSide(
            color: _isOnline ? Colors.orange[300]! : Colors.red[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icône de statut
          Icon(
            _isOnline ? Icons.sync : Icons.cloud_off,
            color: _isOnline ? Colors.orange[700] : Colors.red[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          
          // Texte de statut
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isOnline 
                      ? 'Opérations en attente de synchronisation'
                      : 'Mode hors ligne',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _isOnline ? Colors.orange[900] : Colors.red[900],
                  ),
                ),
                if (_pendingOperationsCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$_pendingOperationsCount opération${_pendingOperationsCount > 1 ? 's' : ''} en attente',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isOnline ? Colors.orange[800] : Colors.red[800],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Bouton Voir
          if (_pendingOperationsCount > 0) ...[
            TextButton(
              onPressed: _viewPendingOperations,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Voir',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isOnline ? Colors.orange[900] : Colors.red[900],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          
          // Bouton Synchroniser
          if (_isOnline && _pendingOperationsCount > 0)
            ElevatedButton(
              onPressed: _isSyncing ? null : _syncNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0,
              ),
              child: _isSyncing
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Synchroniser',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}


