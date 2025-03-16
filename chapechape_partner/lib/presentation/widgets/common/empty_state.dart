import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.subtitle,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ).animate()
              .scale(duration: 400.ms, curve: Curves.easeOut)
              .fadeIn(duration: 300.ms),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ).animate()
              .fadeIn(duration: 300.ms, delay: 100.ms)
              .moveY(begin: 10, duration: 400.ms, curve: Curves.easeOut),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ).animate()
              .fadeIn(duration: 300.ms, delay: 200.ms)
              .moveY(begin: 10, duration: 400.ms, curve: Curves.easeOut),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ).animate()
                .fadeIn(duration: 300.ms, delay: 300.ms)
                .moveY(begin: 10, duration: 400.ms, curve: Curves.easeOut),
            ],
          ],
        ),
      ),
    );
  }
}
