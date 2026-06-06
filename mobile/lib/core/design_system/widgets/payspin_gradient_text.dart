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
    this.wordmark = false,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;

  /// When true, renders [text] in [PayspinSemanticColors.textPrimary] instead of
  /// the brand gradient (used on splash / welcome wordmarks in light mode).
  final bool solidWordmark;

  /// Brand "Payspin" wordmark: renders the official logo lettering (cropped
  /// from the brand lockup) tinted to the semantic primary colour — white in
  /// dark mode, black in light mode — so it matches the logo exactly on every
  /// screen. [style.fontSize] sets the visual size.
  final bool wordmark;

  /// Cropped from the official Payspin logo lockup (black on transparent), so
  /// tinting with [colorBlendMode] srcIn recolours it per theme.
  static const String _wordmarkAsset = 'assets/images/payspin_wordmark.png';

  /// Native pixel aspect ratio of [_wordmarkAsset] (width / height).
  static const double _wordmarkAspect = 241 / 71;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;

    // Canonical Payspin wordmark — official logo artwork, tinted per theme.
    if (wordmark) {
      final fontSize = style?.fontSize ?? 18;
      // Match the optical height of the old text (cap height ≈ 0.72·fontSize;
      // the artwork includes ascenders/descenders, so scale up a touch).
      final height = fontSize * 1.25;
      return Image.asset(
        _wordmarkAsset,
        height: height,
        width: height * _wordmarkAspect,
        color: colors.textPrimary,
        colorBlendMode: BlendMode.srcIn,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Payspin',
      );
    }

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
