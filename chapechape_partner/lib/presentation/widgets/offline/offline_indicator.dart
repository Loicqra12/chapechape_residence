import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/offline_queue_service.dart';

/// Widget indicateur de mode offline
class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkStatus>(
      stream: ConnectivityService().status,
      builder: (context, snapshot) {
        final isOnline = snapshot.data == NetworkStatus.online;
        
        if (isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mode hors-ligne - Les données seront synchronisées',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget compteur d'opérations en attente
class PendingOperationsCounter extends StatelessWidget {
  const PendingOperationsCounter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QueueStats>(
      future: OfflineQueueService().getQueueStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.pending == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sync, color: Colors.blue.shade700, size: 16),
              const SizedBox(width: 4),
              Text(
                '${snapshot.data!.pending} en attente',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget bouton de synchronisation manuelle
class SyncButton extends StatelessWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NetworkStatus>(
      stream: ConnectivityService().status,
      builder: (context, snapshot) {
        final isOnline = snapshot.data == NetworkStatus.online;
        
        if (!isOnline) {
          return const SizedBox.shrink();
        }

        return IconButton(
          icon: const Icon(Icons.sync),
          onPressed: () async {
            await OfflineQueueService().forceProcessQueue();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Synchronisation en cours...'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          tooltip: 'Synchroniser maintenant',
        );
      },
    );
  }
}


