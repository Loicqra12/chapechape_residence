import 'package:flutter/material.dart';

/// Widget de bannière informative affichant le mode de réservation défini par le partenaire
/// Ce widget NE PERMET PAS de sélectionner le mode (réservé aux partenaires)
/// Il affiche seulement une information visuelle pour l'utilisateur
class ReservationModeBanner extends StatelessWidget {
  final String reservationMode; // 'instant' ou 'approval_required'
  final VoidCallback? onInfoTap;

  const ReservationModeBanner({
    Key? key,
    required this.reservationMode,
    this.onInfoTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Configuration selon le mode
    final isInstant = reservationMode.toLowerCase() == 'instant';
    
    final bannerColor = isInstant 
        ? (isDarkMode ? Colors.green.shade800 : Colors.green.shade50)
        : (isDarkMode ? Colors.orange.shade800 : Colors.orange.shade50);
    
    final iconColor = isInstant 
        ? Colors.green.shade600 
        : Colors.orange.shade600;
    
    final textColor = isInstant 
        ? (isDarkMode ? Colors.green.shade100 : Colors.green.shade800)
        : (isDarkMode ? Colors.orange.shade100 : Colors.orange.shade800);

    final icon = isInstant ? Icons.flash_on : Icons.schedule;
    
    final title = isInstant 
        ? 'Réservation Instantanée'
        : 'Réservation avec Approbation';
    
    final description = isInstant
        ? 'Votre réservation sera confirmée immédiatement après le paiement'
        : 'Votre réservation nécessite l\'approbation du partenaire avant confirmation';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onInfoTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Icône du mode
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Contenu textuel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textColor.withOpacity(0.8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Icône d'information (optionnelle)
            if (onInfoTap != null)
              Icon(
                Icons.info_outline,
                color: iconColor.withOpacity(0.7),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget d'information détaillée sur les modes de réservation
class ReservationModeInfoDialog extends StatelessWidget {
  const ReservationModeInfoDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Modes de Réservation'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Instantané
            _ModeInfoTile(
              icon: Icons.flash_on,
              iconColor: Colors.green,
              title: 'Réservation Instantanée',
              description: 'Votre réservation est confirmée automatiquement après le paiement. Idéal pour les réservations urgentes.',
              advantages: [
                'Confirmation immédiate',
                'Pas d\'attente',
                'Paiement direct',
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Mode Approbation
            _ModeInfoTile(
              icon: Icons.schedule,
              iconColor: Colors.orange,
              title: 'Réservation avec Approbation',
              description: 'Le partenaire examine votre demande avant de la confirmer. Permet une sélection plus attentive des clients.',
              advantages: [
                'Vérification par le partenaire',
                'Communication préalable',
                'Qualité assurée',
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Compris'),
        ),
      ],
    );
  }
}

class _ModeInfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final List<String> advantages;

  const _ModeInfoTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.advantages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        ...advantages.map((advantage) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 16,
                color: iconColor.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                advantage,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }
}
