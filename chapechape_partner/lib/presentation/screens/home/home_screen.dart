import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/auth/auth_bloc.dart';
import '../../../core/blocs/auth/auth_event.dart';
import '../../../core/blocs/sync/sync_bloc.dart';
import '../../widgets/sync/sync_status_widget.dart';
import '../../widgets/offline/offline_indicator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final partner = context.select((AuthBloc bloc) =>
        bloc.state is AuthAuthenticated ? (bloc.state as AuthAuthenticated).partner : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChapeChape Partner'),
        actions: [
          const PendingOperationsCounter(),
          const SyncButton(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SyncStatusWidget(
              showDetails: false,
              showForceButton: false,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineIndicator(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue, ${partner?.fullName ?? ''}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    SyncStatusWidget(
                      showDetails: true,
                      showForceButton: true,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _buildDashboardPlaceholder(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDashboardPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.dashboard_customize,
          size: 64,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        Text(
          'Tableau de bord en construction...',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade700,
              ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pushNamed('/dashboard');
          },
          icon: const Icon(Icons.dashboard),
          label: const Text('Aller au tableau de bord provisoire'),
        ),
      ],
    );
  }
}
