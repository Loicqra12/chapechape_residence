import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader pour l'écran Dashboard
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton du sélecteur de période
            _buildPeriodSelectorSkeleton(),
            const SizedBox(height: 24),
            
            // Skeleton de la section Performance
            _buildPerformanceSectionSkeleton(context),
            const SizedBox(height: 24),
            
            // Skeleton de la section Revenus
            _buildRevenueSectionSkeleton(),
            const SizedBox(height: 24),
            
            // Skeleton de la section Payouts
            _buildPayoutSectionSkeleton(),
            const SizedBox(height: 24),
            
            // Skeleton de la section Tendances
            _buildTrendsSectionSkeleton(),
            const SizedBox(height: 24),
            
            // Skeleton des réservations à venir
            _buildUpcomingReservationsSkeleton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelectorSkeleton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildPerformanceSectionSkeleton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 24,
                  width: 150,
                  color: Colors.white,
                ),
                Container(
                  height: 30,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Performance cards grid
            Row(
              children: [
                Expanded(child: _buildPerformanceCardSkeleton()),
                const SizedBox(width: 12),
                Expanded(child: _buildPerformanceCardSkeleton()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPerformanceCardSkeleton()),
                const SizedBox(width: 12),
                Expanded(child: _buildPerformanceCardSkeleton()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 24, height: 24, color: Colors.white),
          const SizedBox(height: 12),
          Container(width: 60, height: 24, color: Colors.white),
          const SizedBox(height: 4),
          Container(width: 80, height: 14, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildRevenueSectionSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 24, width: 120, color: Colors.white),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildRevenueCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _buildRevenueCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _buildRevenueCardSkeleton()),
          ],
        ),
        const SizedBox(height: 24),
        Container(height: 20, width: 180, color: Colors.white),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 24, height: 24, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Container(width: 80, height: 20, color: Colors.grey[300]),
          const SizedBox(height: 4),
          Container(width: 60, height: 14, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildPayoutSectionSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 40, height: 40, color: Colors.grey[300]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 150, height: 20, color: Colors.grey[300]),
                    const SizedBox(height: 4),
                    Container(width: 180, height: 14, color: Colors.grey[300]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildMetricCardSkeleton()),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCardSkeleton()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMetricCardSkeleton()),
              const SizedBox(width: 12),
              Expanded(child: _buildMetricCardSkeleton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 20, height: 20, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Container(width: 70, height: 18, color: Colors.grey[300]),
          const SizedBox(height: 4),
          Container(width: 50, height: 12, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildTrendsSectionSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(width: 150, height: 24, color: Colors.grey[300]),
              Container(
                width: 80,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingReservationsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 200, height: 24, color: Colors.white),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(flex: 2, child: Container(width: 60, height: 16, color: Colors.grey[300])),
                  Expanded(flex: 2, child: Container(width: 80, height: 16, color: Colors.grey[300])),
                  Expanded(child: Container(width: 50, height: 16, color: Colors.grey[300])),
                  Expanded(child: Container(width: 50, height: 16, color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(
                3,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Container(height: 14, color: Colors.grey[300])),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: Container(height: 14, color: Colors.grey[300])),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 14, color: Colors.grey[300])),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 14, color: Colors.grey[300])),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

