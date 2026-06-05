import 'package:flutter/material.dart';

import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

class PayspinGradientText extends StatelessWidget {
  const PayspinGradientText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.solidWordmark = false,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// When true, renders [text] in [PayspinSemanticColors.textPrimary] instead of
  /// the brand gradient (used on splash / welcome wordmarks in light mode).
  final bool solidWordmark;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final base = style ??
        Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 32,
              color: colors.textPrimary,
            ) ??
        TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        );

    // Dark surfaces (or explicit solid wordmark): use semantic primary text colour.
    if (solidWordmark || Theme.of(context).brightness == Brightness.dark) {
      return Text(
        text,
        textAlign: textAlign,
        style: base.copyWith(color: colors.textPrimary),
      );
    }

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
