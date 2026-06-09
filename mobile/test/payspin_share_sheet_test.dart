import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_gradient_pill_button.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_share_sheet.dart';
import 'package:payspin_mobile/core/l10n/locale_controller.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(
      theme: PayspinTheme.dark(),
      locale: const Locale('en'),
      supportedLocales: LocaleController.supportedLocales,
      localizationsDelegates: const [
        PayspinLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    );

const _payload = ShareLinkPayload(
  linkId: 'l1',
  amountLabel: '€10.00',
  description: 'Dinner',
  payUrl: 'https://pay/abc',
  isPayable: true,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'share_sheet_shimmer_seen': true});
  });

  testWidgets('PayspinShareActionCluster renders WhatsApp and More apps', (tester) async {
    await tester.pumpWidget(_app(const Scaffold(body: PayspinShareActionCluster(payload: _payload))));
    await tester.pump();

    expect(find.text('Share via WhatsApp'), findsOneWidget);
    expect(find.text('More apps'), findsOneWidget);
    expect(find.text('Copy link'), findsOneWidget);
    expect(find.text('Show QR'), findsOneWidget);
  });

  testWidgets('showPayspinShareSheet opens with hero CTA', (tester) async {
    await tester.pumpWidget(_app(Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () => showPayspinShareSheet(context, payload: _payload, whatsAppShimmer: false),
          child: const Text('Open'),
        ),
      ),
    )));
    await tester.pump();

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Dinner'), findsOneWidget);
    expect(find.byType(PayspinGradientPillButton), findsOneWidget);
    expect(find.text('€10.00'), findsOneWidget);
  });

  testWidgets('disabled payload invokes onShareDisabled from WhatsApp tap', (tester) async {
    var disabled = false;
    const blocked = ShareLinkPayload(
      linkId: 'l2',
      amountLabel: '€5.00',
      description: '',
      payUrl: 'https://pay/x',
      isPayable: false,
    );

    await tester.pumpWidget(_app(Scaffold(
      body: PayspinShareActionCluster(
        payload: blocked,
        onShareDisabled: () => disabled = true,
      ),
    )));
    await tester.pump();

    await tester.tap(find.text('Share via WhatsApp'));
    await tester.pump();
    expect(disabled, isTrue);
  });
}
