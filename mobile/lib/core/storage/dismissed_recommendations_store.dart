import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/home/home_dashboard_data.dart';

/// Client-side dismissed "Recommended for you" cards — no API.
class DismissedRecommendationsStore extends ChangeNotifier {
  DismissedRecommendationsStore(this._prefs) {
    _ids = <HomeRecommendation>{};
    for (final name in _prefs.getStringList(_key) ?? const <String>[]) {
      for (final rec in HomeRecommendation.values) {
        if (rec.name == name) _ids.add(rec);
      }
    }
  }

  static const String _key = 'payspin_dismissed_recommendations';

  final SharedPreferences _prefs;
  Set<HomeRecommendation> _ids = {};

  Set<HomeRecommendation> get ids => Set.unmodifiable(_ids);

  bool isDismissed(HomeRecommendation rec) => _ids.contains(rec);

  Future<void> dismiss(HomeRecommendation rec) async {
    if (_ids.add(rec)) {
      await _prefs.setStringList(_key, _ids.map((e) => e.name).toList());
      notifyListeners();
    }
  }
}
