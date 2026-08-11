import 'package:shared_preferences/shared_preferences.dart';

/// Small on-device flags that aren't worth a backend round-trip —
/// currently just "has this device seen onboarding before".
class AppPrefs {
  AppPrefs._();

  static const _onboardingSeenKey = 'basket_has_seen_onboarding';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> setSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }
}
