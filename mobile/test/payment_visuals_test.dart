import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/tokens/payspin_tokens.dart';
import 'package:payspin_mobile/core/utils/payment_visuals.dart';

void main() {
  group('PaymentVisuals.emoji — keyword based, not random', () {
    test('matches food keywords', () {
      expect(PaymentVisuals.emoji('Pizza night with friends'), '🍕');
      expect(PaymentVisuals.emoji('Sushi 🍣'), '🍣');
      expect(PaymentVisuals.emoji('Burger King'), '🍔');
      expect(PaymentVisuals.emoji('Friet en snacks'), '🍟');
      expect(PaymentVisuals.emoji('Shoarma'), '🥙');
    });

    test('matches drinks', () {
      expect(PaymentVisuals.emoji('Koffie bij Starbucks'), '☕');
      expect(PaymentVisuals.emoji('Biertje in de kroeg'), '🍺');
      expect(PaymentVisuals.emoji('Wine tasting'), '🍷');
    });

    test('matches transport', () {
      expect(PaymentVisuals.emoji('Uber ride home'), '🚕');
      expect(PaymentVisuals.emoji('Taxi'), '🚕');
      expect(PaymentVisuals.emoji('Benzine tanken'), '⛽');
      expect(PaymentVisuals.emoji('Vlucht naar Spanje'), '✈️');
      expect(PaymentVisuals.emoji('Parkeren in de garage'), '🅿️');
    });

    test('matches entertainment and shopping', () {
      expect(PaymentVisuals.emoji('Movie tickets'), '🎬');
      expect(PaymentVisuals.emoji('Concert ticket'), '🎵');
      expect(PaymentVisuals.emoji('Boodschappen Albert Heijn'), '🛒');
      expect(PaymentVisuals.emoji('Verjaardag cadeau'), '🎂');
    });

    test('is case-insensitive', () {
      expect(PaymentVisuals.emoji('PIZZA'), '🍕');
      expect(PaymentVisuals.emoji('pIzZa'), '🍕');
    });

    test('is deterministic for the same description', () {
      const desc = 'Random thing 12345';
      expect(PaymentVisuals.emoji(desc), PaymentVisuals.emoji(desc));
    });

    test('falls back for empty or unmatched descriptions', () {
      expect(PaymentVisuals.emoji(null), isNotEmpty);
      expect(PaymentVisuals.emoji(''), isNotEmpty);
      expect(PaymentVisuals.emoji('   '), isNotEmpty);
      // Unmatched text still returns a non-empty emoji.
      expect(PaymentVisuals.emoji('zxqwv'), isNotEmpty);
    });
  });

  group('PaymentVisuals.linkStatusColor', () {
    test('settled / paid is green', () {
      expect(PaymentVisuals.linkStatusColor('SETTLED'), PayspinTokens.green);
      expect(
        PaymentVisuals.linkStatusColor('ACTIVE', hasCompletedPayments: true),
        PayspinTokens.green,
      );
    });

    test('open states use brand accents', () {
      expect(PaymentVisuals.linkStatusColor('ACTIVE'), PayspinTokens.mint);
      expect(PaymentVisuals.linkStatusColor('COLLECTING'), PayspinTokens.blue);
    });

    test('ended states are muted / error', () {
      expect(PaymentVisuals.linkStatusColor('EXPIRED'), PayspinTokens.textMuted);
      expect(PaymentVisuals.linkStatusColor('CANCELLED'), PayspinTokens.pink);
    });
  });

  group('PaymentVisuals.recordStatusColor', () {
    test('completed is green', () {
      expect(PaymentVisuals.recordStatusColor('COMPLETED'), PayspinTokens.green);
    });

    test('in-flight states are mustard', () {
      expect(PaymentVisuals.recordStatusColor('PENDING'), PayspinTokens.mustard);
      expect(PaymentVisuals.recordStatusColor('PROCESSING'), PayspinTokens.mustard);
      expect(PaymentVisuals.recordStatusColor('AWAITING_AUTHORIZATION'), PayspinTokens.mustard);
    });

    test('failed / cancelled are error', () {
      expect(PaymentVisuals.recordStatusColor('FAILED'), PayspinTokens.pink);
      expect(PaymentVisuals.recordStatusColor('CANCELLED'), PayspinTokens.pink);
    });
  });
}
