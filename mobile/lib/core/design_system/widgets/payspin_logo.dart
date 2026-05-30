import 'package:flutter/material.dart';

enum PayspinLogoVariant { mark, wordmark }

class PayspinLogo extends StatelessWidget {
  const PayspinLogo({super.key, this.variant = PayspinLogoVariant.mark, this.size = 48});

  final PayspinLogoVariant variant;
  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = variant == PayspinLogoVariant.mark
        ? 'assets/images/payspin_ic.png'
        : 'assets/images/payspin_ic_white.png';
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }
}
