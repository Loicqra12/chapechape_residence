import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/auth/auth_event.dart';
import '../../core/blocs/locale/locale_cubit.dart';
import '../../core/blocs/locale/locale_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/text_styles.dart';
import '../../core/theme/spacing.dart';

class CustomNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomNavigationBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showLanguageDialog(BuildContext context) {
    final localeCubit = context.read<LocaleCubit>();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Choisir la langue'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Text('🇫🇷', style: AppTextStyles.headline.copyWith(fontSize: 24)),
                title: const Text('Français'),
                onTap: () {
                  localeCubit.setFrench();
                  Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                leading: Text('🇬🇧', style: AppTextStyles.headline.copyWith(fontSize: 24)),
                title: const Text('English'),
                onTap: () {
                  localeCubit.setEnglish();
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return AppBar(
          backgroundColor: AppTheme.textLight,
          elevation: 1,
          title: Row(
            children: [
              GestureDetector(
                onTap: () => context.go('/'),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 40,
                ),
              ),
              const Spacer(),
              BlocBuilder<LocaleCubit, LocaleState>(
                builder: (context, localeState) {
                  final currentLocale = localeState.locale.languageCode;
                  return IconButton(
                    icon: Text(
                      currentLocale == 'fr' ? '🇫🇷' : '🇬🇧',
                      style: AppTextStyles.bodyLarge.copyWith(fontSize: 20),
                    ),
                    onPressed: () => _showLanguageDialog(context),
                    tooltip: 'Changer de langue',
                  );
                },
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                    color: AppTheme.textPrimary,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(AppSpacing.xs / 2),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '0',
                        style: AppTextStyles.caption.copyWith(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.push('/search'),
                color: AppTheme.textPrimary,
              ),
              if (state is Authenticated)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        context.push('/profile');
                        break;
                      case 'settings':
                        context.push('/settings');
                        break;
                      case 'logout':
                        context.read<AuthBloc>().add(const LogoutRequested());
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: AppTheme.textPrimary),
                          SizedBox(width: AppSpacing.sm),
                          const Text('Mon profil'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: AppTheme.textPrimary),
                          SizedBox(width: AppSpacing.sm),
                          const Text('Paramètres'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppTheme.textPrimary),
                          SizedBox(width: AppSpacing.sm),
                          const Text('Déconnexion'),
                        ],
                      ),
                    ),
                  ],
                ),
              if (state is Unauthenticated)
                Row(
                  children: [
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('S\'inscrire'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Connexion'),
                    ),
                    SizedBox(width: AppSpacing.md),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
