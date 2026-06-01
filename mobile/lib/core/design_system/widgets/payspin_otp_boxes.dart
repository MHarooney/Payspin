import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../tokens/payspin_tokens.dart';

/// Six-cell OTP entry. A single hidden [TextField] drives the value; tapping
/// anywhere focuses it and the visible cells mirror the entered digits.
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

class _PayspinOtpBoxesState extends State<PayspinOtpBoxes> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {});
    widget.onChanged?.call(widget.controller.text);
    if (widget.controller.text.length == widget.length) {
      widget.onCompleted?.call(widget.controller.text);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.text;
    final focused = _focus.hasFocus;

    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (i) {
            final filled = i < value.length;
            final isActive = focused && i == value.length;
            final char = filled ? value[i] : '';
            return _Cell(char: char, active: isActive, error: widget.hasError);
          }),
        ),
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
  const _Cell({required this.char, required this.active, required this.error});

  final String char;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = error
        ? PayspinTokens.error
        : active
            ? PayspinTokens.mint
            : PayspinTokens.border;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 48,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PayspinTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
        border: Border.all(color: borderColor, width: active ? 2 : 1),
        boxShadow: active
            ? [BoxShadow(color: PayspinTokens.mint.withValues(alpha: 0.18), blurRadius: 12)]
            : null,
      ),
      child: Text(
        char,
        style: GoogleFonts.raleway(fontSize: 26, fontWeight: FontWeight.w800, color: PayspinTokens.mint),
      ),
    );
  }
}
