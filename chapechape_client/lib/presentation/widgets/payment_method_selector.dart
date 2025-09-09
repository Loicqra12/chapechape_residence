import 'package:flutter/material.dart';

/// Widget pour sélectionner une méthode de paiement
class PaymentMethodSelector extends StatelessWidget {
  final String? selectedMethod;
  final Function(String) onMethodSelected;
  final bool showTitle;

  const PaymentMethodSelector({
    Key? key,
    this.selectedMethod,
    required this.onMethodSelected,
    this.showTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Row(
            children: [
              Icon(Icons.payment, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Choisir la méthode de paiement',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Sélectionnez votre méthode de paiement préférée pour recevoir les instructions détaillées :',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Mobile Money (populaire en Afrique de l'Ouest)
        _buildMethodCard(
          context,
          method: 'wave',
          title: 'Wave',
          subtitle: 'Paiement mobile Wave',
          icon: Icons.waves,
          color: Colors.blue,
          popular: true,
        ),
        const SizedBox(height: 8),
        _buildMethodCard(
          context,
          method: 'om',
          title: 'Orange Money',
          subtitle: 'Composez #144*1*1#',
          icon: Icons.phone_android,
          color: Colors.orange,
          popular: true,
        ),
        const SizedBox(height: 8),
        _buildMethodCard(
          context,
          method: 'mtn_money',
          title: 'MTN Money',
          subtitle: 'Composez *133#',
          icon: Icons.smartphone,
          color: Colors.yellow.shade700,
        ),
        const SizedBox(height: 8),
        _buildMethodCard(
          context,
          method: 'momo',
          title: 'Moov Money',
          subtitle: 'Composez *155#',
          icon: Icons.mobile_friendly,
          color: Colors.green,
        ),
        const SizedBox(height: 12),
        
        // Divider
        Divider(color: theme.dividerColor),
        const SizedBox(height: 12),
        
        // Méthodes traditionnelles
        _buildMethodCard(
          context,
          method: 'credit_card',
          title: 'Carte bancaire',
          subtitle: 'Visa, Mastercard',
          icon: Icons.credit_card,
          color: Colors.indigo,
        ),
        const SizedBox(height: 8),
        _buildMethodCard(
          context,
          method: 'cash',
          title: 'Espèces',
          subtitle: 'Paiement à l\'arrivée',
          icon: Icons.money,
          color: Colors.green.shade600,
        ),
      ],
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String method,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool popular = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedMethod == method;
    
    // Mapping des images selon le style partner premium
    String? imagePath = _getPaymentMethodImage(method);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? theme.primaryColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 4),
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: Card(
        elevation: 0, // Supprime l'ombre par défaut
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected 
                ? theme.primaryColor 
                : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => onMethodSelected(method),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Image du provider avec style premium
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: imagePath != null
                      ? Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              icon,
                              color: color,
                              size: 28,
                            );
                          },
                        )
                      : Icon(
                          icon,
                          color: color,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isSelected 
                                  ? theme.primaryColor 
                                  : theme.textTheme.titleMedium?.color,
                            ),
                          ),
                          if (popular) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.orange, Colors.deepOrange],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Populaire',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicateur de sélection premium
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.primaryColor 
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? theme.primaryColor 
                          : Colors.grey.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Retourne le chemin de l'image pour chaque méthode de paiement
  String? _getPaymentMethodImage(String method) {
    switch (method) {
      case 'wave':
        return 'assets/images/wave.png';
      case 'om':
        return 'assets/images/orange_money.png';
      case 'mtn_money':
        return 'assets/images/mtn_money.png';
      case 'momo':
        return 'assets/images/moov_money.png';
      case 'credit_card':
        return 'assets/images/visa.png'; // Ou mastercard selon préférence
      case 'cash':
        return null; // Utilise l'icône par défaut
      default:
        return null;
    }
  }
}

/// Widget compact pour afficher la méthode sélectionnée
class SelectedPaymentMethodChip extends StatelessWidget {
  final String paymentMethod;
  final VoidCallback? onTap;

  const SelectedPaymentMethodChip({
    Key? key,
    required this.paymentMethod,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final methodInfo = _getMethodInfo(paymentMethod);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              methodInfo['icon'] as IconData,
              size: 18,
              color: theme.primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              methodInfo['title'] as String,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.edit,
                size: 14,
                color: theme.primaryColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getMethodInfo(String method) {
    switch (method) {
      case 'wave':
        return {'title': 'Wave', 'icon': Icons.waves};
      case 'om':
        return {'title': 'Orange Money', 'icon': Icons.phone_android};
      case 'mtn_money':
        return {'title': 'MTN Money', 'icon': Icons.smartphone};
      case 'momo':
        return {'title': 'Moov Money', 'icon': Icons.mobile_friendly};
      case 'credit_card':
        return {'title': 'Carte bancaire', 'icon': Icons.credit_card};
      case 'cash':
        return {'title': 'Espèces', 'icon': Icons.money};
      default:
        return {'title': 'Autre', 'icon': Icons.payment};
    }
  }
}
