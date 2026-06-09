import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_shell_chrome.dart';

ScrollMetrics _metrics({double pixels = 0}) => FixedScrollMetrics(
      pixels: pixels,
      maxScrollExtent: 1000,
      minScrollExtent: 0,
      viewportDimension: 600,
      devicePixelRatio: 1,
      axisDirection: AxisDirection.down,
    );

ScrollUpdateNotification _update(
  BuildContext context,
  double delta, {
  double pixels = 100,
}) {
  return ScrollUpdateNotification(
    context: context,
    metrics: _metrics(pixels: pixels),
    scrollDelta: delta,
  );
}

Future<BuildContext> _testContext(WidgetTester tester) async {
  await tester.pumpWidget(const MaterialApp(home: SizedBox()));
  return tester.element(find.byType(SizedBox));
}

void main() {
  testWidgets('ShellChromeController hides on sustained scroll down', (tester) async {
    final context = await _testContext(tester);
    final c = ShellChromeController();
    expect(c.visible, isTrue);

    c.handleScrollNotification(_update(context, 5, pixels: 80));
    expect(c.visible, isTrue);

    c.handleScrollNotification(_update(context, 8, pixels: 90));
    expect(c.visible, isTrue);

    c.handleScrollNotification(_update(context, 6, pixels: 100));
    expect(c.visible, isFalse);
  });

  testWidgets('ShellChromeController shows on scroll up', (tester) async {
    final context = await _testContext(tester);
    final c = ShellChromeController()..handleScrollNotification(_update(context, 20, pixels: 100));
    expect(c.visible, isFalse);

    c.handleScrollNotification(_update(context, -16, pixels: 80));
    expect(c.visible, isTrue);
  });

  testWidgets('ShellChromeController stays visible near top', (tester) async {
    final context = await _testContext(tester);
    final c = ShellChromeController();
    c.handleScrollNotification(_update(context, 20, pixels: 10));
    expect(c.visible, isTrue);
  });

  testWidgets('ShellChromeController reset shows chrome', (tester) async {
    final context = await _testContext(tester);
    final c = ShellChromeController()..handleScrollNotification(_update(context, 20, pixels: 100));
    c.reset();
    expect(c.visible, isTrue);
  });
}
