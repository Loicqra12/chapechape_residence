import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/locale/locale_cubit.dart';
import '../../core/blocs/locale/locale_state.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final languages = [
      {'code': 'fr', 'name': 'Français'},
      {'code': 'en', 'name': 'English'},
    ];

    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        final localeCubit = context.read<LocaleCubit>();
        final currentLocale = state.locale.languageCode;

        return Container(
          constraints: const BoxConstraints(maxWidth: 80),
          child: PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getLanguageFlag(currentLocale),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
            onSelected: (String languageCode) {
              if (languageCode == 'fr') {
                localeCubit.setFrench();
              } else if (languageCode == 'en') {
                localeCubit.setEnglish();
              }
            },
            itemBuilder: (BuildContext context) {
              return languages.map((language) {
                final isSelected = language['code'] == currentLocale;
                return PopupMenuItem<String>(
                  value: language['code'],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(language['name']!),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check, size: 18),
                      ],
                    ],
                  ),
                );
              }).toList();
            },
          ),
        );
      },
    );
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'fr':
        return '🇫🇷';
      case 'en':
        return '🇬🇧';
      default:
        return '';
    }
  }
}
