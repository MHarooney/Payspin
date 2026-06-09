import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:payspin_mobile/core/security/app_lock_service.dart';
import 'package:payspin_mobile/domain/repositories/auth_repository.dart';
import 'package:payspin_mobile/presentation/security/lock_screen.dart';

import 'helpers/fake_repositories.dart';

class _MockService extends Mock implements AppLockService {}

void main() {
  late _MockService service;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  setUp(() async {
    service = _MockService();
    when(() => service.capability()).thenAnswer((_) async => LockCapability.empty);
    when(() => service.isBiometricEnabled()).thenAnswer((_) async => false);
    when(() => service.displayName()).thenAnswer((_) async => 'Mahmoud AlHaroon');
    if (sl.isRegistered<AuthRepository>()) await sl.unregister<AuthRepository>();
    sl.registerSingleton<AuthRepository>(FakeAuthRepository());
  });

  Future<void> pumpLock(
    WidgetTester tester, {
    required VoidCallback onUnlocked,
    VoidCallback? onPasscodeReset,
    VoidCallback? onSignOutFallback,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        PayspinLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Navigator(
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => LockScreen(
            service: service,
            onUnlocked: onUnlocked,
            onPasscodeReset: onPasscodeReset ?? () {},
            onSignOutFallback: onSignOutFallback ?? () {},
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    for (final d in code.split('')) {
      await tester.tap(find.text(d));
      await tester.pump();
    }
  }

  testWidgets('renders welcome, hero, name, and passcode keypad', (tester) async {
    await pumpLock(tester, onUnlocked: () {});
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Mahmoud'), findsOneWidget);
    expect(find.text('Mahmoud AlHaroon'), findsOneWidget);
    expect(find.text('Forgot your passcode?'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    for (final d in ['1', '5', '9', '0']) {
      expect(find.text(d), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('unlocks when the correct passcode is entered', (tester) async {
    when(() => service.verifyPin('246810')).thenAnswer((_) async => true);
    var unlocked = false;
    await pumpLock(tester, onUnlocked: () => unlocked = true);

    await enterCode(tester, '246810');
    await tester.pump(const Duration(milliseconds: 300));

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
    await enterCode(tester, '1');
    await tester.pump();
    verify(() => service.verifyPin('000000')).called(1);
  });

  testWidgets('forgot passcode opens reset flow', (tester) async {
    await pumpLock(tester, onUnlocked: () {});

    await tester.tap(find.text('Forgot your passcode?'));
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Verify your identity'), findsOneWidget);
    expect(find.text('Contact support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
