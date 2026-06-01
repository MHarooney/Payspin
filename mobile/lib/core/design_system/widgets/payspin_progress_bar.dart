import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';

class PayspinProgressBar extends StatelessWidget {
  const PayspinProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: SizedBox(
        height: 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: PayspinTokens.surfaceMuted),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: const DecoratedBox(decoration: BoxDecoration(gradient: PayspinTokens.gradientPink)),
            ),
          ],
        ),
      ),
    );
  }
}
