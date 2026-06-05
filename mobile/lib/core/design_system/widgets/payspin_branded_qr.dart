import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../tokens/payspin_tokens.dart';

/// Payspin-branded QR code: rounded white plate, pink data modules, mint
/// finder eyes, and the Payspin emblem embedded in the center.
///
/// Uses high error correction (H) so the centre logo overlay never breaks
/// scannability — verified against [ScanQrPage].
class PayspinBrandedQr extends StatelessWidget {
  const PayspinBrandedQr({
    super.key,
    required this.data,
    this.size = 240,
  });

  /// The payable URL (e.g. `https://pay.payspin.io/abcd1234`).
  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final plate = size + 40;
    return Container(
      width: plate,
      height: plate,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: PayspinTokens.pink.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        gapless: false,
        backgroundColor: Colors.white,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: PayspinTokens.pink,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.circle,
          color: Color(0xFF1A1230),
        ),
        embeddedImage: const AssetImage('assets/images/payspin_ic_opaque.png'),
        embeddedImageStyle: const QrEmbeddedImageStyle(
          size: Size(46, 46),
        ),
        embeddedImageEmitsError: false,
        semanticsLabel: 'Payspin payment QR code',
      ),
    );
  }
}
