import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_motion.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_morphing_sliver_header.dart';

/// Six-cell OTP entry with fill pop, shake on error, and completion ripple.
class PayspinOtpBoxes extends StatefulWidget {
  const PayspinOtpBoxes({
    super.key,
    required this.controller,
    this.length = 6,
    this.autofocus = true,
    this.hasError = false,
    this.onChanged,
    this.onCompleted,
  });

  final TextEditingController controller;
  final int length;
  final bool autofocus;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  @override
  State<PayspinOtpBoxes> createState() => _PayspinOtpBoxesState();
}

class _PayspinOtpBoxesState extends State<PayspinOtpBoxes> with SingleTickerProviderStateMixin {
  final FocusNode _focus = FocusNode();
  late final AnimationController _shake;
  int _lastLen = 0;
  bool _completePulse = false;
  Timer? _pulseTimer;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    widget.controller.addListener(_onChanged);
    _lastLen = widget.controller.text.length;
  }

  void _onChanged() {
    final len = widget.controller.text.length;
    if (len > _lastLen) HapticFeedback.selectionClick();
    if (len == widget.length && _lastLen < widget.length) {
      setState(() => _completePulse = true);
      _pulseTimer?.cancel();
      _pulseTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _completePulse = false);
      });
    }
    _lastLen = len;
    setState(() {});
    widget.onChanged?.call(widget.controller.text);
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  void didUpdateWidget(covariant PayspinOtpBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shake.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    widget.controller.removeListener(_onChanged);
    _shake.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    final focused = _focus.hasFocus;
    final reduced = PayspinMotion.reduced(context);

    Widget row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (i) {
        final filled = i < value.length;
        final isActive = focused && i == value.length;
        final char = filled ? value[i] : '';
        final justFilled = filled && i == value.length - 1;
        return _Cell(
          char: char,
          active: isActive,
          error: widget.hasError,
          pop: justFilled && !reduced,
          pulse: _completePulse,
        );
      }),
    );

    if (!reduced) {
      row = AnimatedBuilder(
        animation: _shake,
        builder: (_, child) {
          final t = _shake.value;
          final dx = widget.hasError ? 8 * (1 - t) * (t < 0.5 ? 1 : -1) : 0.0;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: row,
      );
    }

    return Stack(
      children: [
        row,
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              keyboardType: TextInputType.number,
              maxLength: widget.length,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              showCursor: false,
              onTap: () => _focus.requestFocus(),
              decoration: const InputDecoration(counterText: '', border: InputBorder.none),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.char,
    required this.active,
    required this.error,
    this.pop = false,
    this.pulse = false,
  });

  final String char;
  final bool active;
  final bool error;
  final bool pop;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final borderColor = error
        ? PayspinTokens.error
        : active || pulse
            ? PayspinTokens.mint
            : PayspinTokens.border;

    Widget cell = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 48,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PayspinTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
        border: Border.all(color: borderColor, width: active || pulse ? 2 : 1),
        boxShadow: active || pulse
            ? [BoxShadow(color: PayspinTokens.mint.withValues(alpha: 0.18), blurRadius: 12)]
            : null,
      ),
      child: Text(
        char,
        style: GoogleFonts.raleway(fontSize: 26, fontWeight: FontWeight.w800, color: PayspinTokens.mint),
      ),
    );

    if (pop) {
      cell = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: PayspinMotion.fast,
        curve: PayspinMotion.spring,
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: cell,
      );
    }

    if (pulse) {
      cell = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
          boxShadow: [
            BoxShadow(color: PayspinTokens.mint.withValues(alpha: 0.25), blurRadius: 14),
          ],
        ),
        child: cell,
      );
    }

    if (active && !error) {
      cell = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: Stack(
          children: [
            cell,
            const Positioned(
              left: 4,
              right: 4,
              bottom: 0,
              child: PayspinMorphingAuroraHairline(intensity: 0.7),
            ),
          ],
        ),
      );
    }

    return cell;
  }
}

/// Resend OTP with circular countdown ring (seconds remaining).
class PayspinOtpResendButton extends StatelessWidget {
  const PayspinOtpResendButton({
    super.key,
    required this.secondsRemaining,
    required this.onPressed,
    this.label = 'Resend code',
  });

  final int secondsRemaining;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final canResend = secondsRemaining <= 0;
    final progress = canResend ? 1.0 : 1 - (secondsRemaining / 60).clamp(0.0, 1.0);

    return TextButton(
      onPressed: canResend ? onPressed : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!canResend) ...[
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 2,
                color: PayspinTokens.mint,
                backgroundColor: PayspinTokens.mint.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            canResend ? label : '$label (${secondsRemaining}s)',
            style: const TextStyle(color: PayspinTokens.mint),
          ),
        ],
      ),
    );
  }
}
