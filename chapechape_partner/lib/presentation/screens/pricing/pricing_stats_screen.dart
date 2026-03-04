import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/pricing/pricing_bloc.dart';
import '../../widgets/pricing/pricing_stats_card.dart';
import '../../widgets/pricing/method_breakdown_chart.dart';
import '../../widgets/pricing/savings_overview_widget.dart';

/// Écran des statistiques de pricing pour les partners
class PricingStatsScreen extends StatefulWidget {
  const PricingStatsScreen({super.key});

  @override
  State<PricingStatsScreen> createState() => _PricingStatsScreenState();
}

class _PricingStatsScreenState extends State<PricingStatsScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les stats au démarrage
    context.read<PricingBloc>().add(LoadPricingStatsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Pricing'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            style: IconButton.styleFrom(
              shape: const CircleBorder(),
              side: const BorderSide(color: Colors.white54),
              backgroundColor: Colors.transparent,
            ),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PricingBloc>().add(LoadPricingStatsEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<PricingBloc, PricingState>(
        builder: (context, state) {
          if (state is PricingStatsLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is PricingStatsError) {
            return _buildErrorState(state.message);
          }

          if (state is PricingStatsLoaded) {
            return _buildStatsContent(state);
          }

          return _buildEmptyState();
        },
      ),
    );
  }

  Widget _buildStatsContent(PricingStatsLoaded state) {
    final stats = state.stats;
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PricingBloc>().add(LoadPricingStatsEvent());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vue d'ensemble des économies
            SavingsOverviewWidget(stats: stats),
            
            const SizedBox(height: 20),
            
            // Statistiques principales
            Row(
              children: [
                Expanded(
                  child: PricingStatsCard(
                    title: 'Réservations',
                    value: stats.totalReservations.toString(),
                    subtitle: 'Total',
                    icon: Icons.home_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PricingStatsCard(
                    title: 'Revenus',
                    value: '${NumberFormat('#,###').format(stats.totalRevenue)} XOF',
                    subtitle: 'Total généré',
                    icon: Icons.monetization_on_outlined,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: PricingStatsCard(
                    title: 'Économies',
                    value: '${NumberFormat('#,###').format(stats.totalSavings)} XOF',
                    subtitle: 'Générées pour clients',
                    icon: Icons.savings_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PricingStatsCard(
                    title: 'Optimisation',
                    value: '${stats.optimizationRate}%',
                    subtitle: 'Taux d\'optimisation',
                    icon: Icons.trending_up_outlined,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Graphique de répartition par méthode
            _buildMethodBreakdownSection(stats),
            
            const SizedBox(height: 24),
            
            // Métriques détaillées
            _buildDetailedMetrics(stats),
            
            const SizedBox(height: 24),
            
            // Recommandations
            _buildRecommendations(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodBreakdownSection(stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Répartition par méthode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MethodBreakdownChart(methodStats: stats.methodStats),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedMetrics(stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Métriques détaillées',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Revenu moyen par réservation',
              '${NumberFormat('#,###').format(stats.avgRevenuePerReservation)} XOF',
              Icons.attach_money,
            ),
            _buildMetricRow(
              'Économie moyenne par client',
              stats.totalReservations > 0 
                  ? '${NumberFormat('#,###').format(stats.totalSavings / stats.totalReservations)} XOF'
                  : '0 XOF',
              Icons.savings,
            ),
            _buildMetricRow(
              'Impact pricing positif',
              '${stats.optimizationRate}% des réservations',
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(stats) {
    final recommendations = _generateRecommendations(stats);
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'Recommandations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.map((rec) => _buildRecommendationItem(rec)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.arrow_right,
            color: Colors.amber,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _generateRecommendations(stats) {
    final recommendations = <String>[];
    
    if (stats.optimizationRate < 50) {
      recommendations.add(
        'Encouragez vos clients à utiliser MTN Money ou Wave pour optimiser les coûts'
      );
    }
    
    if (stats.totalReservations > 0) {
      final mostUsedMethod = stats.methodStats.entries
          .reduce((a, b) => a.value.count > b.value.count ? a : b);
      
      if (mostUsedMethod.key == 'card' || mostUsedMethod.key == 'orange_money') {
        recommendations.add(
          'Informez vos clients des économies possibles avec d\'autres méthodes de paiement'
        );
      }
    }
    
    if (stats.totalSavings > 10000) {
      recommendations.add(
        'Excellent ! Vos clients économisent grâce au pricing optimisé'
      );
    }
    
    return recommendations;
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PricingBloc>().add(LoadPricingStatsEvent());
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Statistiques pricing',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tirez sur l\'écran pour actualiser',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
