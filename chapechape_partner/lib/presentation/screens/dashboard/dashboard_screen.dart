import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/blocs/dashboard/dashboard_bloc.dart';
import '../../../core/models/dashboard/dashboard_data.dart';
import '../../../core/models/payment/payout_model.dart';
import '../../../core/services/api/payment_service.dart';
import '../../../core/services/api/residence_service.dart';
import '../../../core/config/app_config_manager.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../widgets/layout/screen_app_bars.dart';
import '../pricing/pricing_stats_screen.dart';
import '../../widgets/skeletons/skeletons.dart';
import 'analytics_tab.dart'; // Import du nouvel onglet Analytics
import '../main/main_screen.dart'; // Pour MainScreenNavigator
import '../residences/edit_residence_screen.dart';
import '../residences/residence_details_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7F9FC),
          body: CustomScrollView(
            slivers: [
              ScreenAppBars.getDashboardAppBar(context),
              SliverToBoxAdapter(
                child: _buildContent(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, DashboardState state) {
    if (state is DashboardLoading) {
      return const DashboardSkeleton();
    }

    if (state is DashboardError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                context.read<DashboardBloc>().add(LoadDashboardData());
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state is DashboardLoaded) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélecteur de période (toujours visible)
            _buildPeriodSelector(context, state),
            const SizedBox(height: 24),
            
            // Bouton Analytics Avancées (NOUVEAU)
            _buildAnalyticsButton(context),
            const SizedBox(height: 24),
            
            // Section Performance
            // Section Performance
            _buildPerformanceSection(context, state.dashboardData.performance),
            const SizedBox(height: 24),

            // Section À faire (Action Section - Style Yango)
            _buildActionSection(context),
            const SizedBox(height: 24),
            
            // 🚫 TEMPORAIREMENT MASQUÉ POUR GOOGLE PLAY SUBMISSION
            // Section Revenus
            // _buildRevenueSection(context, state.dashboardData.revenue, state.period),
            // const SizedBox(height: 24),
            
            // 🚫 TEMPORAIREMENT MASQUÉ POUR GOOGLE PLAY SUBMISSION
            // Section Financière Payouts
            // _buildPayoutFinancialSection(context),
            // const SizedBox(height: 24),
            
            // Section Tendances
            _buildTrendsSection(context, state.trendData, state.period),
            const SizedBox(height: 24),
            
            // Ajouter la section Réservations à venir
            _buildUpcomingReservationsSection(context),
            const SizedBox(height: 24),
            
            // Ajouter la section Localisation
            _buildLocationAnalyticsSection(context),
            const SizedBox(height: 24),
            
            // 🚫 TEMPORAIREMENT MASQUÉ POUR GOOGLE PLAY SUBMISSION
            // Section Pricing Dynamique
            // _buildPricingSection(context),
            // const SizedBox(height: 24),
            
            // Ajouter la section Performances par résidence
            if (state.residenceStats.isNotEmpty)
              _buildResidencePerformanceSection(context, state.residenceStats),
            
            // Ajouter la section Avis Clients
            const SizedBox(height: 24),
            _buildReviewsSection(context, state.dashboardData.stats.rating),
            
            // Pied de page avec la date de mise à jour
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Dernière mise à jour: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  static String _periodLabel(String period) {
    switch (period) {
      case 'daily': return 'Journalier';
      case 'weekly': return 'Hebdomadaire';
      case 'monthly': return 'Mensuel';
      case 'yearly': return 'Annuel';
      default: return 'Mensuel';
    }
  }

  Widget _buildPeriodSelector(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => _showPeriodBottomSheet(context, state),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.date_range, size: 22, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Période',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _periodLabel(state.period),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showPeriodBottomSheet(BuildContext context, DashboardLoaded state) {
    final theme = Theme.of(context);
    final options = [
      ('daily', 'Journalier', Icons.today_rounded),
      ('weekly', 'Hebdomadaire', Icons.date_range_rounded),
      ('monthly', 'Mensuel', Icons.calendar_month_rounded),
      ('yearly', 'Annuel', Icons.calendar_today_rounded),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisir la période',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((e) {
                final value = e.$1;
                final label = e.$2;
                final icon = e.$3;
                final isSelected = state.period == value;
                return ListTile(
                  leading: Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_rounded, color: theme.colorScheme.primary, size: 22)
                      : null,
                  onTap: () {
                    Navigator.of(context).pop();
                    if (value != state.period) {
                      context.read<DashboardBloc>().add(ChangePeriod(period: value));
                    }
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // Naviguer vers la page Analytics
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(
                title: const Text('Analytics Avancées'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Retour',
                ),
              ),
              body: const AnalyticsTab(),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.analytics_rounded,
                color: Theme.of(context).colorScheme.primary,
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
                      Expanded(
                        child: Text(
                          'Analytics Avancées',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'NOUVEAU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Graphiques interactifs • Comparaisons • Tendances',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    PerformanceStats stats,
  ) {
    // Même style que les cartes Revenus : bordure, radius 12, fond surface
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF757575),
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.occupancyRate}%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Hero stats inline
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHeroStat(
                  context,
                  stats.totalResidences.toString(),
                  'Résidences',
                  const Color(0xFF1A1A1A),
                ),
                _buildHeroStat(
                  context,
                  stats.totalReservations.toString(),
                  'Réservations',
                  const Color(0xFF1A1A1A),
                ),
                _buildHeroStat(
                  context,
                  stats.newMessages.toString(),
                  'Messages',
                  const Color(0xFF1A1A1A),
                ),
                _buildHeroStat(
                  context,
                  stats.pendingReviews.toString(),
                  'Avis',
                  const Color(0xFF1A1A1A),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Last updated
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 4),
                Text(
                  'Mis à jour il y a 2h',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'À faire',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildActionItem(
                context,
                icon: Icons.add_business_rounded,
                title: 'Ajouter votre première résidence',
                subtitle: 'Commencez à gagner des revenus',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EditResidenceScreen())),
                showDivider: true,
              ),
              Container(
                height: 1,
                color: Colors.grey.withOpacity(0.1),
                margin: const EdgeInsets.only(left: 60),
              ),
              _buildActionItem(
                context,
                icon: Icons.calendar_month_rounded,
                title: 'Configurer vos disponibilités',
                subtitle: 'Ouvrez votre calendrier',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => MainScreenNavigator.of(context)?.navigateToTab(1),
                showDivider: true,
              ),
              Container(
                height: 1,
                color: Colors.grey.withOpacity(0.1),
                margin: const EdgeInsets.only(left: 60),
              ),
              _buildActionItem(
                context,
                icon: Icons.payment_rounded,
                title: 'Activer les paiements',
                subtitle: 'Recevez vos revenus directement',
                color: Theme.of(context).colorScheme.primary,
                onTap: () {},
                showDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Section Marketing/Croissance (Violet Yango)
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3E5F5), // Violet très clair
            borderRadius: BorderRadius.circular(16),
          ),
          child: _buildActionItem(
            context,
            icon: Icons.auto_graph_rounded,
            title: 'Attirer plus de clients',
            subtitle: 'Concluez 1 transaction par semaine...',
            color: const Color(0xFF9C27B0), // Violet
            onTap: () => MainScreenNavigator.of(context)?.navigateToTab(1),
            showDivider: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildPerformanceCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    // Get color based on icon type
    Color iconColor;
    Color bgColor;
    
    if (icon == Icons.home_rounded) {
      iconColor = Theme.of(context).colorScheme.primary; // Bleu
      bgColor = const Color(0xFFE3F2FD);
    } else if (icon == Icons.calendar_month_rounded) {
      iconColor = Colors.green; // Vert
      bgColor = const Color(0xFFE8F5E9);
    } else if (icon == Icons.message_rounded) {
      iconColor = const Color(0xFF00BCD4); // Cyan
      bgColor = const Color(0xFFE0F7FA);
    } else {
      iconColor = const Color(0xFFE91E63); // Rose pour avis
      bgColor = const Color(0xFFFCE4EC);
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSection(
    BuildContext context,
    RevenueStats revenue,
    String period,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenus',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildRevenueCard(
                context,
                'Aujourd\'hui',
                revenue.dailyRevenue,
                Icons.today_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRevenueCard(
                context,
                'Cette semaine',
                revenue.weeklyRevenue,
                Icons.calendar_view_week_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRevenueCard(
                context,
                'Ce mois',
                revenue.monthlyRevenue,
                Icons.calendar_month_rounded,
                isHighlighted: true,
              ),
            ),
          ],
        ),
        if (revenue.revenueHistory.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Historique des revenus',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: revenue.revenueHistory.isEmpty 
                      ? 1000 
                      : (revenue.revenueHistory.isEmpty || revenue.revenueHistory.where((e) => e.amount > 0).isEmpty) 
                          ? 1000 
                          : revenue.revenueHistory.map((e) => e.amount).reduce((a, b) => a > b ? a : b) / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < 0 || value.toInt() >= revenue.revenueHistory.length) {
                          return const SizedBox.shrink();
                        }
                        final date = revenue.revenueHistory[value.toInt()].date;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(
                            DateFormat('MMM').format(date),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8,
                          child: Text(
                            NumberFormat.compact().format(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (revenue.bestResidences.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Meilleures résidences',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: revenue.bestResidences.length.clamp(0, 3),
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final residence = revenue.bestResidences[index];
              return _buildBestResidenceCard(context, residence);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildBestResidenceCard(
    BuildContext context,
    BestPerformingResidence residence,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(AppConfigManager.getProfileImageUrl(residence.imageUrl ?? 
                  'assets/images/placeholders/profile_placeholder.png')),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  residence.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${residence.bookings} réservations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${NumberFormat.compact().format(residence.revenue)} FCFA',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    {bool isHighlighted = false}
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isHighlighted 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const Spacer(),
              if (isHighlighted)
                 Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat.compact().format(amount)} F',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isHighlighted 
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsSection(BuildContext context, TrendData trendData, String period) {
    // Formater les points pour le graphique
    final trendPoints = trendData.points;
    
    if (trendPoints.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Tendances',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 40,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pas de données de tendances disponibles',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
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
    
    final revenueSpots = trendPoints.asMap().entries.map((entry) {
      final int index = entry.key;
      final TrendPoint point = entry.value;
      return FlSpot(index.toDouble(), point.revenue);
    }).toList();
    
    final bookingSpots = trendPoints.asMap().entries.map((entry) {
      final int index = entry.key;
      final TrendPoint point = entry.value;
      return FlSpot(index.toDouble(), point.bookings.toDouble());
    }).toList();
    
    // Calculer le max pour l'échelle
    final double maxRevenue = trendPoints.isEmpty 
        ? 10000 
        : (trendPoints.where((p) => p.revenue > 0).isEmpty)
            ? 10000
            : trendPoints.map((p) => p.revenue).reduce((a, b) => a > b ? a : b) * 1.2;
    final double maxBookings = trendPoints.isEmpty 
        ? 10 
        : (trendPoints.where((p) => p.bookings > 0).isEmpty)
            ? 10
            : trendPoints.map((p) => p.bookings.toDouble()).reduce((a, b) => a > b ? a : b) * 1.2;
    
    final String periodTitle = {
      'daily': 'Tendances quotidiennes',
      'weekly': 'Tendances hebdomadaires',
      'monthly': 'Tendances mensuelles',
      'yearly': 'Tendances annuelles',
    }[period] ?? 'Tendances';
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    periodTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        trendData.growth >= 0 ? Icons.trending_up : Icons.trending_down,
                        color: trendData.growth >= 0 ? Colors.green : Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trendData.growth.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: trendData.growth >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: trendPoints.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bar_chart, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune donnée disponible pour cette période',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                      ],
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: maxRevenue / 5,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final int index = value.toInt();
                              if (index < 0 || index >= trendPoints.length) {
                                return const SizedBox.shrink();
                              }
                              
                              final point = trendPoints[index];
                              String label = '';
                              
                              switch (period) {
                                case 'daily':
                                  label = DateFormat('E').format(point.date);
                                  break;
                                case 'weekly':
                                  label = 'S${DateFormat('w').format(point.date)}';
                                  break;
                                case 'monthly':
                                  label = DateFormat('MMM').format(point.date);
                                  break;
                                case 'yearly':
                                  label = DateFormat('yyyy').format(point.date);
                                  break;
                                default:
                                  label = DateFormat('MM/dd').format(point.date);
                              }
                              
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8.0,
                                child: Text(
                                  NumberFormat.compact().format(value),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                          left: BorderSide(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                          right: BorderSide(
                            color: Colors.transparent,
                          ),
                          top: BorderSide(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                      minX: 0,
                      maxX: (trendPoints.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxRevenue,
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueSpots,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              Theme.of(context).colorScheme.primary,
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  context,
                  'Revenus',
                  Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  context,
                  'Taux d\'occupation: ${trendPoints.isNotEmpty ? trendPoints.last.occupancyRate.toStringAsFixed(1) : 0}%',
                  Colors.amber,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildUpcomingReservationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réservations à venir',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // En-tête des réservations
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Client',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Résidence',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Date',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Statut',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                // Message quand aucune réservation
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune réservation à venir',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lorsque vous recevrez des réservations, elles apparaîtront ici',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () {
              // Notifier le parent (MainScreen) de changer d'onglet vers Réservations (index 2)
              MainScreenNavigator.of(context)?.navigateToTab(2);
            },
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Voir toutes les réservations'),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationAnalyticsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analyse par localisation',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: const Color(0xFFF5F7FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre de la carte
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Résidences par région',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Côte d\'Ivoire',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Régions en Côte d'Ivoire
                Row(
                  children: [
                    _buildRegionCard(
                      context, 
                      'Abidjan', 
                      '1', 
                      const Color(0xFF1A237E),
                    ),
                    const SizedBox(width: 12),
                    _buildRegionCard(
                      context, 
                      'Yamoussoukro', 
                      '0', 
                      Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    _buildRegionCard(
                      context, 
                      'San-Pédro', 
                      '0', 
                      Colors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF1A237E).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF1A237E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Élargissez votre offre en ajoutant des résidences dans d\'autres villes pour atteindre plus de clients',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1A237E),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegionCard(BuildContext context, String region, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.location_on, color: color, size: 16),
            ),
            const SizedBox(height: 12),
            Text(
              count,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              region,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResidencePerformanceSection(BuildContext context, List<ResidenceStats> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance des résidences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: stats.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final residence = stats[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade200,
                            child: residence.imageUrl.isNotEmpty
                                ? Image.network(
                                    residence.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.home,
                                      color: Colors.grey,
                                    ),
                                  )
                                : const Icon(
                                    Icons.home,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                residence.title.isNotEmpty ? residence.title : 'Résidence sans nom',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                residence.displayAddress.isNotEmpty
                                    ? residence.displayAddress
                                    : 'Abidjan, Côte d\'Ivoire',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: residence.status == 'available'
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            residence.status == 'available' ? 'Disponible' : 'Indisponible',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: residence.status == 'available' ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildResidenceStatItem(
                          context,
                          'Réservations',
                          '${residence.totalBookings}',
                          Icons.calendar_today,
                        ),
                        // 🚫 TEMPORAIREMENT MASQUÉ POUR GOOGLE PLAY SUBMISSION
                        // _buildResidenceStatItem(
                        //   context,
                        //   'Revenus',
                        //   '${NumberFormat.compact().format(residence.revenue)} FCFA',
                        //   Icons.payments,
                        // ),
                        _buildResidenceStatItem(
                          context,
                          'Occupation',
                          '${residence.occupancyRate.toStringAsFixed(0)}%',
                          Icons.bar_chart,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () async {
                        try {
                          // Récupérer la résidence complète par son ID
                          final residenceService = ResidenceService(
                            baseUrl: AppConfigManager.apiUrl,
                          );
                          final fullResidence = await residenceService.getResidenceById(residence.id);
                          
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResidenceDetailsScreen(
                                  residence: fullResidence,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('Voir les détails'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResidenceStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  /// Retourne le libellé de la note (cohérent avec la valeur : 0 = aucune note).
  static String _ratingLabel(double rating) {
    if (rating <= 0) return 'Aucune note';
    if (rating < 2) return 'Mauvais';
    if (rating < 3) return 'Moyen';
    if (rating < 4) return 'Bien';
    if (rating < 4.5) return 'Bon';
    return 'Excellent';
  }

  static Color _ratingLabelColor(double rating) {
    if (rating <= 0) return Colors.grey;
    if (rating < 2) return Colors.red;
    if (rating < 3) return Colors.orange;
    if (rating < 4) return Colors.amber;
    if (rating < 4.5) return Colors.lightGreen;
    return Colors.green;
  }

  Widget _buildReviewsSection(BuildContext context, double rating) {
    final hasRating = rating > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Avis clients',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
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
                                rating.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              const Text('/5'),
                            ],
                          ),
                          Text(
                            hasRating ? 'Basé sur les avis' : 'Aucun avis pour le moment',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _ratingLabelColor(rating).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasRating)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _ratingLabelColor(rating),
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (hasRating) const SizedBox(width: 4),
                          Text(
                            _ratingLabel(rating),
                            style: TextStyle(
                              color: _ratingLabelColor(rating),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Aucun avis à afficher',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // Navigation vers la page des avis
                      },
                      child: Text(
                        'Voir tous les avis',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Icon(
                    Icons.rate_review_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Les avis de vos clients apparaîtront ici',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Section financière dédiée aux payouts avec données temps réel
  Widget _buildPayoutFinancialSection(BuildContext context) {
    return FutureBuilder<PayoutStats?>(
      future: _getPayoutStats(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPayoutLoadingSection(context);
        }
        
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildPayoutErrorSection(context, snapshot.error);
        }
        
        final stats = snapshot.data!;
        return _buildPayoutStatsSection(context, stats);
      },
    );
  }

  /// Récupère les statistiques des payouts via l'API
  Future<PayoutStats?> _getPayoutStats(BuildContext context) async {
    try {
      final dio = Dio();
      final paymentService = PaymentService(dio);
      return await paymentService.getPayoutStats();
    } catch (e) {
      return null;
    }
  }

  /// Section de chargement pour les payouts
  Widget _buildPayoutLoadingSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Mes Reversements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text('Chargement des données financières...'),
          ),
        ],
      ),
    );
  }

  /// Section d'erreur pour les payouts
  Widget _buildPayoutErrorSection(BuildContext context, Object? error) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Mes Reversements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Center(
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Impossible de charger les données financières',
              style: TextStyle(color: Colors.orange),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                // Forcer le rebuild du widget
                (context as Element).markNeedsBuild();
              },
              child: const Text('Réessayer'),
            ),
          ),
        ],
      ),
    );
  }

  /// Section des statistiques des payouts
  Widget _buildPayoutStatsSection(BuildContext context, PayoutStats stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Reversements',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Données financières en temps réel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 🚫 TEMPORAIREMENT MASQUÉ POUR GOOGLE PLAY SUBMISSION
              // GestureDetector(
              //   onTap: () {
              //     // Navigation vers l'écran détaillé des payouts
              //     Navigator.pushNamed(context, '/payouts');
              //   },
              //   child: Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              //     decoration: BoxDecoration(
              //       color: Theme.of(context).primaryColor.withOpacity(0.1),
              //       borderRadius: BorderRadius.circular(16),
              //     ),
              //     child: Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         Text(
              //           'Voir tout',
              //           style: TextStyle(
              //             color: Theme.of(context).primaryColor,
              //             fontSize: 12,
              //             fontWeight: FontWeight.w500,
              //           ),
              //         ),
              //         const SizedBox(width: 4),
              //         Icon(
              //           Icons.arrow_forward_ios,
              //           size: 12,
              //           color: Theme.of(context).primaryColor,
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 24),

          // Métriques principales
          Row(
            children: [
              Expanded(
                child: _buildPayoutMetricCard(
                  context,
                  'Total Reçu',
                  stats.formattedTotalEarned,
                  Icons.trending_up,
                  Colors.green,
                  isHighlighted: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPayoutMetricCard(
                  context,
                  'En Attente',
                  stats.formattedTotalPending,
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPayoutMetricCard(
                  context,
                  'Commissions',
                  stats.formattedTotalCommission,
                  Icons.percent,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPayoutMetricCard(
                  context,
                  'Taux Réussite',
                  '${(stats.successRate * 100).toStringAsFixed(1)}%',
                  Icons.check_circle,
                  stats.successRate > 0.9 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),

          // Statistiques détaillées
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total reversements:',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${stats.totalPayouts}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Réussis:',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${stats.successfulPayouts}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'En cours:',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${stats.pendingPayouts}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (stats.failedPayouts > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Échecs:',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        '${stats.failedPayouts}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
                if (stats.lastPayoutDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dernier reversement:',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(stats.lastPayoutDate!),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour une métrique de payout
  Widget _buildPayoutMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted ? color.withOpacity(0.3) : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const Spacer(),
              if (isHighlighted)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? color : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Section Pricing Dynamique — une seule couleur d’accent (primary) pour cohérence.
  Widget _buildPricingSection(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: primary, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pricing Dynamique',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PricingStatsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics_outlined, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        'Détails',
                        style: TextStyle(
                          fontSize: 12,
                          color: primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Optimisez vos revenus grâce au pricing intelligent',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPricingQuickStat(
                  context,
                  'Économies clients',
                  'Calculées automatiquement',
                  Icons.savings,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPricingQuickStat(
                  context,
                  'Méthodes optimisées',
                  'MTN, Wave recommandés',
                  Icons.payment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Encouragez vos clients à utiliser MTN Money ou Wave pour réduire les frais',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingQuickStat(BuildContext context, String title, String subtitle, IconData icon) {
    final primary = Theme.of(context).colorScheme.primary;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primary, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: onSurfaceVariant,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
