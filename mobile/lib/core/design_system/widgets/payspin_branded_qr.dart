import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/payspin_localizations.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// Payspin-branded QR code: rounded white plate, pink data modules, mint
/// finder eyes, and the Payspin emblem on a **circular safe plate** in the centre.
///
/// The centre plate keeps the gradient emblem readable on both light and dark
/// app themes and preserves EC level H scannability.
class PayspinBrandedQr extends StatelessWidget {
  const PayspinBrandedQr({
    super.key,
    required this.data,
    this.size = 240,
  });

  /// The payable URL (e.g. `https://pay.payspin.io/abcd1234`).
  final String data;
  final double size;

  static const _centerDark = 'assets/images/payspin_emblem_qr_center.png';
  static const _centerLight = 'assets/images/payspin_emblem_qr_center_light.png';

  /// Emblem + circular safe plate ≈ 28% of QR side (emblem core ~19%).
  static double plateSide(double qrSide) => qrSide * 0.28;

  @override
  Widget build(BuildContext context) {
    final plate = size + 40;
    final centerPlate = plateSide(size);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final centerAsset = isDark ? _centerDark : _centerLight;
    final glow = context.psColors.pageGlowPink;
    final l10n = PayspinLocalizations.of(context);

    return Container(
      width: plate,
      height: plate,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : context.psColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glow,
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
        embeddedImage: AssetImage(centerAsset),
        embeddedImageStyle: QrEmbeddedImageStyle(
          size: Size(centerPlate, centerPlate),
        ),
        embeddedImageEmitsError: false,
        semanticsLabel: l10n.qrSemanticsLabel,
      ),
    );
  }
}
