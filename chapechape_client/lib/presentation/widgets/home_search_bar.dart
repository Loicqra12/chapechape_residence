import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/text_styles.dart';
import 'advanced_search_widget.dart';

/// Barre de recherche "pilule" sur l'accueil.
/// Un tap ouvre un overlay flottant semi-transparent avec le formulaire de recherche.
class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({Key? key}) : super(key: key);

  void _openSearchOverlay(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (routeContext, animation, secondaryAnimation) {
          return _SearchOverlayPage(
            onSearch: (params) {
              Navigator.of(routeContext).pop();
              context.push('/search', extra: params);
            },
            onClose: () => Navigator.of(routeContext).pop(),
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            width: 1.2,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: InkWell(
          onTap: () => _openSearchOverlay(context),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 18,
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85), size: 24),
                const SizedBox(width: AppSpacing.smd),
                Expanded(
                  child: Text(
                    'Commencer ma recherche',
                    style: AppTextStyles.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.9),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.tune, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page overlay flottante.
/// Utilise un Scaffold avec fond semi-transparent + le AdvancedSearchWidget
/// (qui est prouvé stable dans un SingleChildScrollView).
class _SearchOverlayPage extends StatelessWidget {
  final Function(Map<String, dynamic>) onSearch;
  final VoidCallback onClose;

  const _SearchOverlayPage({
    required this.onSearch,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: onClose,
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.softShadow,
                ),
                child: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurface),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        child: AdvancedSearchWidget(
          onSearch: onSearch,
        ),
      ),
    );
  }
}
