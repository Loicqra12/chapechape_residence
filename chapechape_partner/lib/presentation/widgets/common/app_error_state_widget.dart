import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import 'buttons/primary_button.dart';

/// État d'erreur unifié (illustration empty_error, message type "Oups... impossible", Réessayer + Retour au Dashboard).
class AppErrorStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final VoidCallback onRetry;
  final bool isNetworkError;
  final bool isAuthError;
  final VoidCallback? onReconnect;
  final VoidCallback? onBackToDashboard;
  final String? imagePath;

  const AppErrorStateWidget({
    super.key,
    required this.message,
    required this.onRetry,
    this.subtitle,
    this.isNetworkError = false,
    this.isAuthError = false,
    this.onReconnect,
    this.onBackToDashboard,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final IconData icon = isNetworkError
        ? Icons.signal_wifi_off_rounded
        : isAuthError
            ? Icons.lock_outline_rounded
            : Icons.error_outline_rounded;
    final Color iconColor = isNetworkError || isAuthError
        ? AppColors.accentViolet.withOpacity(0.7)
        : theme.colorScheme.error.withOpacity(0.9);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildIcon(icon, iconColor),
                )
              else
                _buildIcon(icon, iconColor),
              const SizedBox(height: 28),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  height: 1.3,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                text: 'Réessayer',
                onPressed: onRetry,
                filled: true,
                icon: Icons.refresh_rounded,
              ),
              if (onBackToDashboard != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: onBackToDashboard,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentViolet,
                    side: BorderSide(color: AppColors.accentViolet),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  child: const Text('Retour au Dashboard'),
                ),
              ],
              if (isAuthError && onReconnect != null && onBackToDashboard == null) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onReconnect,
                  child: const Text('Se reconnecter'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 56, color: color),
    );
  }
}
