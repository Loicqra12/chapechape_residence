import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit pour le thème (clair / sombre / système).
/// Permet d'appliquer le choix de l'utilisateur depuis Paramètres → Affichage.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(ThemeMode initial) : super(initial);

  void setTheme(ThemeMode mode) => emit(mode);
}
