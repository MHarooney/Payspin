import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(children: [for (final d in row) _digit(d)]),
        Row(
          children: [
            _action(
              child: biometricIcon != null
                  ? Icon(biometricIcon, color: PayspinTokens.mint, size: 30)
                  : null,
              onTap: biometricIcon != null ? onBiometric : null,
            ),
            _digit('0'),
            _action(
              child: const Icon(Icons.backspace_outlined,
                  color: PayspinTokens.textBody, size: 26),
              onTap: onBackspace,
            ),
          ],
        ),
      ],
    );
  }

  Widget _digit(String d) => Expanded(
        child: AspectRatio(
          aspectRatio: 1.45,
          child: _KeypadButton(
            onTap: () {
              HapticFeedback.selectionClick();
              onDigit(d);
            },
            child: Text(
              d,
              style: GoogleFonts.raleway(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: PayspinTokens.textPrimary,
              ),
            ),
          ),
        ),
      );

  Widget _action({Widget? child, VoidCallback? onTap}) => Expanded(
        child: AspectRatio(
          aspectRatio: 1.45,
          child: child == null
              ? const SizedBox.shrink()
              : _KeypadButton(
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
  const _KeypadButton({required this.child, this.onTap});

  final Widget child;
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
          highlightColor: PayspinTokens.glass,
          splashColor: PayspinTokens.surfaceMuted,
          child: Center(child: child),
        ),
      ),
    );
  }
}
