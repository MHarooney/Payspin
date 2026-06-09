import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/storage/dismissed_recommendations_store.dart';
import 'package:payspin_mobile/presentation/home/home_dashboard_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<DismissedRecommendationsStore> store([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);
    final prefs = await SharedPreferences.getInstance();
    return DismissedRecommendationsStore(prefs);
  }

  test('dismiss persists recommendation type', () async {
    final s = await store();
    await s.dismiss(HomeRecommendation.groepies);
    expect(s.isDismissed(HomeRecommendation.groepies), isTrue);

    SharedPreferences.setMockInitialValues({
      'payspin_dismissed_recommendations': <String>['groepies'],
    });
    final prefs = await SharedPreferences.getInstance();
    final reloaded = DismissedRecommendationsStore(prefs);
    expect(reloaded.isDismissed(HomeRecommendation.groepies), isTrue);
  });
}
