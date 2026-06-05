import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's language and drives [MaterialApp.locale].
class LocaleController extends ChangeNotifier {
  LocaleController(this._prefs);

  static const _prefKey = 'payspin_locale';

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
    Locale('de'),
    Locale('ar'),
  ];

  final SharedPreferences _prefs;
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  Future<void> load() async {
    final stored = _prefs.getString(_prefKey);
    _locale = supportedLocales.firstWhere(
      (l) => l.languageCode == stored,
      orElse: () => const Locale('en'),
    );
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!supportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    _locale = Locale(locale.languageCode);
    await _prefs.setString(_prefKey, _locale.languageCode);
    notifyListeners();
  }

  String get languageLabel => switch (_locale.languageCode) {
        'nl' => 'Nederlands',
        'de' => 'Deutsch',
        'ar' => 'العربية',
        _ => 'English',
      };
}
