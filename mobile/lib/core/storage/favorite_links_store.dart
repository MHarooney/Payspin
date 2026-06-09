import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Client-side "starred" payment links — there is no favorites API, so pinned
/// link IDs live in [SharedPreferences]. A [ChangeNotifier] so Home (and the
/// star on each row) react live to toggles without a reload.
class FavoriteLinksStore extends ChangeNotifier {
  FavoriteLinksStore(this._prefs) {
    _ids = (_prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  static const String _key = 'payspin_favorite_link_ids';

  /// Keep the Favorites strip a deliberate shortlist, not a second list.
  static const int maxFavorites = 8;

  final SharedPreferences _prefs;
  Set<String> _ids = <String>{};

  /// Unmodifiable view of the pinned link IDs.
  Set<String> get ids => Set.unmodifiable(_ids);

  bool isFavorite(String id) => _ids.contains(id);

  bool get isFull => _ids.length >= maxFavorites;

  /// Toggles [id]. Returns false (and does nothing) when adding would exceed
  /// [maxFavorites]; callers can surface a hint in that case.
  Future<bool> toggle(String id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      if (_ids.length >= maxFavorites) return false;
      _ids.add(id);
    }
    await _prefs.setStringList(_key, _ids.toList());
    notifyListeners();
    return true;
  }
}
