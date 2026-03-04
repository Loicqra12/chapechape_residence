import 'package:flutter/material.dart';
import '../../../core/services/sync_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/sync/sync_bloc.dart';
import '../../../core/theme/colors.dart';

/// Widget qui affiche l'état actuel de la synchronisation
class SyncStatusWidget extends StatelessWidget {
  final bool showDetails;
  final bool showForceButton;
  
  const SyncStatusWidget({
    Key? key,
    this.showDetails = false,
    this.showForceButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: _getBackgroundColor(state),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getStatusIcon(state),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _getStatusMessage(state),
                  style: TextStyle(
                    color: _getTextColor(state),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (showForceButton && state is! SyncInProgress && _canForceSynch(state))
                IconButton(
                  icon: const Icon(Icons.sync, size: 18),
                  color: _getTextColor(state),
                  tooltip: 'Forcer la synchronisation',
                  onPressed: () {
                    context.read<SyncBloc>().add(SyncRequested());
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  /// Retourne l'icône correspondant à l'état de synchronisation
  Widget _getStatusIcon(SyncState state) {
    if (state is SyncInProgress) {
      return SizedBox(
        width: 16,
        height: 16, 
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _getTextColor(state),
        ),
      );
    } else if (state is SyncError) {
      return Icon(Icons.error_outline, 
        size: 16, 
        color: _getTextColor(state),
      );
    } else if (state is SyncOffline) {
      return Icon(Icons.wifi_off, 
        size: 16, 
        color: _getTextColor(state),
      );
    } else if (state is SyncSuccess) {
      return Icon(Icons.check_circle, 
        size: 16, 
        color: _getTextColor(state),
      );
    } else if (state is SyncInitial || state is SyncIdle) {
      if (state is SyncIdle && state.pendingOperations > 0) {
        return Icon(Icons.schedule, 
          size: 16, 
          color: _getTextColor(state),
        );
      }
      return Icon(Icons.sync, 
        size: 16, 
        color: _getTextColor(state),
      );
    } else {
      return Icon(Icons.sync_problem, 
        size: 16, 
        color: _getTextColor(state),
      );
    }
  }

  /// Retourne le message correspondant à l'état de synchronisation
  String _getStatusMessage(SyncState state) {
    if (state is SyncInProgress) {
      if (showDetails && state.currentEntity != null) {
        return 'Synchronisation de ${state.currentEntity}...';
      }
      return 'Synchronisation...';
    } else if (state is SyncError) {
      return showDetails ? 'Erreur: ${state.message}' : 'Erreur de synchronisation';
    } else if (state is SyncOffline) {
      return 'Hors-ligne';
    } else if (state is SyncSuccess) {
      return 'Synchronisé';
    } else if (state is SyncIdle) {
      if (state.pendingOperations > 0) {
        return '${state.pendingOperations} modifications en attente';
      }
      if (state.lastSyncTime != null) {
        // Formatage simple de la date/heure
        final now = DateTime.now();
        final diff = now.difference(state.lastSyncTime!);
        
        if (diff.inMinutes < 1) {
          return 'Synchronisé à l\'instant';
        } else if (diff.inMinutes < 60) {
          return 'Synchronisé il y a ${diff.inMinutes} min';
        } else if (diff.inHours < 24) {
          return 'Synchronisé il y a ${diff.inHours} h';
        } else {
          return 'Sync. ${state.lastSyncTime!.day}/${state.lastSyncTime!.month} à ${state.lastSyncTime!.hour}:${state.lastSyncTime!.minute.toString().padLeft(2, '0')}';
        }
      }
      return 'Prêt à synchroniser';
    } else {
      return 'État inconnu';
    }
  }

  /// Retourne la couleur de fond correspondant à l'état de synchronisation
  Color _getBackgroundColor(SyncState state) {
    if (state is SyncInProgress) {
      return AppColors.brandPrimary.withOpacity(0.2);
    } else if (state is SyncError) {
      return Colors.red.withOpacity(0.2);
    } else if (state is SyncOffline) {
      return Colors.orange.withOpacity(0.2);
    } else if (state is SyncSuccess) {
      return Colors.green.withOpacity(0.2);
    } else if (state is SyncIdle && state.pendingOperations > 0) {
      return Colors.amber.withOpacity(0.2);
    } else {
      return Colors.grey.withOpacity(0.2);
    }
  }

  /// Retourne la couleur du texte correspondant à l'état de synchronisation
  Color _getTextColor(SyncState state) {
    if (state is SyncInProgress) {
      return AppColors.brandPrimary;
    } else if (state is SyncError) {
      return Colors.red;
    } else if (state is SyncOffline) {
      return Colors.orange;
    } else if (state is SyncSuccess) {
      return Colors.green;
    } else if (state is SyncIdle && state.pendingOperations > 0) {
      return Colors.amber.shade800;
    } else {
      return Colors.grey.shade700;
    }
  }
  
  /// Vérifie si on peut forcer une synchronisation dans l'état actuel
  bool _canForceSynch(SyncState state) {
    if (state is SyncOffline) {
      return false;
    }
    return true;
  }
}

/// Widget plus petit pour afficher uniquement une icône de statut de synchronisation
class SyncStatusIconWidget extends StatelessWidget {
  final double size;
  
  const SyncStatusIconWidget({
    Key? key,
    this.size = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        if (state is SyncInProgress) {
          return SizedBox(
            width: size,
            height: size, 
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _getColor(state),
            ),
          );
        } else {
          return Icon(
            _getIcon(state),
            size: size,
            color: _getColor(state),
          );
        }
      },
    );
  }
  
  IconData _getIcon(SyncState state) {
    if (state is SyncError) {
      return Icons.error_outline;
    } else if (state is SyncOffline) {
      return Icons.wifi_off;
    } else if (state is SyncSuccess) {
      return Icons.check_circle;
    } else if (state is SyncIdle && state.pendingOperations > 0) {
      return Icons.schedule;
    } else if (state is SyncInitial || state is SyncIdle) {
      return Icons.sync;
    } else {
      return Icons.sync_problem;
    }
  }
  
  Color _getColor(SyncState state) {
    if (state is SyncInProgress) {
      return AppColors.brandPrimary;
    } else if (state is SyncError) {
      return Colors.red;
    } else if (state is SyncOffline) {
      return Colors.orange;
    } else if (state is SyncSuccess) {
      return Colors.green;
    } else if (state is SyncIdle && state.pendingOperations > 0) {
      return Colors.amber.shade800;
    } else {
      return Colors.grey.shade600;
    }
  }
} 