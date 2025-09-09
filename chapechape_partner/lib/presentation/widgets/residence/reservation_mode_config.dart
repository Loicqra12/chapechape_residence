import 'package:flutter/material.dart';

/// Widget de configuration du mode de réservation pour les partenaires
/// Permet de définir si une résidence utilise le mode instantané ou avec approbation
class ReservationModeConfig extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;
  final bool enabled;
  final String? title;

  const ReservationModeConfig({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
    this.enabled = true,
    this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Icon(
                  Icons.settings_applications,
                  color: theme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  title ?? 'Mode de Réservation',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Choisissez comment les clients peuvent réserver cette résidence',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 20),

            // Options de mode
            _buildModeOption(
              context: context,
              mode: 'instant',
              icon: Icons.flash_on,
              title: 'Réservation Instantanée',
              subtitle: 'Confirmée automatiquement après paiement',
              details: 'Les clients peuvent réserver immédiatement. Idéal pour maximiser les réservations.',
              benefits: [
                'Confirmation immédiate',
                'Plus de réservations',
                'Expérience client fluide',
                'Disponible 24h/24',
              ],
            ),

            const SizedBox(height: 16),

            _buildModeOption(
              context: context,
              mode: 'approval_required',
              icon: Icons.schedule,
              title: 'Réservation avec Approbation',
              subtitle: 'Vous validez chaque demande avant confirmation',
              details: 'Vous examinez chaque demande et choisissez vos clients. Contrôle total sur vos réservations.',
              benefits: [
                'Sélection des clients',
                'Communication préalable',
                'Contrôle qualité',
                'Flexibilité totale',
              ],
            ),

            if (!enabled) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sauvegardez d\'abord votre résidence pour modifier le mode de réservation',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeOption({
    required BuildContext context,
    required String mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required String details,
    required List<String> benefits,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isSelected = currentMode == mode;
    
    final primaryColor = isSelected 
        ? theme.primaryColor 
        : (isDarkMode ? Colors.grey[600] : Colors.grey[400]);
    
    final backgroundColor = isSelected 
        ? (isDarkMode ? theme.primaryColor.withOpacity(0.1) : theme.primaryColor.withOpacity(0.05))
        : (isDarkMode ? Colors.grey[800] : Colors.grey[50]);

    return GestureDetector(
      onTap: enabled ? () => onModeChanged(mode) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'SÉLECTIONNÉ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: primaryColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Radio<String>(
                    value: mode,
                    groupValue: currentMode,
                    onChanged: (value) {
                      if (value != null) onModeChanged(value);
                    },
                    activeColor: theme.primaryColor,
                  ),
              ],
            ),

            // Détails et avantages
            if (isSelected) ...[
              const SizedBox(height: 12),
              Text(
                details,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Avantages :',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ...benefits.map((benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget compact pour l'affichage du mode dans les listes
class ReservationModeIndicator extends StatelessWidget {
  final String mode;
  final bool showLabel;

  const ReservationModeIndicator({
    Key? key,
    required this.mode,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isInstant = mode.toLowerCase() == 'instant';
    final color = isInstant ? Colors.green : Colors.orange;
    final icon = isInstant ? Icons.flash_on : Icons.schedule;
    final label = isInstant ? 'Instantané' : 'Approbation';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color[600],
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color[600],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
