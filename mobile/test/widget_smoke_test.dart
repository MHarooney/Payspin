import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_gradient_pill_button.dart';
import 'package:payspin_mobile/presentation/welcome/welcome_page.dart';

void main() {
  testWidgets('welcome shows Get started', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PayspinTheme.dark(),
        home: const WelcomePage(),
      ),
    );
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Payspin'), findsOneWidget);
  });

  testWidgets('gradient pill button renders label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PayspinGradientPillButton(label: 'Go to Home', onPressed: () {}),
        ),
      ),
    );
    expect(find.text('Go to Home'), findsOneWidget);
  });
}
