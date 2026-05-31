import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/phone_country_codes.dart';
import '../tokens/payspin_tokens.dart';

/// Compact trigger: flag + dial code. Opens a searchable bottom sheet.
class PhoneCountrySelector extends StatelessWidget {
  const PhoneCountrySelector({
    super.key,
    required this.selectedDialCode,
    required this.onChanged,
  });

  final String selectedDialCode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final country = phoneCountryByDialCode(selectedDialCode) ?? defaultPhoneCountry;
    return InkWell(
      onTap: () => _openPicker(context, country),
      borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
      child: Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(country.flagEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Text(
                  country.dialCode,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: PayspinTokens.mint,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 22,
                  color: PayspinTokens.textMuted,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              width: 88,
              color: PayspinTokens.borderActive,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context, PhoneCountry current) async {
    final picked = await showModalBottomSheet<PhoneCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: PayspinTokens.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PhoneCountryPickerSheet(selected: current),
    );
    if (picked != null) onChanged(picked.dialCode);
  }
}

class _PhoneCountryPickerSheet extends StatefulWidget {
  const _PhoneCountryPickerSheet({required this.selected});

  final PhoneCountry selected;

  @override
  State<_PhoneCountryPickerSheet> createState() => _PhoneCountryPickerSheetState();
}

class _PhoneCountryPickerSheetState extends State<_PhoneCountryPickerSheet> {
  final _search = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<PhoneCountry> get _filtered =>
      kPhoneCountries.where((c) => c.matchesQuery(_search.text)).toList();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.72;
    final items = _filtered;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Country code',
                style: GoogleFonts.raleway(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: PayspinTokens.textPrimary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                focusNode: _focus,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(color: PayspinTokens.textPrimary, fontSize: 16),
                cursorColor: PayspinTokens.mint,
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  hintStyle: GoogleFonts.inter(color: PayspinTokens.textHint, fontSize: 16),
                  prefixIcon: Icon(Icons.search_rounded, color: PayspinTokens.textMuted),
                  filled: true,
                  fillColor: PayspinTokens.bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
                    borderSide: BorderSide(color: PayspinTokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
                    borderSide: BorderSide(color: PayspinTokens.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PayspinTokens.radiusInput),
                    borderSide: const BorderSide(color: PayspinTokens.mint),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'No countries match your search',
                        style: GoogleFonts.inter(color: PayspinTokens.textMuted, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final country = items[index];
                        final isSelected = country.dialCode == widget.selected.dialCode;
                        return Material(
                          color: isSelected
                              ? PayspinTokens.mint.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            onTap: () => Navigator.of(context).pop(country),
                            leading: Text(country.flagEmoji, style: const TextStyle(fontSize: 26)),
                            title: Text(
                              country.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: PayspinTokens.textPrimary,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  country.dialCode,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: PayspinTokens.mint,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_rounded, color: PayspinTokens.mint, size: 20),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
