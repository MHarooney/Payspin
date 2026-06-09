import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_gradient_pill_button.dart';
import 'package:payspin_mobile/core/l10n/locale_controller.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:payspin_mobile/domain/entities/payment_link.dart';
import 'package:payspin_mobile/domain/repositories/bank_account_repository.dart';
import 'package:payspin_mobile/domain/repositories/payment_link_repository.dart';
import 'package:payspin_mobile/presentation/send/send_name_page.dart';

import 'helpers/fake_repositories.dart';

PaymentLink _link() => const PaymentLink(
      id: 'l1',
      shortCode: 'abc',
      currency: 'EUR',
      status: 'ACTIVE',
      createdAt: '2026-01-01T10:00:00.000Z',
      payUrl: 'https://pay/abc',
      completedPaymentCount: 0,
      totalReceivedCents: 0,
    );

Widget _router(Widget child) {
  final router = GoRouter(
    initialLocation: '/send/name',
    routes: [
      GoRoute(
        path: '/send/name',
        builder: (_, __) => child,
      ),
      GoRoute(
        path: '/links/:id',
        builder: (_, state) => Scaffold(body: Text('Detail ${state.pathParameters['id']}')),
      ),
    ],
  );
  return MaterialApp.router(
    theme: PayspinTheme.dark(),
    locale: const Locale('en'),
    supportedLocales: LocaleController.supportedLocales,
    localizationsDelegates: const [
      PayspinLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    routerConfig: router,
  );
}

void main() {
  late FakePaymentLinkRepository links;
  late FakeBankAccountRepository bank;

  setUp(() {
    links = FakePaymentLinkRepository(links: [_link()]);
    bank = FakeBankAccountRepository();
    sl.registerSingleton<PaymentLinkRepository>(links);
    sl.registerSingleton<BankAccountRepository>(bank);
  });

  tearDown(() => sl.reset());

  testWidgets('Save link is enabled without description and creates once', (tester) async {
    await tester.pumpWidget(_router(const SendNamePage(amountLabel: '€10.00', amountCents: 1000)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Save link'), findsOneWidget);

    await tester.tap(find.text('Save link'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(links.createCount, 1);
    expect(links.lastDescription, isNull);
    expect(find.text('Detail l1'), findsOneWidget);
    expect(find.text('Link saved — share anytime'), findsOneWidget);
  });

  testWidgets('WhatsApp button is enabled without description', (tester) async {
    await tester.pumpWidget(_router(const SendNamePage(amountLabel: 'Open amount', amountCents: null)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final wa = tester.widget<PayspinGradientPillButton>(
      find.byType(PayspinGradientPillButton),
    );
    expect(wa.onPressed, isNotNull);
  });
}
