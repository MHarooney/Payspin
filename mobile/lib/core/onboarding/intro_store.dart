import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether the user has seen the one-time Wise-style intro storyboard.
abstract final class IntroStore {
  static const _key = 'payspin_intro_seen';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
