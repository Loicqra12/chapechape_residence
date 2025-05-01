import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/dashboard/dashboard_bloc.dart';
import '../settings/settings_screen.dart';
import '../payments/payments_screen.dart' hide PaymentBloc;
import '../notifications/notifications_screen.dart';
import '../help/help_screen.dart' hide HelpBloc;
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import '../../widgets/layout/screen_app_bars.dart';
import '../../../core/blocs/payment/payment_bloc.dart';
import '../../../core/blocs/help/help_bloc.dart';
import '../residences/residences_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'dart:io' show Platform;
import 'package:chapechape_partner/core/config/app_config_manager.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Déclencher le chargement des statistiques si nécessaire
    if (context.read<DashboardBloc>().state is! DashboardLoaded) {
      context.read<DashboardBloc>().add(LoadDashboardData());
    }
    
    // Récupérer les données du partenaire
    final partner = context.select((AuthBloc bloc) =>
        bloc.state is AuthAuthenticated ? (bloc.state as AuthAuthenticated).partner : null);
    
    // Récupérer les statistiques
    final dashboardState = context.select((DashboardBloc bloc) => bloc.state);
    final dashboardStats = dashboardState is DashboardLoaded ? dashboardState.partnerStats : null;
    
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          ScreenAppBars.getProfileAppBar(context),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Photo de profil et bouton d'édition
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Hero(
                              tag: 'profile_photo',
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: theme.colorScheme.primaryContainer,
                                backgroundImage: partner?.profilePictureUrl != null
                                    ? NetworkImage(_buildProfileImageUrl(partner!.profilePictureUrl!))
                                    : null,
                                child: partner?.profilePictureUrl == null
                                    ? Text(
                                        partner?.fullName?.substring(0, 1).toUpperCase() ?? 'P',
                                        style: TextStyle(
                                          fontSize: 48,
                                          color: theme.colorScheme.onPrimaryContainer,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Material(
                            color: theme.colorScheme.primary,
                            shape: const CircleBorder(),
                            elevation: 4,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfileScreen(),
                                  ),
                                );
                              },
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn().scale(),

                    const SizedBox(height: 16),

                    // Nom et badge vérifié
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          partner?.fullName ?? '',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (partner?.isVerified ?? false)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Vérifié',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    // Rôle en badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        partner?.role.toUpperCase() ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Informations sur les résidences
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.home_work_outlined,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Vos résidences',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<DashboardBloc, DashboardState>(
                              builder: (context, state) {
                                final int totalResidences = state is DashboardLoaded 
                                    ? state.dashboardData.performance.totalResidences
                                    : 0;
                                
                                final int availableResidences = state is DashboardLoaded
                                    ? state.residenceStats.where((r) => r.status == 'available').length
                                    : 0;
                                
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildResidenceIndicator(
                                      context,
                                      count: totalResidences,
                                      label: 'Résidences',
                                      icon: Icons.home,
                                      color: theme.colorScheme.primary,
                                    ),
                                    _buildResidenceIndicator(
                                      context,
                                      count: availableResidences,
                                      label: 'Disponibles',
                                      icon: Icons.check_circle_outline,
                                      color: Colors.green,
                                    ),
                                    _buildResidenceIndicator(
                                      context,
                                      count: totalResidences - availableResidences,
                                      label: 'Occupées',
                                      icon: Icons.timer,
                                      color: Colors.orange,
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                onPressed: () {
                                  // Naviguer vers la liste des résidences
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ResidencesScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward),
                                label: const Text('Gérer mes résidences'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Informations de contact
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoTile(
                              icon: Icons.email_outlined,
                              title: 'Email',
                              subtitle: partner?.email ?? '',
                              theme: theme,
                            ),
                            const Divider(),
                            _buildInfoTile(
                              icon: Icons.phone_outlined,
                              title: 'Téléphone',
                              subtitle: partner?.phoneNumber ?? '',
                              theme: theme,
                            ),
                            const Divider(),
                            _buildInfoTile(
                              icon: Icons.business_outlined,
                              title: 'Rôle',
                              subtitle: partner?.role ?? '',
                              theme: theme,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideX(),

                    const SizedBox(height: 24),

                    // Statistiques
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.home_outlined,
                            value: dashboardState is DashboardLoaded 
                                ? '${dashboardState.dashboardData.performance.totalResidences}'
                                : '-',
                            label: 'Résidences',
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star_outline,
                            value: dashboardState is DashboardLoaded 
                                ? '${dashboardState.dashboardData.stats.rating}'
                                : '-',
                            label: 'Note moyenne',
                            theme: theme,
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(),

                    const SizedBox(height: 16),

                    // Deuxième rangée de statistiques
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.calendar_today_outlined,
                            value: dashboardState is DashboardLoaded 
                                ? '${dashboardState.dashboardData.performance.totalReservations}'
                                : '-',
                            label: 'Réservations',
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.monetization_on_outlined,
                            value: dashboardState is DashboardLoaded 
                                ? '${dashboardState.dashboardData.revenue.totalRevenue} FCFA'
                                : '-',
                            label: 'Revenus',
                            theme: theme,
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(),

                    const SizedBox(height: 24),

                    // Menu
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outline.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildMenuTile(
                            icon: Icons.settings_outlined,
                            title: 'Paramètres',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsScreen.withBloc(context),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.lock_outline,
                            title: 'Changer le mot de passe',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ChangePasswordScreen(),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.payment_outlined,
                            title: 'Paiements',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentsScreen.withBloc(context),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notifications',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const NotificationsScreen(),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                          const Divider(height: 1),
                          _buildMenuTile(
                            icon: Icons.help_outline,
                            title: 'Aide',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HelpScreen.withBloc(context),
                                ),
                              );
                            },
                            theme: theme,
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideX(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(title),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }

  String _buildProfileImageUrl(String url) {
    // Si l'URL est vide, retourner une image par défaut au lieu d'une chaîne vide
    if (url.isEmpty) return 'https://via.placeholder.com/120';
    
    // Si l'URL est déjà complète, la retourner telle quelle
    if (url.startsWith('http')) return url;
    
    // Utiliser AppConfigManager pour construire l'URL
    return AppConfigManager.getProfileImageUrl(url);
  }

  Widget _buildResidenceIndicator(
    BuildContext context, {
    required int count,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
