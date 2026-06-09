import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_peel_reveal.dart';

import 'helpers/l10n_test_app.dart';

void main() {
  Widget wrap(Widget child) => l10nTestApp(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      );

  testWidgets('dock hidden at rest for dismiss peel', (tester) async {
    await tester.pumpWidget(
      wrap(
        PayspinPeelReveal(
          peelId: 'rec:groepies',
          isOpen: false,
          onOpenChanged: (_) {},
          actions: const [
            PeelRevealAction(
              icon: Icons.close_rounded,
              label: 'Dismiss',
              kind: PeelActionKind.dismiss,
              onTap: _noop,
            ),
          ],
          builder: (_) => const SizedBox(height: 72, child: Text('Promo')),
        ),
      ),
    );
    await tester.pump();

    final dockOpacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byType(PayspinPeelReveal),
        matching: find.byType(Opacity).first,
      ),
    );
    expect(dockOpacity.opacity, 0);
  });

  testWidgets('swipe reveals dismiss label', (tester) async {
    await tester.pumpWidget(
      wrap(
        PayspinPeelReveal(
          peelId: 'rec:groepies',
          isOpen: false,
          onOpenChanged: (_) {},
          actions: const [
            PeelRevealAction(
              icon: Icons.close_rounded,
              label: 'Dismiss',
              kind: PeelActionKind.dismiss,
              onTap: _noop,
            ),
          ],
          builder: (_) => const SizedBox(height: 72, child: Text('Promo')),
        ),
      ),
    );
    await tester.pump();

    final box = tester.getRect(find.byType(PayspinPeelReveal));
    final gesture = await tester.startGesture(Offset(box.right - 20, box.center.dy));
    await gesture.moveBy(const Offset(-120, 0));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dismiss'), findsOneWidget);
  });
}

void _noop() {}
