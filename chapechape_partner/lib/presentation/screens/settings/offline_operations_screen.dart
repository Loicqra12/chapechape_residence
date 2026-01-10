import 'package:flutter/material.dart';
import '../../../core/services/offline_queue_service.dart';
import '../../../core/theme/colors.dart';
import 'package:intl/intl.dart';

/// Écran affichant toutes les opérations en attente de synchronisation
class OfflineOperationsScreen extends StatefulWidget {
  const OfflineOperationsScreen({super.key});

  @override
  State<OfflineOperationsScreen> createState() => _OfflineOperationsScreenState();
}

class _OfflineOperationsScreenState extends State<OfflineOperationsScreen> {
  final OfflineQueueService _queueService = OfflineQueueService();
  
  List<QueueOperation> _operations = [];
  QueueStats? _stats;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadOperations();
    _listenToQueueEvents();
  }

  void _listenToQueueEvents() {
    _queueService.queueEvents.listen((event) {
      if (mounted) {
        switch (event.type) {
          case QueueEventType.operationEnqueued:
          case QueueEventType.operationCompleted:
          case QueueEventType.queueProcessed:
          case QueueEventType.queueCleared:
            _loadOperations();
            break;
          default:
            break;
        }
      }
    });
  }

  Future<void> _loadOperations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final operations = await _queueService.getPendingOperations();
      final stats = await _queueService.getQueueStats();
      
      if (mounted) {
        setState(() {
          _operations = operations;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showMessage('Erreur lors du chargement: $e', isError: true);
      }
    }
  }

  Future<void> _syncAll() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _queueService.forceProcessQueue();
      _showMessage('Synchronisation réussie !', isError: false);
      await _loadOperations();
    } catch (e) {
      _showMessage('Erreur lors de la synchronisation: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _clearQueue() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider la file d\'attente'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les opérations en attente ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
            ),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _queueService.clearQueue();
      _showMessage('File d\'attente vidée', isError: false);
      await _loadOperations();
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

  String _getOperationTypeLabel(String type) {
    switch (type) {
      case 'create_residence':
        return 'Créer résidence';
      case 'update_residence':
        return 'Modifier résidence';
      case 'delete_residence':
        return 'Supprimer résidence';
      case 'create_reservation':
        return 'Créer réservation';
      case 'update_reservation':
        return 'Modifier réservation';
      case 'cancel_reservation':
        return 'Annuler réservation';
      case 'create_payment':
        return 'Créer paiement';
      case 'update_payment':
        return 'Modifier paiement';
      case 'send_message':
        return 'Envoyer message';
      case 'update_profile':
        return 'Modifier profil';
      default:
        return type;
    }
  }

  IconData _getOperationIcon(String type) {
    if (type.contains('residence')) return Icons.home;
    if (type.contains('reservation')) return Icons.calendar_today;
    if (type.contains('payment')) return Icons.payment;
    if (type.contains('message')) return Icons.message;
    if (type.contains('profile')) return Icons.person;
    return Icons.sync;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opérations en attente'),
        actions: [
          if (_operations.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearQueue,
              tooltip: 'Vider la file',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadOperations,
              child: Column(
                children: [
                  // Statistiques
                  if (_stats != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'En attente',
                            _stats!.pending.toString(),
                            Colors.orange,
                          ),
                          _buildStatItem(
                            'Réussies',
                            _stats!.completed.toString(),
                            Colors.green,
                          ),
                          _buildStatItem(
                            'Échec',
                            _stats!.failed.toString(),
                            Colors.red,
                          ),
                        ],
                      ),
                    ),

                  // Liste des opérations
                  Expanded(
                    child: _operations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.green[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Aucune opération en attente',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toutes vos modifications sont synchronisées',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _operations.length,
                            padding: const EdgeInsets.all(16),
                            itemBuilder: (context, index) {
                              final operation = _operations[index];
                              return _buildOperationCard(operation);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _operations.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isSyncing ? null : _syncAll,
              backgroundColor: AppColors.primary,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(_isSyncing ? 'Synchronisation...' : 'Synchroniser tout'),
            )
          : null,
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildOperationCard(QueueOperation operation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Icon(
            _getOperationIcon(operation.type),
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Text(
          _getOperationTypeLabel(operation.type),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_formatDate(operation.createdAt)),
            if (operation.attempts > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${operation.attempts} tentative${operation.attempts > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        trailing: operation.status == QueueStatus.failed
            ? const Icon(Icons.error, color: Colors.red)
            : operation.status == QueueStatus.completed
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.pending, color: Colors.orange),
      ),
    );
  }
}


