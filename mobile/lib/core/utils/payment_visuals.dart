import 'package:flutter/material.dart';

import '../design_system/tokens/payspin_tokens.dart';

/// Maps a payment description and status to its on-screen visuals: a category
/// emoji chosen from the words in the description, and a status color.
///
/// The emoji is *deterministic* — the same description always yields the same
/// icon — and *meaningful*: "Pizza night" → 🍕, "Uber home" → 🚕. When nothing
/// matches we fall back to a stable emoji derived from the text so different
/// links still look distinct rather than all sharing one generic icon.
abstract final class PaymentVisuals {
  /// Generic fallbacks used when no keyword matches. Picked deterministically
  /// from the description so a list of links stays visually varied.
  static const List<String> _fallbackEmojis = ['💸', '🧾', '💳', '🪙', '📦', '🎟️'];

  /// Ordered keyword → emoji rules. The first rule whose any keyword is found
  /// in the (lower-cased) description wins, so put more specific rules first.
  /// Keywords cover both English and Dutch since Payspin is NL-first.
  static const List<_IconRule> _rules = [
    // Food — specific dishes first so "pizza" beats the generic "dinner".
    _IconRule('🍕', ['pizza', 'pizzas', "pizza's", 'pizzeria']),
    _IconRule('🍣', ['sushi', 'sashimi', 'poke', 'poké']),
    _IconRule('🍔', ['burger', 'hamburger', 'cheeseburger', 'mcdonald', 'mcd', 'bigmac', 'whopper']),
    _IconRule('🌮', ['taco', 'tacos', 'burrito', 'mexican', 'mexicaans']),
    _IconRule('🍝', ['pasta', 'spaghetti', 'italian', 'italiaans']),
    _IconRule('🍜', ['ramen', 'noodles', 'noedels', 'pho', 'soup', 'soep']),
    _IconRule('🍛', ['curry', 'indian', 'indiaas', 'thai', 'thais']),
    _IconRule('🍗', ['chicken', 'kip', 'kfc', 'wings']),
    _IconRule('🍟', ['fries', 'friet', 'patat', 'frietjes', 'fryd']),
    _IconRule('🥙', ['kebab', 'shoarma', 'shawarma', 'döner', 'doner', 'falafel', 'durum']),
    _IconRule('🍱', ['lunch', 'bento']),
    _IconRule('🥪', ['sandwich', 'broodje', 'tosti', 'lunchroom']),
    _IconRule('🍰', ['cake', 'taart', 'dessert', 'gebak', 'pie']),
    _IconRule('🍦', ['ice cream', 'icecream', 'ijs', 'ijsje', 'gelato']),
    _IconRule('🥞', ['pancake', 'pannenkoek', 'poffertjes', 'brunch']),
    _IconRule('🍫', ['chocolate', 'chocola', 'candy', 'snoep', 'sweets']),
    _IconRule('🍩', ['donut', 'doughnut']),
    _IconRule('🍿', ['popcorn']),
    _IconRule('🍽️', ['dinner', 'diner', 'restaurant', 'eten', 'meal', 'food', 'lunch', 'brasserie', 'bistro']),

    // Drinks.
    _IconRule('☕', ['coffee', 'koffie', 'latte', 'cappuccino', 'espresso', 'starbucks', 'flat white', 'mocha']),
    _IconRule('🍵', ['tea', 'thee', 'matcha']),
    _IconRule('🍺', ['beer', 'bier', 'pint', 'pub', 'borrel', 'biertje', 'brewery', 'brouwerij']),
    _IconRule('🍷', ['wine', 'wijn', 'rosé', 'rose wine', 'prosecco', 'champagne']),
    _IconRule('🍸', ['cocktail', 'cocktails', 'gin', 'martini', 'mojito']),
    _IconRule('🥤', ['soda', 'cola', 'frisdrank', 'smoothie', 'milkshake', 'drink', 'drinks', 'drankjes']),

    // Transport.
    _IconRule('🚕', ['taxi', 'uber', 'bolt', 'cab', 'ride', 'rit', 'lyft']),
    _IconRule('⛽', ['fuel', 'gas', 'petrol', 'benzine', 'tank', 'tanken', 'diesel', 'shell', 'bp', 'esso']),
    _IconRule('🅿️', ['parking', 'parkeren', 'parkeer', 'garage', 'park']),
    _IconRule('🚆', ['train', 'trein', 'ns ', ' ns', 'ov-chip', 'ovchip', 'intercity', 'sprinter']),
    _IconRule('🚌', ['bus', 'tram', 'metro', 'gvb', 'ret', ' ov', 'ov ', 'public transport', 'openbaar vervoer']),
    _IconRule('🚲', ['bike', 'fiets', 'cycle', 'swapfiets', 'ov-fiets']),
    _IconRule('✈️', ['flight', 'vlucht', 'plane', 'vliegtuig', 'airport', 'vliegveld', 'klm', 'ryanair', 'easyjet', 'transavia']),
    _IconRule('🚗', ['car', 'auto', 'rental car', 'huurauto', 'greenwheels', 'sixt', 'carpool']),

    // Travel & stay.
    _IconRule('🏨', ['hotel', 'airbnb', 'hostel', 'booking', 'stay', 'overnachting', 'accommodation']),
    _IconRule('🏖️', ['vacation', 'vakantie', 'holiday', 'beach', 'strand', 'trip', 'reis', 'travel', 'tripje', 'roadtrip']),
    _IconRule('⛺', ['camping', 'camp', 'tent', 'festival camping']),

    // Entertainment.
    _IconRule('🎬', ['movie', 'cinema', 'film', 'bioscoop', 'pathe', 'pathé', 'netflix', 'kino']),
    _IconRule('🎵', ['concert', 'festival', 'gig', 'spotify', 'music', 'muziek', 'lowlands', 'tomorrowland']),
    _IconRule('🎫', ['ticket', 'tickets', 'kaartjes', 'kaartje', 'entree', 'entry']),
    _IconRule('🎮', ['game', 'games', 'gaming', 'playstation', 'xbox', 'nintendo', 'steam']),
    _IconRule('🎳', ['bowling', 'bowlen']),
    _IconRule('🎤', ['karaoke']),
    _IconRule('🎉', ['party', 'feest', 'celebration', 'feestje']),
    _IconRule('🎂', ['birthday', 'verjaardag', 'jarig', 'bday']),
    _IconRule('🎁', ['gift', 'present', 'cadeau', 'cadeautje', 'kado', 'sinterklaas', 'kerstcadeau']),

    // Shopping.
    _IconRule('🛒', ['groceries', 'grocery', 'boodschappen', 'supermarket', 'supermarkt', 'albert heijn', 'jumbo', 'lidl', 'aldi', 'ah ', ' ah', 'plus']),
    _IconRule('🛍️', ['shopping', 'clothes', 'kleding', 'shoes', 'schoenen', 'zalando', 'fashion', 'shirt', 'jacket', 'jas']),
    _IconRule('📦', ['amazon', 'bol.com', 'bol ', 'package', 'pakket', 'order', 'bestelling', 'coolblue']),
    _IconRule('💐', ['flowers', 'bloemen', 'boeket', 'bouquet']),
    _IconRule('📚', ['book', 'books', 'boek', 'boeken', 'study', 'studie', 'college', 'school', 'tuition', 'cursus', 'course']),

    // Home & bills.
    _IconRule('🏠', ['rent', 'huur', 'house', 'huis', 'apartment', 'appartement', 'mortgage', 'hypotheek', 'kamer']),
    _IconRule('💡', ['electricity', 'energy', 'energie', 'stroom', 'utilities', 'nuts', 'eneco', 'vattenfall', 'gas bill']),
    _IconRule('💧', ['water', 'waterbill', 'waterrekening']),
    _IconRule('🌐', ['internet', 'wifi', 'ziggo', 'kpn', 'broadband']),
    _IconRule('📱', ['phone bill', 'telefoon', 'simkaart', 'sim', 'abonnement', 'subscription', 'vodafone']),
    _IconRule('🧹', ['cleaning', 'schoonmaak', 'schoonmaken', 'huishoudster']),
    _IconRule('🛠️', ['repair', 'reparatie', 'fix', 'klusjes', 'handyman', 'tools', 'gereedschap']),

    // Health & care.
    _IconRule('💊', ['pharmacy', 'apotheek', 'medicine', 'medicijn', 'doctor', 'dokter', 'huisarts', 'tandarts', 'dentist']),
    _IconRule('💇', ['haircut', 'kapper', 'barber', 'salon', 'knippen', 'hairdresser']),
    _IconRule('💅', ['nails', 'nagels', 'manicure', 'beauty', 'spa', 'massage']),
    _IconRule('🏋️', ['gym', 'fitness', 'workout', 'sportschool', 'crossfit', 'basic-fit', 'basic fit']),
    _IconRule('⚽', ['football', 'voetbal', 'soccer', 'sport', 'tennis', 'padel', 'hockey']),

    // Pets & misc.
    _IconRule('🐾', ['pet', 'dog', 'hond', 'cat', 'kat', 'vet', 'dierenarts', 'puppy', 'huisdier']),
    _IconRule('❤️', ['charity', 'donation', 'donatie', 'goede doel', 'gift aid', 'collecte', 'sponsor']),
    _IconRule('💰', ['savings', 'sparen', 'loan', 'lening', 'debt', 'schuld', 'borrow', 'geleend', 'lenen', 'terugbetaling', 'repay', 'payback']),
    _IconRule('💼', ['work', 'werk', 'office', 'kantoor', 'business', 'invoice', 'factuur', 'freelance', 'zzp']),
    _IconRule('🚬', ['smoke', 'sigaret', 'tabak', 'vape']),
    _IconRule('🎓', ['graduation', 'afstuderen', 'diploma']),
    _IconRule('💍', ['wedding', 'bruiloft', 'trouwen', 'engagement', 'verloving']),
    _IconRule('🍼', ['baby', 'kraamcadeau', 'luiers', 'diapers']),
    _IconRule('🎄', ['christmas', 'kerst', 'kerstmis', 'xmas']),
  ];

  /// Returns the most relevant emoji for [description].
  static String emoji(String? description) {
    final text = (description ?? '').toLowerCase().trim();
    if (text.isEmpty) return _fallbackEmojis.first;
    for (final rule in _rules) {
      for (final keyword in rule.keywords) {
        if (text.contains(keyword)) return rule.emoji;
      }
    }
    return _fallbackEmojis[description!.hashCode.abs() % _fallbackEmojis.length];
  }

  /// Status color for a payment *link* (backend `PaymentLinkStatus`).
  /// "Paid"/settled is green; open/active states use brand accents; ended
  /// states are muted/error.
  static Color linkStatusColor(String status, {bool hasCompletedPayments = false}) {
    if (hasCompletedPayments) return PayspinTokens.green;
    switch (status) {
      case 'SETTLED':
        return PayspinTokens.green;
      case 'ACTIVE':
        return PayspinTokens.mint;
      case 'COLLECTING':
        return PayspinTokens.blue;
      case 'EXPIRED':
        return PayspinTokens.textMuted;
      case 'CANCELLED':
        return PayspinTokens.pink;
      default:
        return PayspinTokens.mint;
    }
  }

  /// Status color for a single payment record (backend `PaymentStatus`).
  static Color recordStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return PayspinTokens.green;
      case 'AWAITING_AUTHORIZATION':
      case 'PENDING':
      case 'PROCESSING':
        return PayspinTokens.mustard;
      case 'FAILED':
      case 'CANCELLED':
        return PayspinTokens.pink;
      default:
        return PayspinTokens.mint;
    }
  }
}

class _IconRule {
  const _IconRule(this.emoji, this.keywords);
  final String emoji;
  final List<String> keywords;
}
