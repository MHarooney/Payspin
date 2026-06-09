import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';

/// A single Home quick-action: a gradient-filled rounded icon square with a
/// label beneath. When [onTap] is null the tile renders as disabled (muted fill,
/// no glow) and exposes the disabled state to assistive tech.
class PayspinQuickActionTile extends StatefulWidget {
  const PayspinQuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticHint,
  });

  final IconData icon;
  final String label;

  /// Null = disabled (e.g. "Share last" with no payable link).
  final VoidCallback? onTap;
  final String? semanticHint;

  @override
  State<PayspinQuickActionTile> createState() => _PayspinQuickActionTileState();
}

class _PayspinQuickActionTileState extends State<PayspinQuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final enabled = widget.onTap != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      hint: widget.semanticHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!.call();
              }
            : null,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1,
          duration: PayspinMotion.fast,
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: enabled ? PayspinTokens.gradientPink : null,
                  color: enabled ? null : PayspinTokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                  border: enabled ? null : Border.all(color: colors.border),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: PayspinTokens.pink.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  size: 24,
                  color: enabled ? PayspinTokens.onBrand : colors.textHint,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 68,
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: enabled ? colors.textBody : colors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
