import 'package:flutter/material.dart';

/// Type d'action pour personnaliser l'apparence du dialogue
enum ActionType {
  delete,
  cancel,
  approve,
  reject,
  warning,
  info,
}

/// Configuration pour les types d'actions prédéfinis
class ActionTypeConfig {
  final Color color;
  final IconData icon;
  final String defaultTitle;
  final String confirmLabel;
  final Color confirmButtonColor;

  const ActionTypeConfig({
    required this.color,
    required this.icon,
    required this.defaultTitle,
    required this.confirmLabel,
    required this.confirmButtonColor,
  });

  static ActionTypeConfig forType(ActionType type) {
    switch (type) {
      case ActionType.delete:
        return const ActionTypeConfig(
          color: Colors.red,
          icon: Icons.delete_outline,
          defaultTitle: 'Confirmer la suppression',
          confirmLabel: 'Supprimer',
          confirmButtonColor: Colors.red,
        );
      case ActionType.cancel:
        return const ActionTypeConfig(
          color: Colors.orange,
          icon: Icons.cancel_outlined,
          defaultTitle: 'Confirmer l\'annulation',
          confirmLabel: 'Annuler',
          confirmButtonColor: Colors.orange,
        );
      case ActionType.approve:
        return const ActionTypeConfig(
          color: Colors.green,
          icon: Icons.check_circle_outline,
          defaultTitle: 'Confirmer l\'approbation',
          confirmLabel: 'Approuver',
          confirmButtonColor: Colors.green,
        );
      case ActionType.reject:
        return const ActionTypeConfig(
          color: Colors.red,
          icon: Icons.block,
          defaultTitle: 'Confirmer le rejet',
          confirmLabel: 'Rejeter',
          confirmButtonColor: Colors.red,
        );
      case ActionType.warning:
        return const ActionTypeConfig(
          color: Colors.amber,
          icon: Icons.warning_amber_rounded,
          defaultTitle: 'Attention',
          confirmLabel: 'Continuer',
          confirmButtonColor: Colors.amber,
        );
      case ActionType.info:
        return const ActionTypeConfig(
          color: Colors.blue,
          icon: Icons.info_outline,
          defaultTitle: 'Information',
          confirmLabel: 'OK',
          confirmButtonColor: Colors.blue,
        );
    }
  }
}

/// Dialogue de confirmation pour les actions critiques
class ActionConfirmationDialog extends StatelessWidget {
  final ActionType actionType;
  final String? title;
  final String message;
  final String? warningMessage;
  final String? confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final bool requiresDoubleConfirmation;

  const ActionConfirmationDialog({
    super.key,
    required this.actionType,
    this.title,
    required this.message,
    this.warningMessage,
    this.confirmLabel,
    this.cancelLabel = 'Annuler',
    required this.onConfirm,
    this.requiresDoubleConfirmation = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = ActionTypeConfig.forType(actionType);
    final effectiveTitle = title ?? config.defaultTitle;
    final effectiveConfirmLabel = confirmLabel ?? config.confirmLabel;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              config.icon,
              color: config.color,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              effectiveTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(fontSize: 15),
          ),
          if (warningMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warningMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        FilledButton(
          onPressed: () {
            if (requiresDoubleConfirmation) {
              _showSecondConfirmation(context, config, effectiveConfirmLabel);
            } else {
              Navigator.of(context).pop(true);
              onConfirm();
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: config.confirmButtonColor,
            foregroundColor: Colors.white,
          ),
          child: Text(
            effectiveConfirmLabel,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  /// Affiche une seconde confirmation pour les actions vraiment critiques
  void _showSecondConfirmation(
    BuildContext context,
    ActionTypeConfig config,
    String confirmLabel,
  ) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Êtes-vous vraiment sûr ?',
          style: TextStyle(
            color: config.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Cette action est irréversible et ne peut pas être annulée.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Non, retour'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Ferme la 2ème dialog
              Navigator.of(context).pop(true); // Ferme la 1ère dialog
              onConfirm();
            },
            style: FilledButton.styleFrom(
              backgroundColor: config.color,
            ),
            child: Text('Oui, $confirmLabel'),
          ),
        ],
      ),
    );
  }

  /// Méthode statique pour afficher facilement le dialogue
  static Future<void> show({
    required BuildContext context,
    required ActionType actionType,
    String? title,
    required String message,
    String? warningMessage,
    String? confirmLabel,
    String cancelLabel = 'Annuler',
    required VoidCallback onConfirm,
    bool requiresDoubleConfirmation = false,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ActionConfirmationDialog(
          actionType: actionType,
          title: title,
          message: message,
          warningMessage: warningMessage,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          onConfirm: onConfirm,
          requiresDoubleConfirmation: requiresDoubleConfirmation,
        );
      },
    );
  }
}

