import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/l10n/locale_controller.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:payspin_mobile/presentation/intro/payspin_intro_flow.dart';
import 'package:payspin_mobile/presentation/intro/scenes/intro_scene_1_bill_to_links.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      theme: PayspinTheme.dark(),
      locale: locale,
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        PayspinLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

void main() {
  group('intro scene localization', () {
    for (final code in ['en', 'nl', 'de', 'ar']) {
      test('all 5 scenes have title + body in $code', () {
        final l10n = PayspinLocalizations(Locale(code));
        for (var i = 1; i <= PayspinIntroFlow.sceneCount; i++) {
          expect(l10n.introSceneTitle(i).trim(), isNotEmpty);
          expect(l10n.introSceneBody(i).trim(), isNotEmpty);
        }
        for (var i = 0; i < 4; i++) {
          expect(l10n.introValueWord(i).trim(), isNotEmpty);
        }
        expect(l10n.introSkip.trim(), isNotEmpty);
        expect(l10n.introGetStarted.trim(), isNotEmpty);
      });
    }
  });

  group('PayspinIntroFlow widget', () {
    testWidgets('shows scene 1 copy, skip, and advances on Next', (tester) async {
      // Reduced motion → scenes render static frames (no infinite tickers).
      await tester.pumpWidget(
        _app(const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: PayspinIntroFlow(),
        )),
      );
      await tester.pump();

      const l10n = PayspinLocalizations(Locale('en'));
      expect(find.text(l10n.introSceneTitle(1)), findsOneWidget);
      expect(find.text(l10n.introSkip), findsOneWidget);
      expect(find.text(l10n.introNext), findsOneWidget);

      await tester.tap(find.text(l10n.introNext));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(l10n.introSceneTitle(2)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scene 1 animation keeps opacity in valid range', (tester) async {
      await tester.pumpWidget(
        _app(const Scaffold(body: IntroScene1())),
      );
      // Pump through several cycles — easeOutBack overshoot must not assert.
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 35));
        expect(tester.takeException(), isNull);
      }
    });
  });
}
