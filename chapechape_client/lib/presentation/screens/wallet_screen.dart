import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
import 'package:chapechape_client/core/theme/spacing.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Retour',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Portefeuille & Récompenses',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  const SizedBox(width: 48), // pour équilibrer la place de l'icône retour
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // SECTION PORTEFEUILLE
                _buildWalletSection(),
                const SizedBox(height: 24),
                // SECTION RÉCOMPENSES
                _buildRewardsSection(),
                const SizedBox(height: 12),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Column(
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
                      const Text(
                        '0 FCFA',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
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
          const Text(
            'Transactions récentes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.smd),
          
          // Message si aucune transaction
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune transaction',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Vos transactions apparaîtront ici',
                    style: TextStyle(
                      fontSize: 14,
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

  Widget _buildRewardsSection() {
    return Column(
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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