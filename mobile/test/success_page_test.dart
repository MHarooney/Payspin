import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payspin_mobile/app/app.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:payspin_mobile/app/router.dart';

Future<void> _pumpSuccess(WidgetTester tester) async {
  final router = createRouter();
  router.go('/onboarding/success');
  await tester.pumpWidget(PayspinApp(router: router));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 2500));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  testWidgets('celebration copy and CTA render after timeline', (tester) async {
    await _pumpSuccess(tester);

    expect(find.text('Nice!'), findsOneWidget);
    expect(find.text('You can now use'), findsOneWidget);
    expect(find.text('Secure your account'), findsOneWidget);
    expect(find.text('Welcome aboard. Send and request payments in seconds.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
