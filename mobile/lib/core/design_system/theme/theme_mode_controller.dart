import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's theme preference and drives [MaterialApp.themeMode].
class ThemeModeController extends ChangeNotifier {
  ThemeModeController(this._prefs);

  static const _prefKey = 'payspin_theme_mode';

  final SharedPreferences _prefs;
  // Dark is the default Payspin experience; users can switch in Profile.
  ThemeMode _mode = ThemeMode.dark;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final stored = _prefs.getString(_prefKey);
    _mode = switch (stored) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    await _prefs.setString(_prefKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    });
    notifyListeners();
  }

  String get modeLabel => switch (_mode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };
}
