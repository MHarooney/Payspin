import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/l10n/locale_controller.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:payspin_mobile/domain/entities/payment_link.dart';
import 'package:payspin_mobile/presentation/home/home_dashboard_data.dart';
import 'package:payspin_mobile/presentation/send/request_again_flow.dart';
import 'package:payspin_mobile/presentation/send/send_name_page.dart';

PaymentLink _link({
  required String id,
  String status = 'ACTIVE',
  int? amountCents = 1000,
  String? description,
  String createdAt = '2026-06-09T10:00:00.000Z',
}) {
  return PaymentLink(
    id: id,
    shortCode: id,
    amountCents: amountCents,
    currency: 'EUR',
    description: description,
    status: status,
    createdAt: createdAt,
    payUrl: 'https://pay/$id',
    completedPaymentCount: 0,
    totalReceivedCents: 0,
  );
}

void main() {
  group('PaymentLink.canRequestAgain', () {
    test('true for CANCELLED, SETTLED, EXPIRED', () {
      expect(_link(id: 'c', status: 'CANCELLED').canRequestAgain, isTrue);
      expect(_link(id: 's', status: 'SETTLED').canRequestAgain, isTrue);
      expect(_link(id: 'e', status: 'EXPIRED').canRequestAgain, isTrue);
    });

    test('false for ACTIVE and COLLECTING', () {
      expect(_link(id: 'a', status: 'ACTIVE').canRequestAgain, isFalse);
      expect(_link(id: 'col', status: 'COLLECTING').canRequestAgain, isFalse);
    });
  });

  group('HomeDashboard requestAgainSource', () {
    final now = DateTime(2026, 6, 9);

    test('picks newest cancelled link with description', () {
      final d = HomeDashboard.from([
        _link(id: 'old', status: 'CANCELLED', description: 'Dinner', createdAt: '2026-06-01T10:00:00.000Z'),
        _link(id: 'new', status: 'CANCELLED', description: 'Vacation', createdAt: '2026-06-08T10:00:00.000Z'),
      ], const {}, now: now);
      expect(d.requestAgainSource?.id, 'new');
      expect(d.recommended.contains(HomeRecommendation.requestAgain), isTrue);
    });

    test('includes expired link with fixed amount', () {
      final d = HomeDashboard.from([
        _link(id: 'exp', status: 'EXPIRED', amountCents: 5000, description: null),
      ], const {}, now: now);
      expect(d.requestAgainSource?.id, 'exp');
    });
  });

  group('RequestAgainFlow', () {
    testWidgets('prefills send name from closed link', (tester) async {
      final closed = _link(id: 'x', status: 'CANCELLED', amountCents: 2000, description: 'Theater');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, _) => Scaffold(
              body: ElevatedButton(
                onPressed: () => RequestAgainFlow.launch(ctx, closed),
                child: const Text('Retry'),
              ),
            ),
          ),
          GoRoute(
            path: '/send/name',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return SendNamePage(
                amountCents: extra['cents'] as int?,
                amountLabel: extra['amountLabel'] as String? ?? '—',
                initialDescription: extra['initialDescription'] as String? ?? '',
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(
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
      ));
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Theater'), findsOneWidget);
      expect(find.textContaining('€20.00'), findsOneWidget);
    });
  });
}
