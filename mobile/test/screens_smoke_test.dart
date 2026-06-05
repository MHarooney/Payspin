import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:payspin_mobile/core/l10n/locale_controller.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:payspin_mobile/app/app.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:payspin_mobile/app/router.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/presentation/auth/login_page.dart';
import 'package:payspin_mobile/presentation/circles/create_circle_page.dart';
import 'package:payspin_mobile/presentation/circles/join_circle_page.dart';
import 'package:payspin_mobile/presentation/notifications/notifications_page.dart';
import 'package:payspin_mobile/presentation/onboarding/pages/step_connect_bank_page.dart';
import 'package:payspin_mobile/presentation/onboarding/pages/step_full_name_page.dart';
import 'package:payspin_mobile/presentation/onboarding/pages/step_iban_page.dart';
import 'package:payspin_mobile/presentation/onboarding/pages/step_name_page.dart';
import 'package:payspin_mobile/presentation/onboarding/pages/step_otp_page.dart';
import 'package:payspin_mobile/presentation/onboarding/pages/step_phone_page.dart';
import 'package:payspin_mobile/presentation/onboarding/pages/success_page.dart';
import 'package:payspin_mobile/presentation/scan/scan_qr_page.dart';
import 'package:payspin_mobile/presentation/send/send_amount_page.dart';
import 'package:payspin_mobile/presentation/send/send_name_page.dart';
import 'package:payspin_mobile/presentation/welcome/welcome_page.dart';

/// Pumps a route via go_router — no auth required for welcome/login/onboarding.
Future<void> pumpRoute(WidgetTester tester, GoRouter router, String location) async {
  router.go(location);
  await tester.pumpWidget(PayspinApp(router: router));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Widget _themed(Widget child) => MaterialApp(
      theme: PayspinTheme.dark(),
      locale: const Locale('en'),
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        PayspinLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

void main() {
  late GoRouter router;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  setUp(() {
    router = createRouter();
  });

  group('router screens (no session)', () {
    testWidgets('welcome', (tester) async {
      await pumpRoute(tester, router, '/welcome');
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('login', (tester) async {
      await pumpRoute(tester, router, '/login');
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('onboarding name — underline field renders', (tester) async {
      await pumpRoute(tester, router, '/onboarding/name');
      expect(find.text('What should we call you?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding phone', (tester) async {
      await pumpRoute(tester, router, '/onboarding/phone');
      expect(find.byType(TextField), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding otp', (tester) async {
      await pumpRoute(tester, router, '/onboarding/otp');
      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding connect bank', (tester) async {
      await pumpRoute(tester, router, '/onboarding/connect');
      // Drain secure-storage read timeout started in initState.
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding iban', (tester) async {
      await pumpRoute(tester, router, '/onboarding/iban');
      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding full name', (tester) async {
      await pumpRoute(tester, router, '/onboarding/full-name');
      expect(tester.takeException(), isNull);
    });

    testWidgets('onboarding success', (tester) async {
      await pumpRoute(tester, router, '/onboarding/success');
      expect(find.text('Nice!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('standalone pages (direct pump)', () {
    testWidgets('send amount', (tester) async {
      await tester.pumpWidget(_themed(const SendAmountPage()));
      await tester.pump();
      expect(find.textContaining('amount'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('send name', (tester) async {
      await tester.pumpWidget(
        _themed(const SendNamePage(amountLabel: '€10.00', amountCents: 1000)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('scan qr', (tester) async {
      await tester.pumpWidget(_themed(const ScanQrPage()));
      await tester.pump();
      expect(find.textContaining('Scan'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('notifications', (tester) async {
      await tester.pumpWidget(_themed(const NotificationsPage()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('create circle', (tester) async {
      await tester.pumpWidget(_themed(const CreateCirclePage()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('join circle', (tester) async {
      await tester.pumpWidget(_themed(const JoinCirclePage()));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('welcome direct', (tester) async {
      await tester.pumpWidget(_themed(const WelcomePage()));
      await tester.pump();
      expect(find.text('Get started'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('login direct', (tester) async {
      await tester.pumpWidget(_themed(const LoginPage()));
      await tester.pump();
      expect(find.text('Log In'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
