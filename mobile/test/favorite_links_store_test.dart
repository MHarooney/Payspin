import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/storage/favorite_links_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<FavoriteLinksStore> store([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return FavoriteLinksStore(prefs);
  }

  test('starts empty when nothing persisted', () async {
    final s = await store();
    expect(s.ids, isEmpty);
    expect(s.isFavorite('a'), isFalse);
  });

  test('toggle adds, persists, and notifies', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = FavoriteLinksStore(prefs);
    var notified = 0;
    s.addListener(() => notified++);

    expect(await s.toggle('link1'), isTrue);
    expect(s.isFavorite('link1'), isTrue);
    expect(notified, 1);
    expect(prefs.getStringList('payspin_favorite_link_ids'), ['link1']);

    // A new store reading the same prefs sees the persisted favorite.
    final reloaded = FavoriteLinksStore(prefs);
    expect(reloaded.isFavorite('link1'), isTrue);
  });

  test('toggle removes an existing favorite', () async {
    final s = await store({'payspin_favorite_link_ids': ['x', 'y']});
    expect(s.isFavorite('x'), isTrue);
    expect(await s.toggle('x'), isTrue);
    expect(s.isFavorite('x'), isFalse);
    expect(s.ids, {'y'});
  });

  test('caps at 8 favorites and reports full', () async {
    final s = await store();
    for (var i = 0; i < FavoriteLinksStore.maxFavorites; i++) {
      expect(await s.toggle('id$i'), isTrue);
    }
    expect(s.isFull, isTrue);
    // Adding a 9th is rejected and does not persist.
    expect(await s.toggle('overflow'), isFalse);
    expect(s.isFavorite('overflow'), isFalse);
    expect(s.ids.length, FavoriteLinksStore.maxFavorites);
  });
}
