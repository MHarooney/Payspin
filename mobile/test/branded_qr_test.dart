import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_branded_qr.dart';
import 'package:payspin_mobile/core/l10n/locale_controller.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';

Widget _wrap(Widget child, {ThemeMode themeMode = ThemeMode.dark}) {
  return MaterialApp(
    themeMode: themeMode,
    theme: PayspinTheme.light(),
    darkTheme: PayspinTheme.dark(),
    locale: const Locale('en'),
    supportedLocales: LocaleController.supportedLocales,
    localizationsDelegates: const [
      PayspinLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('PayspinBrandedQr renders a QR encoding the pay URL', (tester) async {
    const url = 'https://pay.payspin.io/abcd1234';
    await tester.pumpWidget(_wrap(const PayspinBrandedQr(data: url)));
    await tester.pump();

    final qrFinder = find.byType(QrImageView);
    expect(qrFinder, findsOneWidget);

    final qr = tester.widget<QrImageView>(qrFinder);
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.H);
    expect(qr.embeddedImageStyle?.size?.width, 240 * 0.28);

    expect(tester.takeException(), isNull);
  });

  testWidgets('uses light-theme centre plate asset in light mode', (tester) async {
    const url = 'https://pay.payspin.io/abcd1234';
    await tester.pumpWidget(
      _wrap(const PayspinBrandedQr(data: url), themeMode: ThemeMode.light),
    );
    await tester.pump();

    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    final asset = (qr.embeddedImage! as AssetImage).assetName;
    expect(asset, contains('qr_center_light'));
  });
}
