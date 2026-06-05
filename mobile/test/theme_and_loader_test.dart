import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_semantic_colors.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/theme/theme_mode_controller.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_brand_mark.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_emblem_assemble.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_emblem_vector.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_emblem_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PayspinTheme semantic colors', () {
    test('dark theme registers the dark semantic palette', () {
      final colors = PayspinTheme.dark().extension<PayspinSemanticColors>();
      expect(colors, isNotNull);
      expect(colors!.bg, PayspinSemanticColors.dark.bg);
      expect(colors.emblemStyle, PayspinEmblemStyle.white);
    });

    test('light theme registers the light semantic palette', () {
      final colors = PayspinTheme.light().extension<PayspinSemanticColors>();
      expect(colors, isNotNull);
      expect(colors!.bg, PayspinSemanticColors.light.bg);
      expect(colors.emblemStyle, PayspinEmblemStyle.gradient);
    });

    testWidgets('context.psColors resolves per active theme', (tester) async {
      late PayspinSemanticColors resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: PayspinTheme.light(),
          home: Builder(
            builder: (context) {
              resolved = context.psColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved.bg, PayspinSemanticColors.light.bg);
      expect(resolved.emblemStyle, PayspinEmblemStyle.gradient);
    });
  });

  group('ThemeModeController', () {
    test('loads persisted mode and persists changes', () async {
      SharedPreferences.setMockInitialValues({'payspin_theme_mode': 'light'});
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeModeController(prefs);
      await controller.load();
      expect(controller.mode, ThemeMode.light);

      await controller.setMode(ThemeMode.dark);
      expect(controller.mode, ThemeMode.dark);
      expect(prefs.getString('payspin_theme_mode'), 'dark');
    });

    test('defaults to light when nothing stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = ThemeModeController(prefs);
      await controller.load();
      expect(controller.mode, ThemeMode.light);
    });
  });

  group('PayspinEmblemAssemble', () {
    testWidgets('arc leads loop at partial progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PayspinTheme.dark(),
          home: const Scaffold(
            body: PayspinEmblemAssemble(size: 80, progress: 0.15, style: PayspinEmblemStyle.white),
          ),
        ),
      );
      expect(find.byType(PayspinEmblemVector), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fully assembled at progress 1', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: PayspinTheme.dark(),
          home: const Scaffold(
            body: PayspinEmblemAssembleStatic(size: 80),
          ),
        ),
      );
      expect(find.byType(PayspinEmblemAssembleStatic), findsOneWidget);
    });
  });

  group('PayspinBrandMark', () {
    testWidgets('auth preset renders emblem vector', (tester) async {
      for (final theme in [PayspinTheme.light(), PayspinTheme.dark()]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(body: Center(child: PayspinBrandMark.auth())),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.byType(PayspinBrandMark), findsOneWidget);
        expect(find.byType(PayspinEmblemVector), findsWidgets);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('PayspinEmblemLoader reduced motion', () {
    Widget wrap({required bool disableAnimations}) => MaterialApp(
          theme: PayspinTheme.dark(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: const Scaffold(body: Center(child: PayspinEmblemLoader())),
          ),
        );

    Finder assembleMotion() => find.descendant(
          of: find.byType(PayspinEmblemLoader),
          matching: find.byType(AnimatedBuilder),
        );

    testWidgets('loops assemble when motion is allowed', (tester) async {
      await tester.pumpWidget(wrap(disableAnimations: false));
      expect(assembleMotion(), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 800));
      expect(tester.takeException(), isNull);
    });

    testWidgets('is static when reduced motion is requested', (tester) async {
      await tester.pumpWidget(wrap(disableAnimations: true));
      expect(assembleMotion(), findsNothing);
      expect(find.byType(PayspinEmblemVector), findsOneWidget);
    });
  });
}
