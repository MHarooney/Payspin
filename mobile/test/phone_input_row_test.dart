import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_phone_input_row.dart';

void main() {
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

  testWidgets('opens the country sheet and selects a country by tap', (tester) async {
    String? picked;
    await pumpRow(tester, onDialCodeChanged: (v) => picked = v);

    expect(find.text('Germany'), findsNothing);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Germany'), findsOneWidget);

    await tester.tap(find.text('Germany'));
    await tester.pumpAndSettle();

    expect(picked, '+49');
    expect(find.text('Germany'), findsNothing);
  });

  testWidgets('tapping the outside barrier dismisses the sheet', (tester) async {
    await pumpRow(tester, onDialCodeChanged: (_) {});

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Belgium'), findsOneWidget);

    await tester.tapAt(const Offset(20, 40));
    await tester.pumpAndSettle();
    expect(find.text('Belgium'), findsNothing);
  });

  Finder searchField() => find.ancestor(
        of: find.byIcon(Icons.search_rounded),
        matching: find.byType(TextField),
      );

  testWidgets('search filters the country list by name', (tester) async {
    await pumpRow(tester, onDialCodeChanged: (_) {});

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Germany'), findsOneWidget);

    await tester.enterText(searchField(), 'egypt');
    await tester.pumpAndSettle();

    expect(find.text('Egypt'), findsOneWidget);
    expect(find.text('Germany'), findsNothing);
  });

  testWidgets('search by dial code, then selecting updates the code', (tester) async {
    String? picked;
    await pumpRow(tester, onDialCodeChanged: (v) => picked = v);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(searchField(), '+20');
    await tester.pumpAndSettle();
    expect(find.text('Egypt'), findsOneWidget);

    await tester.tap(find.text('Egypt'));
    await tester.pumpAndSettle();
    expect(picked, '+20');
  });

  testWidgets('shows an empty state when nothing matches', (tester) async {
    await pumpRow(tester, onDialCodeChanged: (_) {});

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    await tester.enterText(searchField(), 'zzzzz');
    await tester.pumpAndSettle();

    expect(find.text('No countries found'), findsOneWidget);
  });

  test('E.164 preview formatting', () {
    expect(formatPhoneE164Preview('+31', '612345678'), '+31 612 345 678');
    expect(isPhoneDigitsValid('+31', '612345678'), isTrue);
    expect(isPhoneDigitsValid('+31', '612'), isFalse);
  });
}
