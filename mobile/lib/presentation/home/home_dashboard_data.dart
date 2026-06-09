import '../../core/utils/payment_visuals.dart';
import '../../domain/entities/payment_link.dart';

/// The heuristic recommended cards shown on Home. Pure enum so the selection
/// logic stays testable without widgets.
enum HomeRecommendation { requestAgain, groepies, dinner }

/// Pure, testable derivation of the Home dashboard sections from the raw link
/// list + locally pinned favorite IDs. No backend, no widgets.
class HomeDashboard {
  const HomeDashboard({
    required this.sorted,
    required this.activeHero,
    required this.activeProgress,
    required this.activeProgressIsCapped,
    required this.favorites,
    required this.recommended,
    required this.recent,
    required this.shareTarget,
    required this.requestAgainSource,
  });

  /// All links, newest first.
  final List<PaymentLink> sorted;

  /// At most one highlighted request, or null.
  final PaymentLink? activeHero;

  /// 0..1 fraction for a capped MULTI hero; null when uncapped/SINGLE.
  final double? activeProgress;
  final bool activeProgressIsCapped;

  final List<PaymentLink> favorites;
  final List<HomeRecommendation> recommended;

  /// Recent list with the active hero + favorites removed (no duplicate cards).
  final List<PaymentLink> recent;

  /// Most-recent payable link, used by "Share last" + share recommendation.
  final PaymentLink? shareTarget;

  /// Newest SETTLED link with a description — drives "Request again".
  final PaymentLink? requestAgainSource;

  static const int maxFavoritesShown = 8;
  static const int maxRecommended = 2;

  static DateTime? _parse(String iso) => DateTime.tryParse(iso);

  static List<PaymentLink> _sortByCreatedDesc(List<PaymentLink> links) {
    final copy = [...links];
    copy.sort((a, b) {
      final da = _parse(a.createdAt);
      final db = _parse(b.createdAt);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return copy;
  }

  factory HomeDashboard.from(List<PaymentLink> links, Set<String> favoriteIds, {DateTime? now}) {
    final today = now ?? DateTime.now();
    final sorted = _sortByCreatedDesc(links);

    // 1) Active hero — at most one, MULTI collecting first.
    PaymentLink? hero;
    double? progress;
    var capped = false;

    for (final l in sorted) {
      final open = l.status == 'COLLECTING' || l.status == 'ACTIVE';
      if (l.isMulti && open && !l.isExpired) {
        final max = l.maxUses;
        if (max == null || l.useCount < max) {
          hero = l;
          if (max != null && max > 0) {
            progress = (l.useCount / max).clamp(0.0, 1.0);
            capped = true;
          }
          break;
        }
      }
    }
    if (hero == null) {
      for (final l in sorted) {
        if (!l.isMulti && l.status == 'ACTIVE' && l.amountCents != null && !l.isExpired) {
          final created = _parse(l.createdAt);
          if (created != null && today.difference(created).inDays < 7) {
            hero = l;
            break;
          }
        }
      }
    }

    // 2) Favorites (preserve newest-first ordering of the loaded set).
    final favorites = sorted.where((l) => favoriteIds.contains(l.id)).take(maxFavoritesShown).toList();

    // 3) Share + request-again sources.
    final shareTarget = sorted.where((l) => l.isPayable).firstOrNull;
    final requestAgainSource = sorted
        .where((l) => l.status == 'SETTLED' && (l.description?.trim().isNotEmpty ?? false))
        .firstOrNull;

    // 4) Recommended cards (≤2, deduped by type).
    final recommended = <HomeRecommendation>[];
    if (requestAgainSource != null) recommended.add(HomeRecommendation.requestAgain);
    if (links.isNotEmpty) recommended.add(HomeRecommendation.groepies);
    if (links.length >= 2 && _hasFoodLink(links)) recommended.add(HomeRecommendation.dinner);
    final trimmedRecommended = recommended.take(maxRecommended).toList();

    // 5) Recent — exclude hero + favorites so cards never repeat.
    final excluded = <String>{if (hero != null) hero.id, ...favorites.map((f) => f.id)};
    final recent = sorted.where((l) => !excluded.contains(l.id)).toList();

    return HomeDashboard(
      sorted: sorted,
      activeHero: hero,
      activeProgress: progress,
      activeProgressIsCapped: capped,
      favorites: favorites,
      recommended: trimmedRecommended,
      recent: recent,
      shareTarget: shareTarget,
      requestAgainSource: requestAgainSource,
    );
  }

  static bool _hasFoodLink(List<PaymentLink> links) {
    const foodEmojis = {'🍕', '🍣', '🍔', '🌮', '🍝', '🍜', '🍛', '🍗', '🍟', '🥙', '🍱', '🥪', '🍰', '🍦', '🥞', '🍫', '🍩', '🍿', '🍽️'};
    for (final l in links) {
      if (foodEmojis.contains(PaymentVisuals.emoji(l.description ?? ''))) return true;
    }
    return false;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}
