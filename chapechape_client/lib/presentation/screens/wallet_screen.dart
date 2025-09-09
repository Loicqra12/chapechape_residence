import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:chapechape_client/core/theme/app_theme.dart';
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
        backgroundColor: const Color(0xFFFFD700),
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solde disponible',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '0 FCFA',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(28),
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
                            borderRadius: BorderRadius.circular(8),
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
          
          const SizedBox(height: 24),
          
          // Transactions récentes
          Text(
            'Transactions récentes',
            style: TextStyle(
              fontSize: context.responsiveFontSize(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Message si aucune transaction
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune transaction',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos transactions apparaîtront ici',
                  style: TextStyle(
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
              borderRadius: BorderRadius.circular(16),
            ),
            color: AppTheme.secondaryColor,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Points de fidélité',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '0 points',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 12),
                  const Text(
                    '1 point = 10 FCFA de réduction',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Comment gagner des points
          const Text(
            'Comment gagner des points',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
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
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(description),
      ),
    );
  }
} 