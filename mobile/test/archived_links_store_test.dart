import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/storage/archived_links_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ArchivedLinksStore> store([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return ArchivedLinksStore(prefs);
  }

  test('archive and unarchive persist ids', () async {
    final s = await store();
    await s.archive('a');
    expect(s.isArchived('a'), isTrue);

    SharedPreferences.setMockInitialValues({'payspin_archived_link_ids': <String>['a']});
    final prefs = await SharedPreferences.getInstance();
    final reloaded = ArchivedLinksStore(prefs);
    expect(reloaded.isArchived('a'), isTrue);

    await reloaded.unarchive('a');
    expect(reloaded.isArchived('a'), isFalse);
  });
}
