import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/blocs/dashboard/dashboard_bloc.dart';
import '../../../core/models/dashboard/dashboard_data.dart';
import 'package:intl/intl.dart';
import '../../widgets/layout/screen_app_bars.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        return Scaffold(
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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPerformanceSection(context, state.data.performance),
            const SizedBox(height: 24),
            _buildRevenueSection(context, state.data.revenue, state.revenuePeriod),
            const SizedBox(height: 24),
            _buildStatsSection(context, state.data.stats),
            const SizedBox(height: 24),
            _buildRealtimeSection(context, state.data.realtime),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPerformanceSection(
    BuildContext context,
    PerformanceStats stats,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B8DE3), Color(0xFF0C1E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                Text(
                  'Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.greenAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.occupancyRate}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPerformanceCard(
                    context,
                    'Résidences',
                    stats.totalResidences.toString(),
                    Icons.home_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPerformanceCard(
                    context,
                    'Réservations',
                    stats.totalReservations.toString(),
                    Icons.calendar_month_rounded,
                  ),
                ),
              ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.7),
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
              ),
            ),
          ],
        ),
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
            itemCount: revenue.bestResidences.length,
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
                image: NetworkImage(residence.imageUrl ?? 
                  'https://via.placeholder.com/60'),
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
                '${residence.revenue.toStringAsFixed(0)} FCFA',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            '${amount.toStringAsFixed(0)} FCFA',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, GeneralStats stats) {
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
            Text(
              'Statistiques',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _buildStatCard(
              context,
              'Taux de réponse',
              '${stats.responseRate}%',
              Icons.message_rounded,
              const Color(0xFF00B2FF),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              'Temps de réponse moyen',
              '${stats.averageResponseTime} min',
              Icons.timer_rounded,
              const Color(0xFFFF6B00),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              'Note moyenne',
              '${stats.rating}/5',
              Icons.star_rounded,
              const Color(0xFFFFB800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealtimeSection(BuildContext context, RealtimeStats realtime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'En temps réel',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildRealtimeCard(
                context,
                'Réservations actives',
                realtime.activeBookings.toString(),
                Icons.calendar_today_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRealtimeCard(
                context,
                'Demandes en attente',
                realtime.pendingRequests.toString(),
                Icons.pending_rounded,
              ),
            ),
          ],
        ),
        if (realtime.todayVisits.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Visites du jour',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: realtime.todayVisits.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final visit = realtime.todayVisits[index];
              return _buildVisitCard(context, visit);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildRealtimeCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitCard(BuildContext context, TodayVisit visit) {
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
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(
              visit.client.avatar ?? 'https://via.placeholder.com/48',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.client.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  visit.residence.name,
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
                visit.time,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(visit.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(visit.status),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(visit.status),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmée';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'Inconnu';
    }
  }
}
