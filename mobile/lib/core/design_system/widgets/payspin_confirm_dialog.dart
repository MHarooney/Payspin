import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_glass_surface.dart';
import 'payspin_gradient_pill_button.dart';

/// Glass confirmation dialog for destructive / irreversible actions.
///
/// Returns `true` when confirmed, `false`/`null` otherwise. Use a single voice
/// for cancel / logout / remove flows instead of bespoke [AlertDialog]s.
Future<bool> showPayspinConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
  IconData? icon,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelLabel,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: PayspinMotion.medium,
    pageBuilder: (context, _, __) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: PayspinMotion.easeEnter);
      return Opacity(
        opacity: anim.value,
        child: Transform.scale(
          scale: 0.94 + 0.06 * curved.value,
          child: _ConfirmBody(
            title: title,
            message: message,
            confirmLabel: confirmLabel,
            cancelLabel: cancelLabel,
            destructive: destructive,
            icon: icon,
          ),
        ),
      );
    },
  );
  return result ?? false;
}

class _ConfirmBody extends StatelessWidget {
  const _ConfirmBody({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.destructive,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final accent = destructive ? PayspinTokens.danger : PayspinTokens.mint;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: PayspinGlassSurface(
            tier: PayspinGlassTier.overlay,
            glow: true,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (icon != null) ...[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.14),
                      border: Border.all(color: accent.withValues(alpha: 0.4)),
                    ),
                    child: Icon(icon, color: accent, size: 26),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  title,
                  style: GoogleFonts.raleway(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: GoogleFonts.inter(fontSize: 14, height: 1.5, color: colors.textMuted),
                ),
                const SizedBox(height: 24),
                if (destructive)
                  _DestructiveButton(label: confirmLabel, onTap: () => Navigator.of(context).pop(true))
                else
                  PayspinGradientPillButton(
                    label: confirmLabel,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    cancelLabel,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PayspinTokens.danger.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
        side: BorderSide(color: PayspinTokens.danger.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
        child: SizedBox(
          height: PayspinTokens.btnHeightLg,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: PayspinTokens.danger,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
