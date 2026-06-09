import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_confirm_dialog.dart';

Widget _host(Widget child) {
  return MaterialApp(
    theme: PayspinTheme.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('renders title, message, and action labels', (tester) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showPayspinConfirmDialog(
                context,
                title: 'Log out?',
                message: 'You can sign back in anytime.',
                confirmLabel: 'Log out',
                destructive: true,
                icon: Icons.logout,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    expect(find.text('Log out?'), findsOneWidget);
    expect(find.text('You can sign back in anytime.'), findsOneWidget);
    expect(find.text('Log out'), findsWidgets);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Cancel returns false', (tester) async {
    bool? result;

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showPayspinConfirmDialog(
                  context,
                  title: 'Remove this IBAN?',
                  message: 'It will be removed from your account.',
                  confirmLabel: 'Remove',
                  destructive: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('Confirm returns true', (tester) async {
    bool? result;

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showPayspinConfirmDialog(
                  context,
                  title: 'Delete link?',
                  message: 'This cannot be undone.',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
