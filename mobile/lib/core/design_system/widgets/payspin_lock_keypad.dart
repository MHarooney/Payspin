import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// Numeric keypad for passcode entry. The bottom-left key is an optional
/// biometric affordance (Face ID / fingerprint); the bottom-right is backspace.
class PayspinLockKeypad extends StatelessWidget {
  const PayspinLockKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.biometricIcon,
    this.onBiometric,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  /// When provided, renders a biometric key in the bottom-left slot.
  final IconData? biometricIcon;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(children: [for (final d in row) _digit(d, colors)]),
        Row(
          children: [
            _action(
              colors,
              child: biometricIcon != null
                  ? Icon(biometricIcon, color: PayspinTokens.mint, size: 30)
                  : null,
              onTap: biometricIcon != null ? onBiometric : null,
            ),
            _digit('0', colors),
            _action(
              colors,
              child: Icon(Icons.backspace_outlined,
                  color: colors.textBody, size: 26),
              onTap: onBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _digit(String d, PayspinSemanticColors colors) => Expanded(
        child: AspectRatio(
          aspectRatio: 1.45,
          child: _KeypadButton(
            colors: colors,
            onTap: () {
              HapticFeedback.selectionClick();
              onDigit(d);
            },
            child: Text(
              d,
              style: GoogleFonts.raleway(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
        ),
      );

  Widget _action(PayspinSemanticColors colors, {Widget? child, VoidCallback? onTap}) => Expanded(
        child: AspectRatio(
          aspectRatio: 1.45,
          child: child == null
              ? const SizedBox.shrink()
              : _KeypadButton(
                  colors: colors,
                  onTap: onTap == null
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          onTap();
                        },
                  child: child,
                ),
        ),
      );
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({required this.child, required this.colors, this.onTap});

  final Widget child;
  final PayspinSemanticColors colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          highlightColor: colors.glassFill,
          splashColor: colors.surfaceRaised,
          child: Center(child: child),
        ),
      ),
    );
  }
}
