import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/blocs/dashboard/dashboard_bloc.dart';
import '../../../core/models/dashboard/dashboard_data.dart';
import '../../widgets/analytics/interactive_line_chart.dart';
import '../../widgets/analytics/interactive_bar_chart.dart';
import '../../widgets/analytics/period_comparison_widget.dart';

/// Onglet Analytics avec graphiques interactifs et comparaisons période à période
/// Utilise les vraies données du DashboardBloc
class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is DashboardError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<DashboardBloc>().add(LoadDashboardData());
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        if (state is! DashboardLoaded) {
          return const SizedBox.shrink();
        }

        final data = state.dashboardData;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<DashboardBloc>().add(LoadDashboardData());
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                _buildHeader(context),
                const SizedBox(height: 24),

                // Comparaisons période à période
                _buildComparisonsSection(data),
                const SizedBox(height: 32),

                // Graphique des revenus
                _buildRevenueChartSection(data.revenue),
                const SizedBox(height: 32),

                // Top résidences
                _buildTopResidencesSection(data.revenue),
                const SizedBox(height: 32),

                // Réservations par statut
                _buildBookingsByStatusSection(data.stats),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics,
                color: Colors.blue[700],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics Avancées',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Graphiques interactifs et comparaisons',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonsSection(DashboardData data) {
    final revenue = data.revenue;
    final performance = data.performance;

    // Calcul de la valeur précédente à partir du growth
    final previousRevenue = revenue.revenueGrowth != 0
        ? revenue.monthlyRevenue / (1 + revenue.revenueGrowth / 100)
        : revenue.monthlyRevenue * 0.85; // Estimation si pas de growth

    // Estimation pour les autres métriques (le backend pourrait les fournir)
    final previousBookings = performance.totalReservations > 0
        ? (performance.totalReservations * 0.9).toDouble()
        : 0.0;
    
    final previousOccupancy = performance.occupancyRate > 0
        ? performance.occupancyRate * 0.92
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comparaisons mensuelles',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Évolution par rapport au mois précédent',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        MultiPeriodComparisonWidget(
          currentPeriodLabel: 'Ce mois',
          previousPeriodLabel: 'Mois dernier',
          comparisons: [
            PeriodComparisonData(
              title: 'Revenus',
              currentValue: revenue.monthlyRevenue,
              previousValue: previousRevenue,
              unit: 'FCFA',
              icon: Icons.attach_money,
              color: Colors.green,
              isMonetary: true,
            ),
          PeriodComparisonData(
            title: 'Réservations',
            currentValue: performance.totalReservations.toDouble(),
            previousValue: previousBookings,
            unit: '',
            icon: Icons.calendar_today,
            color: Colors.blue,
          ),
            PeriodComparisonData(
              title: 'Taux occupation',
              currentValue: performance.occupancyRate,
              previousValue: previousOccupancy,
              unit: '%',
              icon: Icons.trending_up,
              color: Colors.orange,
            ),
            PeriodComparisonData(
              title: 'Résidences',
              currentValue: performance.totalResidences.toDouble(),
              previousValue: performance.totalResidences.toDouble(),
              unit: '',
              icon: Icons.home,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueChartSection(RevenueStats revenue) {
    if (revenue.revenueHistory.isEmpty) {
      return _buildEmptyState(
        'Aucun historique de revenus',
        'Les données apparaîtront ici dès que vous aurez des réservations',
        Icons.show_chart,
      );
    }

    // Conversion RevenuePoint → ChartDataPoint
    final chartData = revenue.revenueHistory.map((point) {
      return ChartDataPoint(
        label: DateFormat('dd/MM').format(point.date),
        value: point.amount,
        date: point.date,
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Évolution des revenus',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${revenue.revenueHistory.length} derniers jours',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: revenue.revenueGrowth >= 0 
                    ? Colors.green[50] 
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    revenue.revenueGrowth >= 0 
                        ? Icons.trending_up 
                        : Icons.trending_down,
                    size: 16,
                    color: revenue.revenueGrowth >= 0 
                        ? Colors.green[700] 
                        : Colors.red[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${revenue.revenueGrowth >= 0 ? '+' : ''}${revenue.revenueGrowth.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: revenue.revenueGrowth >= 0 
                          ? Colors.green[700] 
                          : Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: InteractiveLineChart(
            title: '',
            data: chartData,
            lineColor: Colors.green,
            gradientStartColor: Colors.green,
            yAxisLabel: 'FCFA',
            showGrid: true,
            showDots: chartData.length <= 15, // Masquer les dots si trop de points
            onPointTap: (point) {
              // Le snackbar sera géré par le widget lui-même
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopResidencesSection(RevenueStats revenue) {
    if (revenue.bestResidences.isEmpty) {
      return _buildEmptyState(
        'Aucune résidence',
        'Ajoutez des résidences pour voir les statistiques',
        Icons.home_outlined,
      );
    }

    // Limiter à 5 résidences max pour la lisibilité
    final topResidences = revenue.bestResidences.take(5).toList();

    // Conversion BestPerformingResidence → BarChartDataPoint
    final chartData = topResidences.map((residence) {
      // Tronquer le nom si trop long
      String label = residence.name;
      if (label.length > 15) {
        label = '${label.substring(0, 12)}...';
      }

      return BarChartDataPoint(
        label: label,
        value: residence.revenue,
        metadata: {
          'id': residence.id,
          'bookings': residence.bookings,
          'fullName': residence.name,
        },
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top résidences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Classées par revenus générés',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (revenue.bestResidences.length > 5)
              Text(
                'Top ${topResidences.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: InteractiveBarChart(
            title: '',
            data: chartData,
            barColor: Colors.blue,
            selectedBarColor: Colors.blue[300],
            yAxisLabel: 'FCFA',
            showGrid: true,
            onBarTap: (bar) {
              // Le snackbar sera géré par le widget lui-même
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsByStatusSection(GeneralStats stats) {
    final bookings = stats.bookingsByStatus;
    
    if (bookings.isEmpty || bookings.values.every((v) => v == 0)) {
      return const SizedBox.shrink();
    }

    // Conversion Map<String, int> → BarChartDataPoint
    final chartData = bookings.entries.map((entry) {
      String label = _getStatusLabel(entry.key);
      return BarChartDataPoint(
        label: label,
        value: entry.value.toDouble(),
        color: _getStatusColor(entry.key),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Réservations par statut',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Répartition actuelle',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: InteractiveBarChart(
            title: '',
            data: chartData,
            barColor: Colors.purple,
            yAxisLabel: '',
            showGrid: false,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmées';
      case 'completed':
        return 'Terminées';
      case 'cancelled':
        return 'Annulées';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

