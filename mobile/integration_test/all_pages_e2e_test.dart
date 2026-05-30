import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:payspin_mobile/app/app.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:payspin_mobile/app/router.dart';

/// E2E user from scripts/dev/e2e-register-iban-link.sh (re-run script for fresh creds).
const _e2eEmail = 'e2e-1779735070@payspin.test';
const _e2ePassword = 'E2eTestPass123!';
const _e2eLinkId = 'b00c4425-0e56-479b-9a02-5436668dfa1e';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late GoRouter router;

  setUpAll(() async {
    await configureDependencies();
    router = createRouter();
  });

  Future<void> pumpRoute(WidgetTester tester, String location) async {
    router.go(location);
    await tester.pumpWidget(PayspinApp(router: router));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  testWidgets('welcome page', (tester) async {
    await pumpRoute(tester, '/welcome');
    expect(find.text('Get started'), findsOneWidget);
    expect(find.textContaining('Log in'), findsOneWidget);
    expect(find.text('Payspin'), findsWidgets);
  });

  testWidgets('login page', (tester) async {
    await pumpRoute(tester, '/login');
    expect(find.text('Log In'), findsOneWidget);
    expect(find.textContaining('Log in'), findsOneWidget);
  });

  testWidgets('login → home with E2E user', (tester) async {
    await pumpRoute(tester, '/login');
    await tester.enterText(find.byType(TextField).at(0), _e2eEmail);
    await tester.enterText(find.byType(TextField).at(1), _e2ePassword);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.text('Tikkies'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('home tabs: Deals and Groepies', (tester) async {
    await pumpRoute(tester, '/login');
    await tester.enterText(find.byType(TextField).at(0), _e2eEmail);
    await tester.enterText(find.byType(TextField).at(1), _e2ePassword);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await tester.tap(find.text('Deals'));
    await tester.pumpAndSettle();
    expect(find.text('Deals — coming soon'), findsOneWidget);

    await tester.tap(find.text('Groepies'));
    await tester.pumpAndSettle();
    expect(find.text('Track Group Expenses?'), findsOneWidget);
  });

  testWidgets('profile page', (tester) async {
    await pumpRoute(tester, '/login');
    await tester.enterText(find.byType(TextField).at(0), _e2eEmail);
    await tester.enterText(find.byType(TextField).at(1), _e2ePassword);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('LINKED IBAN'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('send amount page', (tester) async {
    await pumpRoute(tester, '/login');
    await tester.enterText(find.byType(TextField).at(0), _e2eEmail);
    await tester.enterText(find.byType(TextField).at(1), _e2ePassword);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle(const Duration(seconds: 8));

    router.go('/send/amount');
    await tester.pumpAndSettle();
    expect(find.text("What's the amount?"), findsOneWidget);
  });

  testWidgets('send name page', (tester) async {
    await pumpRoute(tester, '/login');
    await tester.enterText(find.byType(TextField).at(0), _e2eEmail);
    await tester.enterText(find.byType(TextField).at(1), _e2ePassword);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle(const Duration(seconds: 8));

    router.go('/send/name', extra: {'cents': 2500, 'amountLabel': '€25.00'});
    await tester.pumpAndSettle();
    expect(find.text('What is it for?'), findsOneWidget);
  });

  testWidgets('scan QR page', (tester) async {
    await pumpRoute(tester, '/login');
    await tester.enterText(find.byType(TextField).at(0), _e2eEmail);
    await tester.enterText(find.byType(TextField).at(1), _e2ePassword);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await tester.tap(find.text('Scan QR'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Scan a Payspin QR code'), findsOneWidget);
    await tester.tap(find.text('OK, nice!'));
    await tester.pumpAndSettle();
  });

  testWidgets('link detail page', (tester) async {
    await pumpRoute(tester, '/login');
    await tester.enterText(find.byType(TextField).at(0), _e2eEmail);
    await tester.enterText(find.byType(TextField).at(1), _e2ePassword);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle(const Duration(seconds: 8));

    router.go('/links/$_e2eLinkId');
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('E2E coffee'), findsOneWidget);
  });

  testWidgets('onboarding steps render', (tester) async {
    final steps = <String, String>{
      '/onboarding/name': 'What should we call you?',
      '/onboarding/phone': 'Enter your phone number',
      '/onboarding/otp': 'Enter the code',
      '/onboarding/credentials': 'Create your account',
      '/onboarding/iban': 'Which IBAN do you want',
      '/onboarding/full-name': 'first and',
      '/onboarding/success': 'Nice!',
    };
    for (final entry in steps.entries) {
      await pumpRoute(tester, entry.key);
      expect(find.textContaining(entry.value), findsWidgets);
    }
  });
}
