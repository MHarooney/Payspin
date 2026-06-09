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

    test('Dutch home dashboard strings', () {
      const l10n = PayspinLocalizations(Locale('nl'));
      expect(l10n.quickActionNewLink, 'Nieuwe link');
      expect(l10n.quickActionShareLast, 'Laatste delen');
      expect(l10n.sectionFavorites, 'Favorieten');
      expect(l10n.sectionRecommended, 'Aanbevolen voor jou');
      expect(l10n.sectionRecentLinks, 'Recente links');
      expect(l10n.paidOfTotal(2, 3), '2 van 3 betaald');
      expect(l10n.homeGreeting(9), 'Goedemorgen');
      expect(l10n.homeGreeting(20), 'Goedenavond');
      expect(l10n.copyLink, 'Link kopiëren');
    });

    test('English home greeting buckets', () {
      const l10n = PayspinLocalizations(Locale('en'));
      expect(l10n.homeGreeting(8), 'Good morning');
      expect(l10n.homeGreeting(14), 'Good afternoon');
      expect(l10n.homeGreeting(22), 'Good evening');
      expect(l10n.homeGreeting(14, name: 'Karim'), 'Good afternoon, Karim');
      expect(l10n.homeGreeting(14, name: '  '), 'Good afternoon');
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
