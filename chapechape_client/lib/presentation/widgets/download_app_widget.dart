import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_assets.dart';
import '../../core/blocs/app_download/app_download_bloc.dart';
import '../../core/models/app_store_model.dart';

class DownloadAppWidget extends StatelessWidget {
  const DownloadAppWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AppDownloadBloc()..add(const AppDownloadEvent.started()),
      child: BlocBuilder<AppDownloadBloc, AppDownloadState>(
        builder: (context, state) {
          return state.maybeWhen(
            initial: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => Center(child: Text('Error: $message')),
            loaded: (stores) => _buildContent(context, stores),
            orElse: () => const SizedBox(),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<AppStoreModel> stores) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Téléchargez notre application',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Image.asset(
                AppAssets.appIcon,
                height: 120,
                width: 120,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ChapeChape Résidences',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Téléchargez notre application pour une meilleure expérience',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: stores.map((store) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: _StoreButton(
                          store: store,
                          onTap: () => context.read<AppDownloadBloc>().add(
                            AppDownloadEvent.downloadRequested(storeId: store.id),
                          ),
                        ),
                      )).toList(),
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
}

class _StoreButton extends StatelessWidget {
  final AppStoreModel store;
  final VoidCallback? onTap;

  const _StoreButton({
    required this.store,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          if (store.isDownloading)
            const CircularProgressIndicator()
          else
            Image.asset(
              store.badge,
              height: 40,
            ),
        ],
      ),
    );
  }
}
