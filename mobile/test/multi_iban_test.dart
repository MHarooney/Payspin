import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_iban_tile.dart';
import 'package:payspin_mobile/domain/entities/bank_account.dart';
import 'package:payspin_mobile/domain/entities/payment_link.dart';
import 'package:payspin_mobile/domain/repositories/bank_account_repository.dart';
import 'package:payspin_mobile/domain/repositories/payment_link_repository.dart';
import 'package:payspin_mobile/presentation/send/send_name_page.dart';

import 'helpers/fake_repositories.dart';

Widget _themed(Widget child) => MaterialApp(theme: PayspinTheme.dark(), home: child);

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

BankAccount _acc(String id, String last4, {bool primary = false}) =>
    BankAccount(id: id, ibanLast4: last4, accountHolder: 'Holder $last4', verified: true, isPrimary: primary);

void main() {
  group('PayspinIbanTile', () {
    testWidgets('shows the masked IBAN and a Primary badge', (tester) async {
      await tester.pumpWidget(_themed(
        const PayspinIbanTile(ibanLast4: '1234', accountHolder: 'Jane', isPrimary: true),
      ));
      expect(find.text('•••• 1234'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
    });

    testWidgets('shows a radio when in picker mode and fires onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_themed(
        PayspinIbanTile(
          ibanLast4: '9999',
          accountHolder: 'Jane',
          selected: true,
          onTap: () => tapped = true,
        ),
      ));
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      await tester.tap(find.byType(PayspinIbanTile));
      expect(tapped, isTrue);
    });
  });

  group('Send IBAN picker', () {
    late FakeBankAccountRepository bank;
    late FakePaymentLinkRepository links;

    setUp(() {
      bank = FakeBankAccountRepository();
      links = FakePaymentLinkRepository(links: [_link()]);
      sl.registerSingleton<BankAccountRepository>(bank);
      sl.registerSingleton<PaymentLinkRepository>(links);
    });

    tearDown(() => sl.reset());

    testWidgets('hides the selector when the user has a single IBAN', (tester) async {
      bank.accounts = [_acc('ba1', '1111', primary: true)];
      await tester.pumpWidget(_themed(const SendNamePage(amountLabel: '€10.00', amountCents: 1000)));
      await tester.pumpAndSettle();
      expect(find.text('Pay into'), findsNothing);
    });

    testWidgets('shows the selector and switches the chosen IBAN when >1', (tester) async {
      bank.accounts = [_acc('ba1', '1111', primary: true), _acc('ba2', '2222')];
      await tester.pumpWidget(_themed(const SendNamePage(amountLabel: '€10.00', amountCents: 1000)));
      await tester.pumpAndSettle();

      // Primary IBAN is preselected in the inline selector.
      expect(find.text('Pay into'), findsOneWidget);
      expect(find.text('•••• 1111'), findsOneWidget);

      // Open the picker sheet and choose the second account.
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('•••• 2222'));
      await tester.pumpAndSettle();

      expect(find.text('•••• 2222'), findsOneWidget);
    });
  });
}
