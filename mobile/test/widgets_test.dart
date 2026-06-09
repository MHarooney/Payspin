import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_gradient_circle_button.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_skeleton.dart';
import 'package:payspin_mobile/core/errors/api_exception.dart';
import 'package:payspin_mobile/core/state/links_refresh_notifier.dart';
import 'package:payspin_mobile/core/state/notifications_refresh_notifier.dart';
import 'package:payspin_mobile/domain/entities/institution.dart';
import 'package:payspin_mobile/domain/entities/payment_link.dart';
import 'package:payspin_mobile/domain/repositories/auth_repository.dart';
import 'package:payspin_mobile/domain/repositories/bank_account_repository.dart';
import 'package:payspin_mobile/domain/repositories/notification_repository.dart';
import 'package:payspin_mobile/domain/repositories/onboarding_repository.dart';
import 'package:payspin_mobile/domain/repositories/payment_link_repository.dart';
import 'package:payspin_mobile/domain/usecases/complete_onboarding_usecase.dart';
import 'package:payspin_mobile/domain/usecases/validate_iban_usecase.dart';
import 'package:payspin_mobile/domain/usecases/verify_otp_usecase.dart';
import 'package:payspin_mobile/presentation/home/home_page.dart';
import 'package:payspin_mobile/presentation/links/link_detail_page.dart';
import 'package:payspin_mobile/presentation/onboarding/onboarding_cubit.dart';
import 'package:payspin_mobile/presentation/onboarding/pages/step_connect_bank_page.dart';
import 'package:payspin_mobile/presentation/notifications/notifications_page.dart';
import 'package:payspin_mobile/domain/entities/app_notification.dart';

import 'helpers/fake_repositories.dart';
import 'helpers/l10n_test_app.dart';

final _sl = GetIt.instance;

PaymentLink _link({
  String id = 'l1',
  String? description = 'Lunch',
  int? amountCents = 1500,
  String status = 'ACTIVE',
}) =>
    PaymentLink(
      id: id,
      shortCode: 'abc',
      amountCents: amountCents,
      currency: 'EUR',
      description: description,
      status: status,
      createdAt: '2026-01-01T10:00:00.000Z',
      payUrl: 'https://pay/abc',
      completedPaymentCount: 0,
      totalReceivedCents: 0,
    );

PaymentLinkDetail _detail({
  String status = 'ACTIVE',
  List<PaymentRecord> payments = const [],
}) =>
    PaymentLinkDetail(
      id: 'l1',
      shortCode: 'abc',
      amountCents: 1500,
      currency: 'EUR',
      description: 'Lunch',
      status: status,
      createdAt: '2026-01-01T10:00:00.000Z',
      payUrl: 'https://pay/abc',
      completedPaymentCount: 0,
      totalReceivedCents: 0,
      payments: payments,
    );

void main() {
  setUpAll(() {
    // Never hit the network for fonts during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() async {
    await _sl.reset();
  });

  Widget wrap(Widget child) => l10nTestApp(child);

  group('HomePage', () {
    // NOTE: empty/error states render continuous "breathing" animations
    // (PayspinRadialGlow / PayspinSkeleton), so pumpAndSettle would never
    // settle. Use bounded pumps to let the load future resolve and the first
    // frame build instead.
    Future<void> pumpHome(WidgetTester tester, FakePaymentLinkRepository repo, LinksRefreshNotifier notifier) async {
      _sl.registerSingleton<PaymentLinkRepository>(repo);
      _sl.registerSingleton<LinksRefreshNotifier>(notifier);
      _sl.registerSingleton<NotificationsRefreshNotifier>(NotificationsRefreshNotifier());
      _sl.registerSingleton<NotificationRepository>(FakeNotificationRepository());
      await tester.pumpWidget(wrap(const Scaffold(body: HomePage())));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('shows empty state when there are no links', (tester) async {
      await pumpHome(tester, FakePaymentLinkRepository(links: const []), LinksRefreshNotifier());
      expect(find.text('Time for your first Tikkie'), findsOneWidget);
    });

    testWidgets('renders a link row', (tester) async {
      await pumpHome(tester, FakePaymentLinkRepository(links: [_link()]), LinksRefreshNotifier());
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('shows an error message when listing fails', (tester) async {
      await pumpHome(
        tester,
        FakePaymentLinkRepository(listError: ApiException(500, '')),
        LinksRefreshNotifier(),
      );
      expect(find.textContaining('on our end'), findsOneWidget);
    });

    testWidgets('reloads when the refresh notifier bumps', (tester) async {
      final repo = FakePaymentLinkRepository(links: const []);
      final notifier = LinksRefreshNotifier();
      await pumpHome(tester, repo, notifier);
      expect(find.text('Time for your first Tikkie'), findsOneWidget);

      repo.links = [_link(description: 'Coffee')];
      notifier.bump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Coffee'), findsOneWidget);
      expect(repo.listCount, greaterThanOrEqualTo(2));
    });
  });

  group('LinkDetailPage', () {
    Future<void> pumpDetail(WidgetTester tester, FakePaymentLinkRepository repo) async {
      _sl.registerSingleton<PaymentLinkRepository>(repo);
      _sl.registerSingleton<LinksRefreshNotifier>(LinksRefreshNotifier());
      await tester.pumpWidget(wrap(const LinkDetailPage(linkId: 'l1')));
      await tester.pumpAndSettle();
    }

    testWidgets('renders amount and friendly payment status labels', (tester) async {
      await pumpDetail(
        tester,
        FakePaymentLinkRepository(
          detail: _detail(payments: [
            const PaymentRecord(id: 'p1', amountCents: 1500, status: 'PROCESSING', initiatedAt: '2026-01-01T11:00:00.000Z'),
          ]),
        ),
      );
      expect(find.text('€15.00'), findsWidgets);
      expect(find.text('Processing'), findsOneWidget);

      // A pending payment starts a polling timer; dispose the tree so it is
      // cancelled and flutter_test doesn't report a leaked timer.
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows cancel action for an active link', (tester) async {
      await pumpDetail(tester, FakePaymentLinkRepository(detail: _detail(status: 'ACTIVE')));
      expect(find.text('Cancel this link'), findsOneWidget);
    });

    testWidgets('hides cancel action for a settled link', (tester) async {
      await pumpDetail(tester, FakePaymentLinkRepository(detail: _detail(status: 'SETTLED')));
      expect(find.text('Cancel this link'), findsNothing);
    });

    testWidgets('surfaces an error snackbar when cancel fails', (tester) async {
      await pumpDetail(
        tester,
        FakePaymentLinkRepository(
          detail: _detail(status: 'ACTIVE'),
          cancelError: ApiException(409, ''),
        ),
      );
      await tester.tap(find.text('Cancel this link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel link'));
      await tester.pump(); // start cancel
      await tester.pump(const Duration(milliseconds: 50)); // let snackbar appear
      expect(find.textContaining('conflicts'), findsOneWidget);

      // The SnackBar schedules an auto-dismiss timer; dispose to cancel it.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('StepConnectBankPage', () {
    void registerConnectDeps(FakeBankAccountRepository bank) {
      _sl.registerSingleton<BankAccountRepository>(bank);
      _sl.registerSingleton<AuthRepository>(FakeAuthRepository());
      _sl.registerSingleton<OnboardingRepository>(FakeOnboardingRepository());
    }

    testWidgets('shows a loading skeleton while institutions load', (tester) async {
      final completer = Completer<List<Institution>>();
      registerConnectDeps(FakeBankAccountRepository(institutionsCompleter: completer));
      await tester.pumpWidget(wrap(const StepConnectBankPage()));
      await tester.pump();
      expect(find.byType(PayspinSkeleton), findsWidgets);
      completer.complete(const []);
      await tester.pumpAndSettle();
    });

    testWidgets('shows empty state when no banks are returned', (tester) async {
      registerConnectDeps(FakeBankAccountRepository(institutions: const []));
      await tester.pumpWidget(wrap(const StepConnectBankPage()));
      await tester.pumpAndSettle();
      expect(find.textContaining('No banks available'), findsOneWidget);
    });

    testWidgets('lists institutions when available', (tester) async {
      registerConnectDeps(FakeBankAccountRepository(
        institutions: const [Institution(id: 'ing', name: 'ING Bank', fullName: 'ING Bank')],
      ));
      await tester.pumpWidget(wrap(const StepConnectBankPage()));
      await tester.pumpAndSettle();
      expect(find.text('ING Bank'), findsOneWidget);
    });

    testWidgets('shows an error message when loading fails', (tester) async {
      registerConnectDeps(FakeBankAccountRepository(institutionsError: ApiException(502, '')));
      await tester.pumpWidget(wrap(const StepConnectBankPage()));
      await tester.pumpAndSettle();
      expect(find.textContaining('temporarily unavailable'), findsOneWidget);
    });
  });

  group('NotificationsPage', () {
    AppNotification _item({String id = 'n1', bool unread = true}) => AppNotification(
          id: id,
          type: 'PAYMENT_RECEIVED',
          title: 'Payment received',
          body: '€8.00 from Alex',
          data: const {'linkId': 'l1'},
          readAt: unread ? null : '2026-01-01T10:00:00.000Z',
          createdAt: '2026-01-01T10:00:00.000Z',
        );

    Future<void> pumpNotifications(WidgetTester tester, FakeNotificationRepository repo) async {
      _sl.registerSingleton<NotificationsRefreshNotifier>(NotificationsRefreshNotifier());
      _sl.registerSingleton<NotificationRepository>(repo);
      await tester.pumpWidget(wrap(const NotificationsPage()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('shows empty state when there are no notifications', (tester) async {
      await pumpNotifications(tester, FakeNotificationRepository());
      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('lists payment notifications', (tester) async {
      await pumpNotifications(
        tester,
        FakeNotificationRepository(items: [_item()], unread: 1),
      );
      expect(find.text('Payment received'), findsOneWidget);
      expect(find.text('€8.00 from Alex'), findsOneWidget);
    });

    testWidgets('shows an error message when loading fails', (tester) async {
      await pumpNotifications(
        tester,
        FakeNotificationRepository(listError: ApiException(500, '')),
      );
      expect(find.textContaining('Something went wrong on our end'), findsOneWidget);
    });
  });
}
