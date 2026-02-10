import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget réutilisable pour la section des tarifs horaires dégressifs (4 paliers)
/// 
/// Permet de définir jusqu'à 4 tarifs horaires différents :
/// - 1 heure (obligatoire si pricePeriod == 'hour')
/// - 2 heures (optionnel, recommandé dégressif)
/// - 3 heures (optionnel, recommandé dégressif)
/// - Heure supplémentaire (optionnel)
class HourlyPricingCard extends StatelessWidget {
  final TextEditingController oneHourController;
  final TextEditingController twoHoursController;
  final TextEditingController threeHoursController;
  final TextEditingController additionalHourController;
  final String selectedPricePeriod;
  
  const HourlyPricingCard({
    Key? key,
    required this.oneHourController,
    required this.twoHoursController,
    required this.threeHoursController,
    required this.additionalHourController,
    required this.selectedPricePeriod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.3),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarifs horaires (dégressifs)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 4),
            Text(
              'Définissez jusqu\'à 4 paliers de tarification pour encourager les réservations longues',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 16),
            
            // Palier 1: 1 heure
            _buildHourlyRateField(
              context: context,
              label: '1 heure (FCFA)',
              controller: oneHourController,
              hint: 'ex: 5000',
              icon: Icons.looks_one,
              filled: selectedPricePeriod == 'hour',
              isRequired: selectedPricePeriod == 'hour',
            ),
            SizedBox(height: 12),
            
            // Palier 2: 2 heures
            _buildHourlyRateField(
              context: context,
              label: '2 heures (FCFA) - Optionnel',
              controller: twoHoursController,
              hint: 'ex: 8000 (au lieu de 10000)',
              helperText: 'Tarif dégressif recommandé',
              icon: Icons.looks_two,
              filled: selectedPricePeriod == 'hour',
            ),
            SizedBox(height: 12),
            
            // Palier 3: 3 heures
            _buildHourlyRateField(
              context: context,
              label: '3 heures (FCFA) - Optionnel',
              controller: threeHoursController,
              hint: 'ex: 12000 (au lieu de 15000)',
              helperText: 'Économie de 20% recommandée',
              icon: Icons.looks_3,
              filled: selectedPricePeriod == 'hour',
            ),
            SizedBox(height: 12),
            
            // Palier 4: Heure supplémentaire
            _buildHourlyRateField(
              context: context,
              label: 'Heure supplémentaire (FCFA) - Optionnel',
              controller: additionalHourController,
              hint: 'ex: 4000',
              helperText: 'Prix pour chaque heure au-delà de 3h',
              icon: Icons.add_circle_outline,
              filled: selectedPricePeriod == 'hour',
            ),
            SizedBox(height: 16),
            
            // Divider visuel
            Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyRateField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? helperText,
    bool filled = false,
    bool isRequired = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon),
        filled: filled,
        fillColor: filled
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2)
            : null,
        border: OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Le tarif pour 1h est requis';
              }
              return null;
            }
          : null,
    );
  }
}
