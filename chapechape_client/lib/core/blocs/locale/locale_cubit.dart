import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_state.dart';

class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit({Locale? defaultLocale}) : super(LocaleState.initial(defaultLocale)) {
    _loadSavedLocale();
  }

  static const String _localeKey = 'app_locale';

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_localeKey);
    
    if (savedLocale != null) {
      final parts = savedLocale.split('_');
      if (parts.isNotEmpty) {
        final locale = parts.length > 1
            ? Locale(parts[0], parts[1])
            : Locale(parts[0]);
        
        emit(state.copyWith(locale: locale));
      }
    }
  }

  Future<void> changeLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    final localeString = locale.countryCode != null
        ? '${locale.languageCode}_${locale.countryCode}'
        : locale.languageCode;
    
    await prefs.setString(_localeKey, localeString);
    emit(state.copyWith(locale: locale));
  }

  Future<void> setFrench() async {
    await changeLocale(const Locale('fr'));
  }

  Future<void> setEnglish() async {
    await changeLocale(const Locale('en'));
  }
}
