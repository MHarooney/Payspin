import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_link_shortcut_button.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_tikkie_row.dart';
import 'package:payspin_mobile/domain/entities/payment_link.dart';

import 'helpers/l10n_test_app.dart';

PaymentLink _link({String status = 'ACTIVE'}) => PaymentLink(
      id: 'l1',
      shortCode: 'abc',
      amountCents: 1500,
      currency: 'EUR',
      description: 'Lunch',
      status: status,
      createdAt: '2026-06-08T10:00:00.000Z',
      payUrl: 'https://pay.test/abc',
      completedPaymentCount: 0,
      totalReceivedCents: 0,
    );

void main() {
  testWidgets('copy shortcut triggers onCopy without onTap', (tester) async {
    var tapped = false;
    var copied = false;

    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: PayspinTikkieRow(
            link: _link(),
            onTap: () => tapped = true,
            onCopy: () => copied = true,
            onShare: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PayspinLinkCopyButton));
    await tester.pump();

    expect(copied, isTrue);
    expect(tapped, isFalse);
  });

  testWidgets('share shortcut triggers onShare without onTap', (tester) async {
    var tapped = false;
    var shared = false;

    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: PayspinTikkieRow(
            link: _link(),
            onTap: () => tapped = true,
            onCopy: () {},
            onShare: () => shared = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PayspinLinkSharePill));
    await tester.pump();

    expect(shared, isTrue);
    expect(tapped, isFalse);
  });

  testWidgets('disabled share calls onShareDisabled for settled links', (tester) async {
    var disabled = false;

    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: PayspinTikkieRow(
            link: _link(status: 'SETTLED'),
            onTap: () {},
            onCopy: () {},
            onShare: () {},
            onShareDisabled: () => disabled = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PayspinLinkSharePill));
    await tester.pump();

    expect(disabled, isTrue);
  });
}
