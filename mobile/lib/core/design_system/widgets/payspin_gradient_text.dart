import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';

class PayspinGradientText extends StatelessWidget {
  const PayspinGradientText(this.text, {super.key, this.style, this.textAlign});

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ??
        Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 32,
            ) ??
        const TextStyle(fontSize: 32, fontWeight: FontWeight.w800);
    return ShaderMask(
      shaderCallback: (b) => PayspinTokens.gradientPink.createShader(b),
      child: Text(text, textAlign: textAlign, style: base.copyWith(color: Colors.white)),
    );
  }
}

class PayspinSplitWordmark extends StatelessWidget {
  const PayspinSplitWordmark({super.key, this.fontSize = 36});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
            ) ??
        TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: 'Pay', style: style.copyWith(color: PayspinTokens.pink)),
          TextSpan(text: 'spin', style: style.copyWith(color: PayspinTokens.mint)),
        ],
      ),
    );
  }
}
