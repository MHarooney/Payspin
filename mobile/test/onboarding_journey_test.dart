import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_onboarding_journey.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: PayspinTheme.dark(), home: Scaffold(body: child));

  group('OnboardingJourneySpec', () {
    test('chapter mapping presets', () {
      expect(OnboardingJourneySpec.name.chapter, OnboardingChapter.you);
      expect(OnboardingJourneySpec.name.subStep, 1);
      expect(OnboardingJourneySpec.name.subTotal, 1);

      expect(OnboardingJourneySpec.phone.chapter, OnboardingChapter.verify);
      expect(OnboardingJourneySpec.phone.subStep, 1);
      expect(OnboardingJourneySpec.otp.subStep, 2);

      expect(OnboardingJourneySpec.connect.chapter, OnboardingChapter.getPaid);
      expect(OnboardingJourneySpec.iban.chapter, OnboardingChapter.getPaid);
      expect(OnboardingJourneySpec.fullName.subStep, 2);
    });

    test('progress fractions', () {
      expect(OnboardingJourneySpec.name.chapterProgress, 1.0);
      expect(OnboardingJourneySpec.phone.chapterProgress, 0.5);
      expect(OnboardingJourneySpec.otp.chapterProgress, 1.0);
      expect(OnboardingJourneySpec.connect.chapterProgress, 0.5);
      expect(OnboardingJourneySpec.fullName.chapterProgress, 1.0);

      expect(OnboardingJourneySpec.name.overallProgress, closeTo(1 / 3, 0.001));
      expect(OnboardingJourneySpec.otp.overallProgress, closeTo(2 / 3, 0.001));
      expect(OnboardingJourneySpec.fullName.overallProgress, 1.0);
    });
  });

  testWidgets('chapter rail renders three labels', (tester) async {
    await tester.pumpWidget(
      wrap(const PayspinOnboardingChapterRail(journey: OnboardingJourneySpec.phone)),
    );
    expect(find.text('You'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
    expect(find.text('Get paid'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chapter progress pumps without overflow', (tester) async {
    await tester.pumpWidget(
      wrap(const PayspinOnboardingChapterProgress(journey: OnboardingJourneySpec.otp)),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
