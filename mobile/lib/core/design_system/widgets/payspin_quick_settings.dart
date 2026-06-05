import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/di/injection.dart';
import '../../l10n/locale_controller.dart';
import '../../l10n/payspin_localizations.dart';
import '../../preferences/payspin_preferences_sheets.dart';
import '../theme/payspin_semantic_colors.dart';
import '../theme/theme_mode_controller.dart';

/// Glass icon button → quick "Preferences" sheet exposing both **Appearance**
/// and **Language** pickers from any screen (not just Profile).
///
/// Reuses [PayspinPreferencesSheets] for the actual pickers so behaviour stays
/// consistent with Profile → Settings.
class PayspinQuickSettings extends StatelessWidget {
  const PayspinQuickSettings({
    super.key,
    this.size = 40,
    this.iconSize = 20,
    this.rounded = false,
  });

  final double size;
  final double iconSize;

  /// `true` → rounded-square chip (home header style); `false` → circle.
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final shape = rounded
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.glassBorder),
          )
        : CircleBorder(side: BorderSide(color: colors.glassBorder));

    final tooltip = PayspinLocalizations.maybeOf(context)?.quickSettingsTooltip ??
        'Appearance & language';
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.glassFill,
        shape: shape,
        child: InkWell(
          onTap: () => showQuickSettings(context),
          customBorder: shape,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(Icons.tune_rounded, color: colors.textPrimary, size: iconSize),
          ),
        ),
      ),
    );
  }

  /// Opens the combined Appearance + Language sheet. Public so screens that
  /// already own a header icon can trigger it directly.
  static Future<void> showQuickSettings(BuildContext context) {
    final colors = context.psColors;
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sheetColors = Theme.of(ctx).extension<PayspinSemanticColors>() ?? colors;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final l10n = PayspinLocalizations.of(ctx);
            final themeMode = sl<ThemeModeController>().mode;
            final locale = sl<LocaleController>().locale;
            final modeKey = switch (themeMode) {
              ThemeMode.dark => 'dark',
              ThemeMode.light => 'light',
              ThemeMode.system => 'system',
            };

            Widget tile({
              required IconData icon,
              required String title,
              required String value,
              required Future<void> Function() onTap,
            }) {
              return ListTile(
                leading: Icon(icon, color: sheetColors.textPrimary),
                title: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: sheetColors.textPrimary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: sheetColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: sheetColors.textMuted, size: 20),
                  ],
                ),
                onTap: () async {
                  await onTap();
                  // Reflect the new selection without closing the sheet.
                  if (ctx.mounted) setSheetState(() {});
                },
              );
            }

            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                    child: Text(
                      l10n.preferences,
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: sheetColors.textPrimary,
                      ),
                    ),
                  ),
                  tile(
                    icon: Icons.brightness_6_outlined,
                    title: l10n.appearance,
                    value: l10n.themeModeLabel(modeKey),
                    onTap: () => PayspinPreferencesSheets.showAppearance(ctx),
                  ),
                  tile(
                    icon: Icons.language_outlined,
                    title: l10n.language,
                    value: l10n.languageName(locale.languageCode),
                    onTap: () => PayspinPreferencesSheets.showLanguage(ctx),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

extension PayspinQuickSettingsContext on BuildContext {
  Future<void> showQuickSettingsSheet() =>
      PayspinQuickSettings.showQuickSettings(this);
}
