import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

// Événements
abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object> get props => [];
}

class ToggleNotifications extends SettingsEvent {
  final bool enabled;
  
  const ToggleNotifications({required this.enabled});
  
  @override
  List<Object> get props => [enabled];
}

class ChangeLanguage extends SettingsEvent {
  final String language;
  
  const ChangeLanguage({required this.language});
  
  @override
  List<Object> get props => [language];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class SaveSettings extends SettingsEvent {
  const SaveSettings();
}

// État
class SettingsState extends Equatable {
  final bool notificationsEnabled;
  final String language;
  final bool isLoading;
  final bool isSaved;
  
  const SettingsState({
    this.notificationsEnabled = true,
    this.language = AppConstants.languageFrench,
    this.isLoading = false,
    this.isSaved = false,
  });
  
  SettingsState copyWith({
    bool? notificationsEnabled,
    String? language,
    bool? isLoading,
    bool? isSaved,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      language: language ?? this.language,
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
    );
  }
  
  @override
  List<Object> get props => [notificationsEnabled, language, isLoading, isSaved];
}

// Bloc
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<SaveSettings>(_onSaveSettings);
    on<ToggleNotifications>(_onToggleNotifications);
    on<ChangeLanguage>(_onChangeLanguage);
  }
  
  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsEnabled = prefs.getBool(AppConstants.prefsNotificationsEnabled) ?? true;
      final language = prefs.getString(AppConstants.prefsLanguage) ?? AppConstants.languageFrench;
      
      emit(state.copyWith(
        notificationsEnabled: notificationsEnabled,
        language: language,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }
  
  Future<void> _onSaveSettings(SaveSettings event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(isLoading: true));
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefsNotificationsEnabled, state.notificationsEnabled);
      await prefs.setString(AppConstants.prefsLanguage, state.language);
      
      emit(state.copyWith(isLoading: false, isSaved: true));
      
      // Réinitialiser le drapeau de sauvegarde après un court délai
      await Future.delayed(const Duration(seconds: 2));
      emit(state.copyWith(isSaved: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false));
    }
  }
  
  void _onToggleNotifications(ToggleNotifications event, Emitter<SettingsState> emit) {
    emit(state.copyWith(notificationsEnabled: event.enabled));
  }
  
  void _onChangeLanguage(ChangeLanguage event, Emitter<SettingsState> emit) {
    emit(state.copyWith(language: event.language));
  }
} 