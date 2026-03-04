import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';
import 'package:chapechape_client/core/theme/text_styles.dart';
import 'package:chapechape_client/core/utils/responsive_utils.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Portefeuille & Récompenses'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          tabs: const [
            Tab(text: 'Portefeuille'),
            Tab(text: 'Récompenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWalletTab(),
          _buildRewardsTab(),
        ],
      ),
    );
  }

  Widget _buildWalletTab() {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                          // Action pour recharger le portefeuille
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl30), // 30px pour espacement spécifique
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
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return SingleChildScrollView(
      padding: context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points de fidélité
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
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
            icon: Icons.house,
            title: 'Réserver une résidence',
            description: 'Gagnez 100 points pour chaque nouvelle réservation',
          ),
          _buildRewardMethod(
            icon: Icons.rate_review,
            title: 'Laisser un avis',
            description: 'Gagnez 50 points en laissant un avis détaillé',
          ),
          _buildRewardMethod(
            icon: Icons.person_add,
            title: 'Parrainer un ami',
            description: 'Gagnez 200 points lorsqu\'un ami s\'inscrit avec votre code',
          ),
          _buildRewardMethod(
            icon: Icons.calendar_month,
            title: 'Séjours longue durée',
            description: 'Gagnez 10 points supplémentaires par jour pour les séjours de plus de 7 jours',
          ),
        ],
      ),
    );
  }

  Widget _buildRewardMethod({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm10), // 10px pour espacement spécifique
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
} 