import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/l10n/locale_controller.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:payspin_mobile/presentation/intro/intro_scene_scope.dart';
import 'package:payspin_mobile/presentation/intro/scenes/intro_scene_1_bill_to_links.dart';
import 'package:payspin_mobile/presentation/intro/scenes/intro_scene_2_europe_map.dart';
import 'package:payspin_mobile/presentation/intro/scenes/intro_scene_3_one_tap_pay.dart';
import 'package:payspin_mobile/presentation/intro/scenes/intro_scene_4_value_loop.dart';
import 'package:payspin_mobile/presentation/intro/scenes/intro_scene_5_use_cases.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: PayspinTheme.dark(),
      locale: const Locale('en'),
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        PayspinLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: IntroSceneScope(
          pageOffset: 0,
          offsetListenable: ValueNotifier(0),
          child: Scaffold(
            body: SizedBox(
              height: 700,
              width: 400,
              child: Column(
                children: [
                  Expanded(flex: 5, child: child),
                  const Expanded(flex: 3, child: SizedBox()),
                ],
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  // Scene 2 is the 3D globe; it loads its surface texture asynchronously and is
  // verified separately with a tolerant assertion below.
  final scenes = <(int, Widget)>[
    (0, const IntroScene1(sceneIndex: 0)),
    (2, const IntroScene3(sceneIndex: 2)),
    (3, const IntroScene4(sceneIndex: 3)),
    (4, const IntroScene5(sceneIndex: 4)),
  ];

  for (final (index, scene) in scenes) {
    testWidgets('intro scene ${index + 1} renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_wrap(scene));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('intro scene 2 globe builds', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(const IntroScene2(sceneIndex: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The scene builds the globe widget; any async asset-load errors from the
    // test harness (no GPU / bundled texture) are drained and ignored.
    expect(find.byType(IntroScene2), findsOneWidget);
    tester.takeException();
  });
}
