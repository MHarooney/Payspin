import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_brand_mark.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_gradient_pill_button.dart';
import 'package:payspin_mobile/presentation/welcome/welcome_page.dart';

import 'helpers/l10n_test_app.dart';

void main() {
  testWidgets('welcome shows Get started', (tester) async {
    await tester.pumpWidget(
      l10nTestApp(const WelcomePage(), theme: PayspinTheme.dark()),
    );
    await tester.pump();
    expect(find.text('Get started'), findsOneWidget);
    expect(find.byType(PayspinBrandMark), findsOneWidget);
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
