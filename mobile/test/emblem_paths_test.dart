import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_semantic_colors.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_emblem_paths.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_emblem_vector.dart';

void main() {
  group('PayspinEmblemPaths geometry', () {
    test('arc and loop are two distinct filled arrows, not one ring', () {
      final arc = PayspinEmblemPaths.arcFill().getBounds();
      final loop = PayspinEmblemPaths.loopFill().getBounds();

      // Both paths must have real area.
      expect(arc.width, greaterThan(10));
      expect(arc.height, greaterThan(10));
      expect(loop.width, greaterThan(10));
      expect(loop.height, greaterThan(10));

      // Arc sits upper-left, loop spans lower-right — clearly separate arrows.
      expect(arc.center.dx, lessThan(loop.center.dx));
      expect(arc.center.dy, lessThan(loop.center.dy));

      // A single ring would fill a near-square centred box; the real emblem is
      // two offset arrows, so their centres must differ noticeably.
      expect((arc.center - loop.center).distance, greaterThan(20));
    });

    test('spines are open (drawable) and traverse the arrows', () {
      for (final spine in [
        PayspinEmblemPaths.arcSpine(),
        PayspinEmblemPaths.loopSpine(),
      ]) {
        final metrics = spine.computeMetrics().toList();
        expect(metrics, isNotEmpty);
        expect(metrics.first.length, greaterThan(40));
        expect(metrics.first.isClosed, isFalse);
      }
    });

    test('scaled() maps the 0..100 box onto the requested size', () {
      final scaled = PayspinEmblemPaths.scaled(
        PayspinEmblemPaths.loopFill(),
        240,
      ).getBounds();
      expect(scaled.right, lessThanOrEqualTo(240.5));
      expect(scaled.bottom, lessThanOrEqualTo(240.5));
      expect(scaled.left, greaterThanOrEqualTo(-0.5));
    });
  });

  group('PayspinEmblemVector rendering', () {
    for (final progress in [0.0, 0.15, 0.5, 0.85, 1.0]) {
      testWidgets('renders without exception at progress $progress',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: PayspinTheme.dark(),
            home: Scaffold(
              body: Center(
                child: PayspinEmblemVector(
                  size: 120,
                  progress: progress,
                  style: PayspinEmblemStyle.gradient,
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(PayspinEmblemVector), findsOneWidget);
      });
    }
  });
}
