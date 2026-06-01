import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_phone_input_row.dart';

void main() {
  // Regression guard: the country dropdown used to render as a Positioned child
  // overflowing a Stack, which paints but is NOT hit-tested, so taps on list
  // items were silently dropped. It now renders via OverlayPortal.
  Future<void> pumpRow(
    WidgetTester tester, {
    required ValueChanged<String> onDialCodeChanged,
    String selected = '+31',
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                PayspinPhoneInputRow(
                  phoneController: TextEditingController(),
                  selectedDialCode: selected,
                  onDialCodeChanged: onDialCodeChanged,
                  autofocusPhone: false,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('opens the dropdown and selects a country by tap', (tester) async {
    String? picked;
    await pumpRow(tester, onDialCodeChanged: (v) => picked = v);

    // Dropdown closed initially.
    expect(find.text('Germany'), findsNothing);

    // Open it.
    await tester.tap(find.text('+31'));
    await tester.pumpAndSettle();
    expect(find.text('Germany'), findsOneWidget);

    // Tap a country — this is the interaction that was broken before.
    await tester.tap(find.text('Germany'));
    await tester.pumpAndSettle();

    expect(picked, '+49');
    // Dropdown closes after selection.
    expect(find.text('Germany'), findsNothing);
  });

  testWidgets('tapping the outside barrier dismisses the dropdown', (tester) async {
    await pumpRow(tester, onDialCodeChanged: (_) {});

    await tester.tap(find.text('+31'));
    await tester.pumpAndSettle();
    expect(find.text('Belgium'), findsOneWidget);

    // Tap far away (the full-screen barrier).
    await tester.tapAt(const Offset(20, 760));
    await tester.pumpAndSettle();
    expect(find.text('Belgium'), findsNothing);
  });
}
