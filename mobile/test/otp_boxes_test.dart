import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_otp_boxes.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: PayspinTheme.dark(), home: Scaffold(body: child));

  testWidgets('fills cells and calls onCompleted', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? completed;

    await tester.pumpWidget(
      wrap(
        PayspinOtpBoxes(
          controller: controller,
          autofocus: true,
          onCompleted: (v) => completed = v,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump(const Duration(milliseconds: 500));

    expect(completed, '123456');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows error state without crashing', (tester) async {
    final controller = TextEditingController();

    await tester.pumpWidget(
      wrap(
        PayspinOtpBoxes(controller: controller, hasError: true),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      wrap(
        PayspinOtpBoxes(controller: controller, hasError: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.takeException(), isNull);
  });

  testWidgets('resend button counts down', (tester) async {
    await tester.pumpWidget(
      wrap(
        PayspinOtpResendButton(secondsRemaining: 45, onPressed: () {}),
      ),
    );
    expect(find.textContaining('(45s)'), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        PayspinOtpResendButton(secondsRemaining: 0, onPressed: () {}),
      ),
    );
    expect(find.text('Resend code'), findsOneWidget);
  });
}
