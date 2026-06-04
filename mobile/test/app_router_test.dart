import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/app/app.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  testWidgets('cold start shows the splash then routes to welcome', (tester) async {
    await tester.pumpWidget(PayspinApp());
    await tester.pump(); // splash first frame
    expect(find.text('Payspin'), findsWidgets); // brand splash on screen

    // No persisted onboarding progress and no stored session → after the
    // storage checks and the minimum on-screen duration, the splash routes on
    // to Welcome. Use fixed pumps (not pumpAndSettle): the splash glow animates
    // forever. Pump past the keychain read timeout used by the session check so
    // no secure-storage timer is left pending when the tree is torn down.
    await tester.pump(const Duration(milliseconds: 100)); // onboarding store check
    await tester.pump(const Duration(seconds: 2)); // minimum splash + session check
    await tester.pump(const Duration(seconds: 2)); // let the keychain read settle
    await tester.pump(const Duration(milliseconds: 500)); // build Welcome

    expect(find.text('Get started'), findsOneWidget);
  });
}
