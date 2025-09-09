import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/pricing/pricing_model.dart';

/// Widget graphique pour afficher la répartition par méthode de paiement
class MethodBreakdownChart extends StatelessWidget {
  final Map<String, MethodStats> methodStats;

  const MethodBreakdownChart({
    super.key,
    required this.methodStats,
  });

  @override
  Widget build(BuildContext context) {
    if (methodStats.isEmpty) {
      return _buildEmptyState();
    }

    final totalCount = methodStats.values.fold<int>(0, (sum, stats) => sum + stats.count);
    final totalRevenue = methodStats.values.fold<double>(0, (sum, stats) => sum + stats.revenue);

    return Column(
      children: [
        // Graphique en barres horizontales
        ...methodStats.entries.map((entry) {
          final percentage = totalCount > 0 ? (entry.value.count / totalCount) * 100 : 0.0;
          final revenuePercentage = totalRevenue > 0 ? (entry.value.revenue / totalRevenue) * 100 : 0.0;
          
          return _buildMethodBar(
            method: entry.key,
            stats: entry.value,
            percentage: percentage,
            revenuePercentage: revenuePercentage,
          );
        }).toList(),
        
        const SizedBox(height: 16),
        
        // Résumé
        _buildSummary(totalCount, totalRevenue),
      ],
    );
  }

  Widget _buildMethodBar({
    required String method,
    required MethodStats stats,
    required double percentage,
    required double revenuePercentage,
  }) {
    final methodInfo = _getMethodInfo(method);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: methodInfo.color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  methodInfo.icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      methodInfo.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${stats.count} réservations • ${NumberFormat('#,###').format(stats.revenue)} XOF',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Barre de progression pour les réservations
          Row(
            children: [
              const SizedBox(width: 36),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Réservations:',
                          style: TextStyle(fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(methodInfo.color),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 4),
          
          // Barre de progression pour les revenus
          Row(
            children: [
              const SizedBox(width: 36),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Revenus:',
                          style: TextStyle(fontSize: 11),
                        ),
                        const Spacer(),
                        Text(
                          '${revenuePercentage.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: revenuePercentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(methodInfo.color.withOpacity(0.7)),
                      minHeight: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(int totalCount, double totalRevenue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                totalCount.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Text(
                'Total réservations',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Container(
            height: 30,
            width: 1,
            color: Colors.grey[300],
          ),
          Column(
            children: [
              Text(
                '${NumberFormat('#,###').format(totalRevenue)} XOF',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const Text(
                'Total revenus',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les statistiques apparaîtront après vos premières réservations',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  _MethodDisplayInfo _getMethodInfo(String method) {
    switch (method) {
      case 'mtn_money':
        return _MethodDisplayInfo(
          displayName: 'MTN Money',
          icon: Icons.phone_android,
          color: const Color(0xFFFFCC02),
        );
      case 'orange_money':
        return _MethodDisplayInfo(
          displayName: 'Orange Money',
          icon: Icons.phone_android,
          color: const Color(0xFFFF6600),
        );
      case 'wave':
        return _MethodDisplayInfo(
          displayName: 'Wave',
          icon: Icons.waves,
          color: const Color(0xFF00D4FF),
        );
      case 'moov_money':
        return _MethodDisplayInfo(
          displayName: 'Moov Money',
          icon: Icons.phone_android,
          color: const Color(0xFF0066CC),
        );
      case 'card':
        return _MethodDisplayInfo(
          displayName: 'Carte bancaire',
          icon: Icons.credit_card,
          color: const Color(0xFF6B7280),
        );
      default:
        return _MethodDisplayInfo(
          displayName: method,
          icon: Icons.payment,
          color: Colors.grey,
        );
    }
  }
}

class _MethodDisplayInfo {
  final String displayName;
  final IconData icon;
  final Color color;

  const _MethodDisplayInfo({
    required this.displayName,
    required this.icon,
    required this.color,
  });
}
