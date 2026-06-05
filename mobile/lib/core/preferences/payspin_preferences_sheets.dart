import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../design_system/theme/payspin_semantic_colors.dart';
import '../design_system/theme/theme_mode_controller.dart';
import '../design_system/tokens/payspin_tokens.dart';
import '../l10n/locale_controller.dart';
import '../l10n/payspin_localizations.dart';

/// Appearance & language pickers — callable from **any** screen via [BuildContext].
abstract final class PayspinPreferencesSheets {
  static Future<void> showAppearance(BuildContext context) async {
    final controller = sl<ThemeModeController>();
    final colors = context.psColors;
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = PayspinLocalizations.of(ctx);
        final sheetColors = Theme.of(ctx).extension<PayspinSemanticColors>() ?? colors;

        Widget option(ThemeMode mode, String label, IconData icon) {
          final isSelected = controller.mode == mode;
          return ListTile(
            leading: Icon(icon, color: sheetColors.textPrimary),
            title: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: sheetColors.textPrimary,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_rounded, color: PayspinTokens.mint)
                : null,
            onTap: () => Navigator.pop(ctx, mode),
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
                  l10n.appearance,
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: sheetColors.textPrimary,
                  ),
                ),
              ),
              option(ThemeMode.system, l10n.themeSystem, Icons.brightness_auto_outlined),
              option(ThemeMode.light, l10n.themeLight, Icons.light_mode_outlined),
              option(ThemeMode.dark, l10n.themeDark, Icons.dark_mode_outlined),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) await controller.setMode(selected);
  }

  static Future<void> showLanguage(BuildContext context) async {
    final controller = sl<LocaleController>();
    final colors = context.psColors;
    final selected = await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: colors.bgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final l10n = PayspinLocalizations.of(ctx);
        final sheetColors = Theme.of(ctx).extension<PayspinSemanticColors>() ?? colors;

        Widget option(Locale locale) {
          final isSelected = controller.locale.languageCode == locale.languageCode;
          return ListTile(
            title: Text(
              l10n.languageName(locale.languageCode),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: sheetColors.textPrimary,
              ),
            ),
            trailing: isSelected
                ? const Icon(Icons.check_rounded, color: PayspinTokens.mint)
                : null,
            onTap: () => Navigator.pop(ctx, locale),
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
                  l10n.language,
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: sheetColors.textPrimary,
                  ),
                ),
              ),
              ...LocaleController.supportedLocales.map(option),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (selected != null) await controller.setLocale(selected);
  }
}

extension PayspinPreferencesContext on BuildContext {
  Future<void> showAppearanceSheet() => PayspinPreferencesSheets.showAppearance(this);

  Future<void> showLanguageSheet() => PayspinPreferencesSheets.showLanguage(this);
}
