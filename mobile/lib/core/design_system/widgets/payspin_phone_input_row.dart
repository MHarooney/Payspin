import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/phone_country_codes.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_glass_surface.dart';
import 'payspin_underline_field.dart';

/// Formats digits into a readable E.164 preview (`+31 612 345 678`).
String formatPhoneE164Preview(String dialCode, String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return dialCode;
  final buf = StringBuffer(dialCode);
  for (var i = 0; i < digits.length; i++) {
    if (i == 0) {
      buf.write(' ');
    } else if (i % 3 == 0) {
      buf.write(' ');
    }
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Minimum digit count for a plausible national number per dial code.
bool isPhoneDigitsValid(String dialCode, String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 6) return false;
  return switch (dialCode) {
    '+31' => digits.length >= 9,
    '+49' => digits.length >= 10,
    '+44' => digits.length >= 10,
    _ => digits.length >= 8,
  };
}

/// Phone row: glass country pill + mint underline input + E.164 preview.
class PayspinPhoneInputRow extends StatefulWidget {
  const PayspinPhoneInputRow({
    super.key,
    required this.phoneController,
    required this.selectedDialCode,
    required this.onDialCodeChanged,
    this.onPhoneChanged,
    this.phoneHint = '06 12345678',
    this.autofocusPhone = true,
  });

  final TextEditingController phoneController;
  final String selectedDialCode;
  final ValueChanged<String> onDialCodeChanged;
  final ValueChanged<String>? onPhoneChanged;
  final String phoneHint;
  final bool autofocusPhone;

  @override
  State<PayspinPhoneInputRow> createState() => _PayspinPhoneInputRowState();
}

class _PayspinPhoneInputRowState extends State<PayspinPhoneInputRow> {
  PhoneCountry get _selected =>
      phoneCountryByDialCode(widget.selectedDialCode) ?? defaultPhoneCountry;

  void _openCountrySheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CountryPickerSheet(
        selected: _selected,
        onPick: (country) {
          widget.onDialCodeChanged(country.dialCode);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final preview = formatPhoneE164Preview(widget.selectedDialCode, widget.phoneController.text);
    final valid = isPhoneDigitsValid(widget.selectedDialCode, widget.phoneController.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _CountryPill(country: _selected, onTap: _openCountrySheet),
            const SizedBox(width: 14),
            Expanded(
              child: PayspinUnderlineField(
                controller: widget.phoneController,
                hintText: widget.phoneHint,
                autofocus: widget.autofocusPhone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                ],
                onChanged: (v) {
                  widget.onPhoneChanged?.call(v);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                preview,
                style: GoogleFonts.inter(fontSize: 12, color: colors.textMuted, letterSpacing: 0.02),
              ),
            ),
            if (valid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PayspinTokens.mint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: PayspinTokens.mint.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_rounded, size: 14, color: PayspinTokens.mint),
                    const SizedBox(width: 4),
                    Text(
                      'Valid',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: PayspinTokens.mint),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _CountryPill extends StatelessWidget {
  const _CountryPill({required this.country, required this.onTap});

  final PhoneCountry country;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Material(
      color: colors.glassFill,
      shape: StadiumBorder(side: BorderSide(color: colors.border)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flagEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                country.dialCode,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: colors.textPrimary,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({required this.selected, required this.onPick});

  final PhoneCountry selected;
  final ValueChanged<PhoneCountry> onPick;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<PhoneCountry> _results = kPhoneCountries;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _search.removeListener(_onQueryChanged);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final query = _search.text;
    setState(() {
      _results = kPhoneCountries.where((c) => c.matchesQuery(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final safeBottom = media.padding.bottom;
    // Keep the sheet above the keyboard and within the remaining space so the
    // search field and results never get covered when the user types.
    final available = media.size.height - keyboardInset - media.padding.top - 24;
    final maxHeight = available.clamp(260.0, media.size.height * 0.72);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: PayspinGlassSurface(
        tier: PayspinGlassTier.overlay,
        borderRadius: 28,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + (keyboardInset > 0 ? 0 : safeBottom)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Select country',
              style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              focusNode: _searchFocus,
              style: GoogleFonts.inter(fontSize: 14, color: colors.textPrimary),
              cursorColor: colors.fieldAccent,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search country or code',
                hintStyle: GoogleFonts.inter(fontSize: 14, color: colors.textHint),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: colors.textMuted),
                prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                filled: true,
                fillColor: colors.glassFill,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
                  borderSide: BorderSide(color: colors.borderActive),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: _results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No countries found',
                        style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (_, i) => _CountryRow(
                        country: _results[i],
                        selected: _results[i].dialCode == widget.selected.dialCode,
                        onTap: () => widget.onPick(_results[i]),
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

class _CountryRow extends StatelessWidget {
  const _CountryRow({required this.country, required this.selected, required this.onTap});

  final PhoneCountry country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Material(
      color: selected ? colors.glassFill : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Text(country.flagEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  country.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              Text(
                country.dialCode,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? colors.fieldAccent : colors.textMuted,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_rounded, size: 16, color: colors.fieldAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
