import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/phone_country_codes.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_underline_field.dart';

/// Phone row from [screens.jsx] `Step2Phone`: glass country pill + mint underline input + inline list.
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
  // The dropdown lives in the root [Overlay] via an [OverlayEntry] positioned
  // from the anchor's real global rect. A Positioned child overflowing the
  // local Stack used to paint but never hit-test (taps were dropped); an
  // overlay entry is hit-tested independently, so list items respond.
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _entry;

  bool get _open => _entry != null;

  PhoneCountry get _selected =>
      phoneCountryByDialCode(widget.selectedDialCode) ?? defaultPhoneCountry;

  void _toggleCountry() {
    if (_open) {
      _close();
    } else {
      // Drop the keyboard so the list isn't fighting the bottom inset.
      FocusManager.instance.primaryFocus?.unfocus();
      _openDropdown();
    }
  }

  void _openDropdown() {
    final box = _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) return;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final size = box.size;
    final screen = overlay.size;
    const gap = 8.0;
    const maxDropdownHeight = 280.0;

    // Prefer opening below the row; flip above if there isn't room.
    final spaceBelow = screen.height - (topLeft.dy + size.height) - gap;
    final openAbove = spaceBelow < 200 && topLeft.dy > spaceBelow;
    final maxHeight =
        (openAbove ? topLeft.dy - gap : spaceBelow).clamp(120.0, maxDropdownHeight);

    _entry = OverlayEntry(
      builder: (_) {
        return Stack(
          children: [
            // Full-screen dismiss barrier.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            Positioned(
              left: topLeft.dx,
              width: size.width,
              top: openAbove ? null : topLeft.dy + size.height + gap,
              bottom: openAbove ? screen.height - topLeft.dy + gap : null,
              child: _CountryDropdown(
                selected: _selected,
                maxHeight: maxHeight,
                onPick: _pickCountry,
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_entry!);
    setState(() {});
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() {});
  }

  void _pickCountry(PhoneCountry country) {
    widget.onDialCodeChanged(country.dialCode);
    _close();
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      key: _anchorKey,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _CountryPill(
          country: _selected,
          isOpen: _open,
          onTap: _toggleCountry,
        ),
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
            onChanged: widget.onPhoneChanged,
          ),
        ),
      ],
    );
  }
}

class _CountryPill extends StatelessWidget {
  const _CountryPill({
    required this.country,
    required this.isOpen,
    required this.onTap,
  });

  final PhoneCountry country;
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Material(
      color: colors.glassFill,
      shape: StadiumBorder(
        side: BorderSide(
          color: isOpen ? colors.borderActive : colors.border,
        ),
      ),
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
              Icon(
                isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: colors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Country picker body shown in the overlay: a search field (filters by name,
/// ISO, or dial code via [PhoneCountry.matchesQuery]) over the country list.
class _CountryDropdown extends StatefulWidget {
  const _CountryDropdown({
    required this.selected,
    required this.onPick,
    this.maxHeight = 280,
  });

  final PhoneCountry selected;
  final ValueChanged<PhoneCountry> onPick;
  final double maxHeight;

  @override
  State<_CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<_CountryDropdown> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<PhoneCountry> _results = kPhoneCountries;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onQueryChanged);
    // Open straight into search so a user can type the country immediately.
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
    return Material(
      color: colors.bgElevated,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSearchField(),
            Flexible(
              child: _results.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                      shrinkWrap: true,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) =>
                          _buildCountryRow(_results[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final colors = context.psColors;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: TextField(
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
    );
  }

  Widget _buildEmptyState() {
    final colors = context.psColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: Text(
        'No countries found',
        style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
      ),
    );
  }

  Widget _buildCountryRow(PhoneCountry country) {
    final colors = context.psColors;
    final isSelected = country.dialCode == widget.selected.dialCode;
    return Material(
      color: isSelected ? colors.glassFill : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => widget.onPick(country),
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
                  color: isSelected ? colors.fieldAccent : colors.textMuted,
                ),
              ),
              if (isSelected) ...[
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
