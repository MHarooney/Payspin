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

    // No persisted onboarding progress → after the storage check and the
    // minimum on-screen duration, the splash routes on to Welcome. Use fixed
    // pumps (not pumpAndSettle): the splash glow animates forever.
    await tester.pump(const Duration(milliseconds: 100)); // storage check
    await tester.pump(const Duration(seconds: 2)); // minimum splash duration
    await tester.pump(const Duration(milliseconds: 500)); // build Welcome

    expect(find.text('Get started'), findsOneWidget);
  });
}
