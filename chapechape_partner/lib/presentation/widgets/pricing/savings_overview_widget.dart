import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/pricing/pricing_model.dart';

/// Widget d'aperçu des économies réalisées
class SavingsOverviewWidget extends StatelessWidget {
  final PricingStats stats;

  const SavingsOverviewWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.totalReservations == 0) {
      return _buildEmptyState();
    }

    final avgSavingsPerReservation = stats.totalSavings / stats.totalReservations;
    final optimizationImpact = _calculateOptimizationImpact();

    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.1),
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.savings,
                    color: Colors.green,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Impact Pricing Dynamique',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Économies générées pour vos clients',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Statistiques principales
            Row(
              children: [
                Expanded(
                  child: _buildMainStat(
                    label: 'Économies totales',
                    value: '${NumberFormat('#,###').format(stats.totalSavings)} XOF',
                    icon: Icons.trending_down,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMainStat(
                    label: 'Moyenne par client',
                    value: '${NumberFormat('#,###').format(avgSavingsPerReservation)} XOF',
                    icon: Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Barre de progression d'optimisation
            _buildOptimizationProgress(context),
            
            const SizedBox(height: 16),
            
            // Impact détaillé
            _buildImpactDetails(context, optimizationImpact),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Taux d\'optimisation',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${stats.optimizationRate}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: stats.optimizationRate / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(
            stats.optimizationRate >= 70 
                ? Colors.green 
                : stats.optimizationRate >= 40 
                    ? Colors.orange 
                    : Colors.red
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          '${stats.optimizationRate >= 70 ? 'Excellent' : stats.optimizationRate >= 40 ? 'Bon' : 'À améliorer'} - ${stats.optimizationRate}% de vos réservations utilisent des méthodes optimisées',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildImpactDetails(BuildContext context, Map<String, dynamic> impact) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impact détaillé',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildImpactItem(
                  icon: Icons.savings_outlined,
                  label: 'Clients satisfaits',
                  value: '${impact['satisfiedClients']}%',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildImpactItem(
                  icon: Icons.monetization_on_outlined,
                  label: 'ROI ChapeChape',
                  value: '+${impact['chapeChapeROI']}%',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.savings_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Pricing dynamique',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Commencez à recevoir des réservations pour voir l\'impact du pricing optimisé',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculateOptimizationImpact() {
    // Calculer l'impact basé sur les statistiques
    final satisfiedClients = stats.optimizationRate >= 50 ? 85 + (stats.optimizationRate - 50) * 0.3 : 60 + stats.optimizationRate * 0.5;
    final chapeChapeROI = stats.optimizationRate >= 70 ? 12 + (stats.optimizationRate - 70) * 0.1 : 5 + stats.optimizationRate * 0.1;
    
    return {
      'satisfiedClients': satisfiedClients.round(),
      'chapeChapeROI': chapeChapeROI.round(),
    };
  }
}
