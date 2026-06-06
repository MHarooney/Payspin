import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/payspin_semantic_colors.dart';

/// Underline text field matching [screens.jsx] onboarding/send inputs:
/// mint text + mint caret when filled; hint at 35% white; active pink underline.
class PayspinUnderlineField extends StatefulWidget {
  const PayspinUnderlineField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLength,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.obscureText = false,
    this.showVisibilityToggle = false,
    this.onChanged,
    this.textInputAction,
    /// Text color when the field has a value. Defaults to the theme
    /// [PayspinSemanticColors.fieldAccent] (pink in light, mint in dark).
    /// Step 5 (full name) overrides with the semantic primary text colour.
    this.filledTextColor,
    this.filledLetterSpacing = 0,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String? hintText;
  final int? maxLength;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool showVisibilityToggle;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final Color? filledTextColor;
  final double filledLetterSpacing;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<PayspinUnderlineField> createState() => _PayspinUnderlineFieldState();
}

class _PayspinUnderlineFieldState extends State<PayspinUnderlineField> {
  late bool _obscured;

  static const _fieldDecoration = InputDecoration(
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    filled: false,
    isDense: true,
    contentPadding: EdgeInsets.zero,
    counterText: '',
  );

  static const _fieldDecorationTheme = InputDecorationThemeData(
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    filled: false,
    isDense: true,
    contentPadding: EdgeInsets.zero,
  );

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant PayspinUnderlineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
    if (oldWidget.obscureText != widget.obscureText && !widget.showVisibilityToggle) {
      _obscured = widget.obscureText;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  bool get _isObscured => widget.showVisibilityToggle ? _obscured : widget.obscureText;

  bool get _hasValue => widget.controller.text.isNotEmpty;

  Color _valueColorOf(BuildContext context) =>
      widget.filledTextColor ?? context.psColors.fieldAccent;

  TextStyle _fieldStyle({
    required bool hasValue,
    required Color hintColor,
    required Color valueColor,
  }) {
    return GoogleFonts.raleway(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: hasValue ? valueColor : hintColor,
      letterSpacing: hasValue ? widget.filledLetterSpacing : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final accent = _valueColorOf(context);
    final hasValue = _hasValue;
    final fieldStyle = _fieldStyle(hasValue: hasValue, hintColor: colors.textHint, valueColor: accent);

    // Isolate from [PayspinTheme] glass-filled [InputDecorationTheme] so typed
    // text uses [fieldStyle], not colorScheme.onSurface (white).
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: _fieldDecorationTheme,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: accent,
          selectionColor: accent.withValues(alpha: 0.3),
          selectionHandleColor: accent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  autofocus: widget.autofocus,
                  maxLength: widget.maxLength,
                  textCapitalization: widget.textCapitalization,
                  keyboardType: widget.keyboardType,
                  inputFormatters: widget.inputFormatters,
                  obscureText: _isObscured,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  style: fieldStyle,
                  cursorColor: accent,
                  decoration: _fieldDecoration.copyWith(
                    hintText: widget.hintText,
                    hintStyle: _fieldStyle(hasValue: false, hintColor: colors.textHint, valueColor: accent),
                  ),
                ),
              ),
              if (widget.showVisibilityToggle) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(
                    _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: colors.textMuted,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  tooltip: _obscured ? 'Show password' : 'Hide password',
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: hasValue ? colors.borderActive : colors.border,
          ),
        ],
      ),
    );
  }
}
