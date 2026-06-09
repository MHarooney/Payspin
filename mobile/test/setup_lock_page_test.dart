import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/presentation/security/setup_lock_page.dart';

Future<void> _pumpSetup(WidgetTester tester, {String? displayName}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: PayspinTheme.dark(),
      home: SetupLockPage(displayName: displayName),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  testWidgets('create phase title, journey rail, and keypad render', (tester) async {
    await _pumpSetup(tester);

    expect(find.text('Create a passcode'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Set up later'), findsOneWidget);
    for (final d in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('personalized subtitle when displayName is provided', (tester) async {
    await _pumpSetup(tester, displayName: 'Alex');

    expect(
      find.text('Hi Alex — add a 6-digit passcode to keep Payspin secure.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
