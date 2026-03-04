import 'package:flutter/material.dart';
import 'dart:convert';

/// Dialogue pour résoudre les conflits lors de la synchronisation
/// Affiche les deux versions (locale vs serveur) et laisse l'utilisateur choisir
class ConflictResolutionDialog extends StatefulWidget {
  final String operationType;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;

  const ConflictResolutionDialog({
    super.key,
    required this.operationType,
    required this.localData,
    required this.serverData,
  });

  @override
  State<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  String? _selectedVersion;

  String _getOperationTypeLabel() {
    switch (widget.operationType) {
      case 'create_residence':
      case 'update_residence':
        return 'Résidence';
      case 'update_reservation':
        return 'Réservation';
      case 'send_message':
        return 'Message';
      case 'update_profile':
        return 'Profil';
      default:
        return 'Donnée';
    }
  }

  List<MapEntry<String, dynamic>> _getConflictingFields() {
    final conflicts = <MapEntry<String, dynamic>>[];
    
    // Comparer les champs qui diffèrent
    for (final key in widget.localData.keys) {
      if (widget.serverData.containsKey(key)) {
        if (widget.localData[key] != widget.serverData[key]) {
          conflicts.add(MapEntry(key, {
            'local': widget.localData[key],
            'server': widget.serverData[key],
          }));
        }
      }
    }
    
    return conflicts;
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'Non défini';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value ? 'Oui' : 'Non';
    if (value is List) return '${value.length} élément${value.length > 1 ? 's' : ''}';
    if (value is Map) return 'Objet (${value.length} champs)';
    return value.toString();
  }

  String _formatFieldName(String key) {
    final formatted = key
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'([A-Z])'), ' \$1')
        .trim();
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = _getConflictingFields();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conflit détecté',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getOperationTypeLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette donnée a été modifiée à la fois localement et sur le serveur. '
              'Choisissez quelle version conserver :',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Résumé des conflits
            if (conflicts.isNotEmpty) ...[
              Text(
                '${conflicts.length} champ${conflicts.length > 1 ? 's' : ''} en conflit :',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              
              ...conflicts.map((conflict) => _buildConflictItem(
                _formatFieldName(conflict.key),
                conflict.value['local'],
                conflict.value['server'],
              )),
            ],

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),

            // Options de résolution
            _buildResolutionOption(
              value: 'local',
              title: 'Conserver ma version (locale)',
              subtitle: 'Écraser les modifications du serveur',
              icon: Icons.phone_android,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _buildResolutionOption(
              value: 'server',
              title: 'Conserver la version serveur',
              subtitle: 'Abandonner mes modifications locales',
              icon: Icons.cloud,
              color: Colors.green,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _selectedVersion == null
              ? null
              : () => Navigator.of(context).pop(_selectedVersion),
          child: const Text('Appliquer'),
        ),
      ],
    );
  }

  Widget _buildConflictItem(String fieldName, dynamic localValue, dynamic serverValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone_android, size: 14, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        const Text(
                          'Local:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatValue(localValue),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.cloud, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        const Text(
                          'Serveur:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatValue(serverValue),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedVersion == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedVersion = value;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedVersion,
              onChanged: (val) {
                setState(() {
                  _selectedVersion = val;
                });
              },
              activeColor: color,
            ),
            const SizedBox(width: 8),
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


