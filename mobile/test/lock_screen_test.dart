import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payspin_mobile/core/security/app_lock_service.dart';
import 'package:payspin_mobile/presentation/security/lock_screen.dart';

class _MockService extends Mock implements AppLockService {}

void main() {
  late _MockService service;

  setUp(() {
    service = _MockService();
    // No biometrics enrolled → keypad-only flow, no auto-prompt.
    when(() => service.capability()).thenAnswer((_) async => LockCapability.empty);
    when(() => service.isBiometricEnabled()).thenAnswer((_) async => false);
    when(() => service.displayName()).thenAnswer((_) async => 'Mahmoud');
  });

  Future<void> pumpLock(
    WidgetTester tester, {
    required VoidCallback onUnlocked,
    VoidCallback? onForgot,
  }) async {
    // Use a realistic phone surface so the keypad/CTA don't overflow the
    // default 800x600 test window.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: LockScreen(
        service: service,
        onUnlocked: onUnlocked,
        onForgot: onForgot ?? () {},
      ),
    ));
    await tester.pump();
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    for (final d in code.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
  }

  testWidgets('renders welcome + name and the passcode keypad', (tester) async {
    await pumpLock(tester, onUnlocked: () {});
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Mahmoud'), findsOneWidget);
    for (final d in ['1', '5', '9', '0']) {
      expect(find.text(d), findsOneWidget);
    }
  });

  testWidgets('unlocks when the correct passcode is entered', (tester) async {
    when(() => service.verifyPin('246810')).thenAnswer((_) async => true);
    var unlocked = false;
    await pumpLock(tester, onUnlocked: () => unlocked = true);

    await enterCode(tester, '246810');
    await tester.pumpAndSettle();

    expect(unlocked, isTrue);
    verify(() => service.verifyPin('246810')).called(1);
  });

  testWidgets('rejects a wrong passcode and clears for retry', (tester) async {
    when(() => service.verifyPin(any())).thenAnswer((_) async => false);
    var unlocked = false;
    await pumpLock(tester, onUnlocked: () => unlocked = true);

    await enterCode(tester, '000000');
    await tester.pump(const Duration(milliseconds: 600));

    expect(unlocked, isFalse);
    // Field reset: re-entering must be possible.
    await enterCode(tester, '1');
    await tester.pump();
    verify(() => service.verifyPin('000000')).called(1);
  });

  testWidgets('forgot passcode invokes the host callback', (tester) async {
    var forgot = false;
    await pumpLock(tester, onUnlocked: () {}, onForgot: () => forgot = true);

    await tester.tap(find.text('Forgot your passcode?'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out & reset'));
    await tester.pumpAndSettle();
    expect(forgot, isTrue);
  });
}
