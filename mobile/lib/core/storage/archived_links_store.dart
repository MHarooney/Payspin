import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Client-side "hidden from recent" payment links — no archive API, so IDs live
/// in [SharedPreferences]. A [ChangeNotifier] so Home reacts live to hide/undo.
class ArchivedLinksStore extends ChangeNotifier {
  ArchivedLinksStore(this._prefs) {
    _ids = (_prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  static const String _key = 'payspin_archived_link_ids';

  final SharedPreferences _prefs;
  Set<String> _ids = <String>{};

  Set<String> get ids => Set.unmodifiable(_ids);

  bool isArchived(String id) => _ids.contains(id);

  Future<void> archive(String id) async {
    if (_ids.add(id)) {
      await _prefs.setStringList(_key, _ids.toList());
      notifyListeners();
    }
  }

  Future<void> unarchive(String id) async {
    if (_ids.remove(id)) {
      await _prefs.setStringList(_key, _ids.toList());
      notifyListeners();
    }
  }
}
