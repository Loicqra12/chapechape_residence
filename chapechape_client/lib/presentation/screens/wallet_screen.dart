import 'package:flutter/material.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/utils/responsive_utils.dart';

/// Écran Portefeuille & Récompenses
/// Deux onglets simples, chacun avec un seul scroll (ListView) pour éviter
/// les problèmes de layout dans le TabBarView.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const TabBar(
                  indicatorColor: Colors.black,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.black54,
                  tabs: [
                    Tab(text: 'Portefeuille'),
                    Tab(text: 'Récompenses'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _WalletTab(bottomInset: bottomInset),
                    _RewardsTab(bottomInset: bottomInset),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletTab extends StatelessWidget {
  final double bottomInset;

  const _WalletTab({required this.bottomInset});

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md + bottomInset + 8,
    );

    return ListView(
      padding: padding,
      children: [
        // Solde du portefeuille
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solde disponible',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                AppSpacing.verticalSm,
                Row(
                  children: [
                    Text(
                      '0 FCFA',
                      style: AppTextStyles.headline.copyWith(
                        fontSize: context.responsiveFontSize(28),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Action pour recharger le portefeuille
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                      ),
                      child: const Text('Recharger'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalLg,

        // Transactions récentes
        Text(
          'Transactions récentes',
          style: AppTextStyles.subtitle.copyWith(
            fontSize: context.responsiveFontSize(18),
          ),
        ),
        SizedBox(height: AppSpacing.smd),

        // Message si aucune transaction
        SizedBox(
          height: context.responsiveHeight(220),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl30),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                AppSpacing.verticalMd,
                Text(
                  'Aucune transaction',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: context.responsiveFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                ),
                AppSpacing.verticalSm,
                Text(
                  'Vos transactions apparaîtront ici',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: context.responsiveFontSize(14),
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardsTab extends StatelessWidget {
  final double bottomInset;

  const _RewardsTab({required this.bottomInset});

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.fromLTRB(
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md,
      AppSpacing.md + bottomInset + 8,
    );

    return ListView(
      padding: padding,
      children: [
        // Points de fidélité
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ).borderRadius,
          ),
          color: AppTheme.secondaryColor,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Points de fidélité',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black87,
                      ),
                ),
                AppSpacing.verticalSm,
                Row(
                  children: [
                    Text(
                      '0 points',
                      style: AppTextStyles.headline.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star,
                      color: Colors.black,
                      size: 32,
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.smd),
                Text(
                  '1 point = 10 FCFA de réduction',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                      ),
                ),
              ],
            ),
          ),
        ),

        AppSpacing.verticalLg,

        // Comment gagner des points
        Text(
          'Comment gagner des points',
          style: AppTextStyles.subtitle,
        ),
        SizedBox(height: AppSpacing.smd),

        _buildRewardMethod(
          context,
          icon: Icons.house,
          title: 'Réserver une résidence',
          description: 'Gagnez 100 points pour chaque nouvelle réservation',
        ),
        _buildRewardMethod(
          context,
          icon: Icons.rate_review,
          title: 'Laisser un avis',
          description: 'Gagnez 50 points en laissant un avis détaillé',
        ),
        _buildRewardMethod(
          context,
          icon: Icons.person_add,
          title: 'Parrainer un ami',
          description: 'Gagnez 200 points lorsqu\'un ami s\'inscrit avec votre code',
        ),
        _buildRewardMethod(
          context,
          icon: Icons.calendar_month,
          title: 'Séjours longue durée',
          description: 'Gagnez 10 points supplémentaires par jour pour les séjours de plus de 7 jours',
        ),
      ],
    );
  }

  Widget _buildRewardMethod(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm10),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
}