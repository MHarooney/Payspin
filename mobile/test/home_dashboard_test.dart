import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/domain/entities/payment_link.dart';
import 'package:payspin_mobile/presentation/home/home_dashboard_data.dart';

PaymentLink link({
  required String id,
  String status = 'ACTIVE',
  String linkType = 'SINGLE',
  int? amountCents = 1000,
  String? description = 'Dinner',
  int? maxUses,
  int useCount = 0,
  int completedPaymentCount = 0,
  DateTime? createdAt,
  String? expiresAt,
}) {
  return PaymentLink(
    id: id,
    shortCode: id,
    amountCents: amountCents,
    currency: 'EUR',
    description: description,
    status: status,
    createdAt: (createdAt ?? DateTime(2026, 6, 1)).toIso8601String(),
    payUrl: 'https://pay.test/$id',
    completedPaymentCount: completedPaymentCount,
    totalReceivedCents: 0,
    linkType: linkType,
    maxUses: maxUses,
    useCount: useCount,
    expiresAt: expiresAt,
  );
}

void main() {
  final now = DateTime(2026, 6, 9);

  test('empty links yields empty dashboard', () {
    final d = HomeDashboard.from(const [], const {}, now: now);
    expect(d.activeHero, isNull);
    expect(d.favorites, isEmpty);
    expect(d.recommended, isEmpty);
    expect(d.recent, isEmpty);
    expect(d.shareTarget, isNull);
  });

  test('sorts links newest first', () {
    final d = HomeDashboard.from([
      link(id: 'old', createdAt: DateTime(2026, 5, 1)),
      link(id: 'new', createdAt: DateTime(2026, 6, 8)),
    ], const {}, now: now);
    expect(d.sorted.first.id, 'new');
  });

  test('MULTI collecting link becomes the active hero with capped progress', () {
    final d = HomeDashboard.from([
      link(id: 'm', linkType: 'MULTI', status: 'COLLECTING', maxUses: 3, useCount: 2, createdAt: DateTime(2026, 6, 8)),
      link(id: 's', status: 'ACTIVE', createdAt: DateTime(2026, 6, 7)),
    ], const {}, now: now);
    expect(d.activeHero?.id, 'm');
    expect(d.activeProgressIsCapped, isTrue);
    expect(d.activeProgress, closeTo(2 / 3, 0.0001));
    // Hero excluded from recent.
    expect(d.recent.any((l) => l.id == 'm'), isFalse);
  });

  test('uncapped MULTI hero has null progress', () {
    final d = HomeDashboard.from([
      link(id: 'm', linkType: 'MULTI', status: 'ACTIVE', maxUses: null, useCount: 4, createdAt: DateTime(2026, 6, 8)),
    ], const {}, now: now);
    expect(d.activeHero?.id, 'm');
    expect(d.activeProgress, isNull);
    expect(d.activeProgressIsCapped, isFalse);
  });

  test('fully-used capped MULTI is not a hero', () {
    final d = HomeDashboard.from([
      link(id: 'm', linkType: 'MULTI', status: 'COLLECTING', maxUses: 3, useCount: 3, createdAt: DateTime(2026, 6, 8)),
    ], const {}, now: now);
    expect(d.activeHero, isNull);
  });

  test('falls back to recent SINGLE active link as hero, but not stale ones', () {
    final fresh = HomeDashboard.from([
      link(id: 's', status: 'ACTIVE', createdAt: DateTime(2026, 6, 8)),
    ], const {}, now: now);
    expect(fresh.activeHero?.id, 's');

    final stale = HomeDashboard.from([
      link(id: 's', status: 'ACTIVE', createdAt: DateTime(2026, 5, 1)),
    ], const {}, now: now);
    expect(stale.activeHero, isNull);
  });

  test('favorites strip filters by pinned ids and excludes them from recent', () {
    final d = HomeDashboard.from([
      link(id: 'a', status: 'SETTLED', createdAt: DateTime(2026, 6, 8)),
      link(id: 'b', status: 'SETTLED', createdAt: DateTime(2026, 6, 7)),
    ], {'a'}, now: now);
    expect(d.favorites.map((l) => l.id), ['a']);
    expect(d.recent.any((l) => l.id == 'a'), isFalse);
  });

  test('share target is the most recent payable link', () {
    final d = HomeDashboard.from([
      link(id: 'settled', status: 'SETTLED', createdAt: DateTime(2026, 6, 8)),
      link(id: 'active', status: 'ACTIVE', createdAt: DateTime(2026, 6, 7)),
    ], const {}, now: now);
    expect(d.shareTarget?.id, 'active');
  });

  test('recommended: request-again from settled + groepies, capped at 2', () {
    final d = HomeDashboard.from([
      link(id: 'a', status: 'SETTLED', description: 'Pizza night', createdAt: DateTime(2026, 6, 8)),
      link(id: 'b', status: 'ACTIVE', description: 'Sushi', createdAt: DateTime(2026, 6, 7)),
    ], const {}, now: now);
    expect(d.requestAgainSource?.id, 'a');
    expect(d.recommended.length, lessThanOrEqualTo(2));
    expect(d.recommended.first, HomeRecommendation.requestAgain);
    expect(d.recommended.contains(HomeRecommendation.groepies), isTrue);
  });
}
