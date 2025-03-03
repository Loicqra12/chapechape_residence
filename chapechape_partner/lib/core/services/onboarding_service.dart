import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _key = 'onboarding_complete';
  final SharedPreferences _prefs;

  OnboardingService(this._prefs);

  Future<bool> isOnboardingComplete() async {
    return _prefs.getBool(_key) ?? false;
  }

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_key, true);
  }
}
