import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/l10n/locale_controller.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PayspinLocalizations', () {
    test('Dutch QR strings', () {
      const l10n = PayspinLocalizations(Locale('nl'));
      expect(l10n.shareAgain, 'Opnieuw delen');
      expect(l10n.linkStatus('ACTIVE'), 'Actief');
      expect(l10n.validForDays(3), 'Nog 3 dagen geldig');
    });

    test('German QR strings', () {
      const l10n = PayspinLocalizations(Locale('de'));
      expect(l10n.scanToPay, 'Zum Bezahlen scannen');
      expect(l10n.shareAgain, 'Erneut teilen');
    });

    test('Arabic QR strings', () {
      const l10n = PayspinLocalizations(Locale('ar'));
      expect(l10n.shareAgain, 'شارك مرة أخرى');
      expect(l10n.linkStatus('ACTIVE'), 'نشط');
    });

    test('Dutch welcome and nav strings', () {
      const l10n = PayspinLocalizations(Locale('nl'));
      expect(l10n.getStarted, 'Aan de slag');
      expect(l10n.navScanQr, 'QR scannen');
    });
  });

  group('LocaleController', () {
    test('persists locale choice', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final controller = LocaleController(prefs);
      await controller.load();
      expect(controller.locale.languageCode, 'en');

      await controller.setLocale(const Locale('nl'));
      expect(controller.locale.languageCode, 'nl');
      expect(prefs.getString('payspin_locale'), 'nl');
      expect(controller.languageLabel, 'Nederlands');
    });
  });
}
