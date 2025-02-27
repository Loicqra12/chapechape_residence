import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/locale/locale_cubit.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocaleCubit, LocaleState>(
      builder: (context, state) {
        final localeCubit = context.read<LocaleCubit>();
        final currentLocale = state.locale.languageCode;
        final languages = localeCubit.availableLanguages;

        return PopupMenuButton<String>(
          icon: const Icon(Icons.language),
          onSelected: (String languageCode) {
            localeCubit.changeLocale(languageCode);
          },
          itemBuilder: (BuildContext context) {
            return languages.map((language) {
              final isSelected = language['code'] == currentLocale;
              return PopupMenuItem<String>(
                value: language['code'],
                child: Row(
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
        );
      },
    );
  }
}
