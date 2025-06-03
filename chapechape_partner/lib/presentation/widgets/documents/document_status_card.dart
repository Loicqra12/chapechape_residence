import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/partner/partner_model.dart';

/// Widget pour afficher le statut d'un document de partenaire
class DocumentStatusCard extends StatelessWidget {
  final PartnerDocument document;
  final VoidCallback? onReupload;
  
  const DocumentStatusCard({
    super.key,
    required this.document,
    this.onReupload,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    // Déterminer le style en fonction du statut
    switch (document.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_top;
        statusText = 'En attente de vérification';
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Vérifié et approuvé';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Document rejeté';
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.file_present;
        statusText = 'Document téléchargé';
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entête avec icône et type
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDocumentTypeIcon(document.type),
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDocumentTypeName(document.type),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statusText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  statusIcon,
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Informations sur le document
            _InfoRow(
              icon: Icons.calendar_today,
              label: 'Date de soumission',
              value: dateFormat.format(document.uploadDate),
            ),
            
            if (document.validUntil != null)
              _InfoRow(
                icon: Icons.event_available,
                label: 'Valide jusqu\'au',
                value: dateFormat.format(document.validUntil as DateTime),
              ),
            
            if (document.comment != null && document.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.comment,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Commentaire',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                      ),
                      child: Text(
                        document.comment!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Bouton de nouvelle soumission si rejeté
            if (document.status == 'rejected' && onReupload != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onReupload,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Soumettre à nouveau'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Obtenir l'icône appropriée pour le type de document
  IconData _getDocumentTypeIcon(String type) {
    switch (type) {
      case 'identity':
        return Icons.badge;
      case 'address':
        return Icons.home;
      case 'professional':
        return Icons.business;
      default:
        return Icons.description;
    }
  }
  
  // Obtenir le nom lisible pour le type de document
  String _getDocumentTypeName(String type) {
    switch (type) {
      case 'identity':
        return 'Carte d\'identité';
      case 'address':
        return 'Justificatif de domicile';
      case 'professional':
        return 'Document professionnel';
      default:
        return 'Document ${type.capitalize()}';
    }
  }
}

// Extension pour capitaliser la première lettre
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// Widget pour les lignes d'information
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
