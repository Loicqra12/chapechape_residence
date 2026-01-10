import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/blocs/auth/auth_bloc.dart';
import '../../core/blocs/auth/auth_state.dart';
import '../../core/blocs/auth/auth_event.dart';
import '../../core/blocs/locale/locale_cubit.dart';
import '../../core/blocs/locale/locale_state.dart';

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
                leading: const Text('🇫🇷', style: TextStyle(fontSize: 24)),
                title: const Text('Français'),
                onTap: () {
                  localeCubit.setFrench();
                  Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
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
          backgroundColor: Colors.white,
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
                      style: const TextStyle(fontSize: 20),
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
                    color: Colors.black87,
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: const Text(
                        '0',
                        style: TextStyle(
                          color: Colors.black87,
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
                color: Colors.black87,
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
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.black87),
                          SizedBox(width: 8),
                          Text('Mon profil'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: Colors.black87),
                          SizedBox(width: 8),
                          Text('Paramètres'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.black87),
                          SizedBox(width: 8),
                          Text('Déconnexion'),
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
                    const SizedBox(width: 16),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
