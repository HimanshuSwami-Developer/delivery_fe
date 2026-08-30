import 'package:shared_preferences/shared_preferences.dart';

/// Small on-device flags that aren't worth a backend round-trip — "has this
/// device seen onboarding before", and the last date each festival's popup
/// was shown (so it appears once a day, not on every app open).
class AppPrefs {
  AppPrefs._();

  static const _onboardingSeenKey = 'basket_has_seen_onboarding';
  static const _festivalPopupPrefix = 'basket_festival_popup_shown_';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> setSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  /// `true` if [festivalId]'s popup has already been shown on [today]
  /// (`yyyy-MM-dd`).
  static Future<bool> hasShownFestivalPopupToday(String festivalId, String today) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_festivalPopupPrefix$festivalId') == today;
  }

  static Future<void> markFestivalPopupShown(String festivalId, String today) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_festivalPopupPrefix$festivalId', today);
  }
}
