import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_branded_qr.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  testWidgets('PayspinBrandedQr renders a QR encoding the pay URL', (tester) async {
    const url = 'https://pay.payspin.io/abcd1234';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: PayspinBrandedQr(data: url)),
        ),
      ),
    );

    final qrFinder = find.byType(QrImageView);
    expect(qrFinder, findsOneWidget);

    final qr = tester.widget<QrImageView>(qrFinder);
    // High error correction is required so the centre logo never breaks scans.
    expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.H);

    // No layout overflow at the default size.
    expect(tester.takeException(), isNull);
  });
}
