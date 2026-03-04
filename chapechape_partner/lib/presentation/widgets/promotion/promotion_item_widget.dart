import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/promotion/promotion_model.dart';

/// Widget pour afficher une promotion individuelle dans une liste
class PromotionItemWidget extends StatelessWidget {
  final PromotionModel promotion;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final bool showControls;
  
  const PromotionItemWidget({
    Key? key,
    required this.promotion,
    this.onEdit,
    this.onDelete,
    this.onTap,
    this.showControls = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Définir la couleur en fonction du type de promotion
    Color tagColor;
    switch (promotion.type) {
      case PromotionType.discount:
        tagColor = Colors.green;
        break;
      case PromotionType.flash:
        tagColor = Colors.orange;
        break;
      case PromotionType.seasonal:
        tagColor = Theme.of(context).colorScheme.primary;
        break;
      case PromotionType.bundle:
        tagColor = Colors.purple;
        break;
      case PromotionType.exclusive:
        tagColor = Colors.red;
        break;
      case PromotionType.newUser:
        tagColor = Colors.teal;
        break;
    }
    
    // Vérifier si la promotion est expirée
    final isExpired = DateTime.now().isAfter(promotion.endDate);
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Badge de type de promotion
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tagColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: tagColor),
                    ),
                    child: Text(
                      _getPromotionTypeLabel(promotion.type),
                      style: TextStyle(
                        color: tagColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge exclusif si applicable
                  if (promotion.isExclusive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Text(
                        'EXCLUSIF',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Badge actif/inactif
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (promotion.isActive && !isExpired) 
                          ? Colors.green.withOpacity(0.2) 
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: (promotion.isActive && !isExpired) 
                            ? Colors.green 
                            : Colors.red,
                      ),
                    ),
                    child: Text(
                      (promotion.isActive && !isExpired) ? 'ACTIF' : 'INACTIF',
                      style: TextStyle(
                        color: (promotion.isActive && !isExpired) 
                            ? Colors.green 
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Titre de la promotion
              Text(
                promotion.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Description de la promotion
              Text(
                promotion.description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Informations de réduction
              Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  if (promotion.discountPercentage > 0)
                    Text(
                      'Réduction: ${promotion.discountPercentage.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  else if (promotion.discountAmount != null && promotion.discountAmount! > 0)
                    Text(
                      'Réduction: ${promotion.discountAmount!.toStringAsFixed(0)} CFA',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Dates de validité
              Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 20,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Valide du ${dateFormat.format(promotion.startDate)} au ${dateFormat.format(promotion.endDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              // Boutons d'action
              if (showControls)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        TextButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('Modifier'),
                          onPressed: onEdit,
                        ),
                      if (onDelete != null)
                        TextButton.icon(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Supprimer', 
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Obtenir le libellé du type de promotion
  String _getPromotionTypeLabel(PromotionType type) {
    switch (type) {
      case PromotionType.discount:
        return 'RÉDUCTION';
      case PromotionType.flash:
        return 'FLASH';
      case PromotionType.seasonal:
        return 'SAISONNIÈRE';
      case PromotionType.bundle:
        return 'BUNDLE';
      case PromotionType.exclusive:
        return 'EXCLUSIVE';
      case PromotionType.newUser:
        return 'NOUVEAUX CLIENTS';
    }
  }
}
