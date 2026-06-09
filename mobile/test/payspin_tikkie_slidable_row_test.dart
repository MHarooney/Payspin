import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_tikkie_row.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_tikkie_slidable_row.dart';
import 'package:payspin_mobile/domain/entities/payment_link.dart';

import 'helpers/l10n_test_app.dart';

PaymentLink _settledLink() => PaymentLink(
      id: 'l1',
      shortCode: 'abc',
      amountCents: null,
      currency: 'EUR',
      description: 'night life',
      status: 'SETTLED',
      createdAt: '2026-06-08T10:00:00.000Z',
      payUrl: 'https://pay.test/abc',
      completedPaymentCount: 1,
      totalReceivedCents: 0,
    );

PaymentLink _activeLink() => PaymentLink(
      id: 'l2',
      shortCode: 'def',
      amountCents: 53000,
      currency: 'EUR',
      description: 'club',
      status: 'ACTIVE',
      createdAt: '2026-06-08T10:00:00.000Z',
      payUrl: 'https://pay.test/def',
      completedPaymentCount: 0,
      totalReceivedCents: 0,
    );

Widget _wrap(Widget child) => l10nTestApp(
      Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );

void main() {
  testWidgets('action dock is hidden at rest', (tester) async {
    await tester.pumpWidget(
      _wrap(
        PayspinTikkieSlidableRow(
          link: _settledLink(),
          isOpen: false,
          onOpenChanged: (_) {},
          onArchive: () {},
          onMore: () {},
          archiveLabel: 'Hide',
          moreLabel: 'More',
          builder: (progress) => PayspinTikkieRow(
            link: _settledLink(),
            onTap: () {},
            useOpaqueSwipeBacking: true,
            swipeRevealProgress: progress,
          ),
        ),
      ),
    );
    await tester.pump();

    final dockOpacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(PayspinTikkieSlidableRow),
        matching: find.byType(Opacity).first,
      ),
    );
    expect(dockOpacity.opacity, 0);
  });

  testWidgets('swipe reveals action labels', (tester) async {
    var open = false;
    await tester.pumpWidget(
      _wrap(
        PayspinTikkieSlidableRow(
          link: _settledLink(),
          isOpen: open,
          onOpenChanged: (v) => open = v,
          onArchive: () {},
          onMore: () {},
          archiveLabel: 'Hide',
          moreLabel: 'More',
          builder: (progress) => PayspinTikkieRow(
            link: _settledLink(),
            onTap: () {},
            useOpaqueSwipeBacking: true,
            swipeRevealProgress: progress,
          ),
        ),
      ),
    );
    await tester.pump();

    final slidable = find.byType(PayspinTikkieSlidableRow);
    final box = tester.getRect(slidable);
    final start = Offset(box.right - 20, box.center.dy);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(-200, 0));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Hide'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);
  });

  testWidgets('open amount fades while peeling', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        PayspinTikkieRow(
          link: _settledLink(),
          onTap: () {},
          useOpaqueSwipeBacking: true,
          swipeRevealProgress: 1,
        ),
      ),
    );
    await tester.pump();

    final amountOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Open amount'),
        matching: find.byType(Opacity),
      ),
    );
    expect(amountOpacity.opacity, lessThan(0.3));
  });

  testWidgets('active link shows cancel action when open', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        PayspinTikkieSlidableRow(
          link: _activeLink(),
          isOpen: true,
          onOpenChanged: (_) {},
          onCancel: () {},
          onMore: () {},
          cancelLabel: 'Cancel link',
          moreLabel: 'More',
          builder: (progress) => PayspinTikkieRow(
            link: _activeLink(),
            onTap: () {},
            useOpaqueSwipeBacking: true,
            swipeRevealProgress: progress,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Cancel link'), findsOneWidget);
  });
}
