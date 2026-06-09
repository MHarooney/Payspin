import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_active_request_hero.dart';
import '../../core/design_system/widgets/payspin_empty_state.dart';
import '../../core/design_system/widgets/payspin_favorite_link_card.dart';
import '../../core/design_system/widgets/payspin_glass_icon_button.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_home_section_header.dart';
import '../../core/design_system/widgets/payspin_brand_mark.dart';
import '../../core/design_system/widgets/payspin_promo_gradient_card.dart';
import '../../core/design_system/widgets/payspin_skeleton.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/design_system/widgets/payspin_tikkie_row.dart';
import '../../core/errors/api_exception.dart';
import '../../core/state/links_refresh_notifier.dart';
import '../../core/storage/favorite_links_store.dart';
import '../../data/services/share_service.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/payment_link_repository.dart';
import '../notifications/notification_bell.dart';
import 'home_dashboard_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PaymentLink> _links = [];
  bool _loading = true;
  String? _error;
  bool _searchOpen = false;
  String _query = '';

  final LinksRefreshNotifier _refresh = sl<LinksRefreshNotifier>();
  final FavoriteLinksStore _favorites = sl<FavoriteLinksStore>();

  @override
  void initState() {
    super.initState();
    // Reload when a link is created/cancelled elsewhere in the nav stack.
    _refresh.addListener(_onLinksChanged);
    // Favorites are local — rebuild the strip + stars when toggled anywhere.
    _favorites.addListener(_onFavoritesChanged);
    _load();
  }

  void _onLinksChanged() {
    if (mounted) _load();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refresh.removeListener(_onLinksChanged);
    _favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _links = await sl<PaymentLinkRepository>().listLinks();
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PaymentLink> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _links;
    return _links.where((l) {
      return (l.description ?? '').toLowerCase().contains(q) ||
          l.amountLabel.toLowerCase().contains(q) ||
          l.shortCode.contains(q);
    }).toList();
  }

  Future<void> _toggleFavorite(PaymentLink link) async {
    final added = await _favorites.toggle(link.id);
    if (!added && mounted) showPayspinSnackBar(context, context.l10n.favoritesFull);
  }

  Future<void> _copyLink(PaymentLink link) async {
    await Clipboard.setData(ClipboardData(text: link.payUrl));
    if (!mounted) return;
    showPayspinSnackBar(context, context.l10n.linkCopied, success: true);
  }

  void _shareLink(PaymentLink link) {
    final share = ShareService();
    share.shareWhatsApp(share.buildMessage(
      amountLabel: link.amountLabel,
      description: link.description ?? '',
      payUrl: link.payUrl,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: PayspinTokens.pink,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          ..._content(),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          children: [
            Row(
              children: [
                PayspinGlassIconButton(
                  icon: Icons.qr_code_2,
                  semanticLabel: l10n.navScanQr,
                  bordered: false,
                  onPressed: () => context.push('/scan'),
                ),
                PayspinGlassIconButton(
                  icon: _searchOpen ? Icons.close_rounded : Icons.search,
                  semanticLabel: l10n.searchTikkies,
                  bordered: false,
                  onPressed: () => setState(() => _searchOpen = !_searchOpen),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PayspinBrandMark.inline(
                        size: 22,
                        emblemStyle: isDark ? PayspinEmblemStyle.gradient : null,
                      ),
                      const SizedBox(width: 8),
                      const PayspinGradientText('Payspin', wordmark: true, style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
                NotificationBell(bordered: false, onTap: () => context.push('/notifications')),
                const SizedBox(width: 4),
                PayspinGlassIconButton(
                  icon: Icons.person_rounded,
                  semanticLabel: l10n.navProfile,
                  bordered: false,
                  onPressed: () => context.go('/home/profile'),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _searchOpen
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: PayspinGlassSurface(
                        tier: PayspinGlassTier.raised,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          autofocus: true,
                          onChanged: (v) => setState(() => _query = v),
                          style: GoogleFonts.inter(color: context.psColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: l10n.searchTikkies,
                            prefixIcon: Icon(Icons.search, color: context.psColors.textMuted, size: 20),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  /// The body slivers: loading skeleton, error, empty, search results, or the
  /// full premium dashboard.
  List<Widget> _content() {
    if (_loading) return [_loadingSliver()];
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: PayspinEmptyState(
            emoji: '😕',
            title: context.l10n.errorTitle,
            subtitle: _error!,
            primary: PayspinGradientPillButton(label: context.l10n.tryAgain, onPressed: _load),
          ),
        ),
      ];
    }

    // Search mode — sections hidden, filtered list only.
    if (_query.trim().isNotEmpty) {
      final filtered = _filtered;
      if (filtered.isEmpty) {
        return [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(context.l10n.noSearchResults, style: TextStyle(color: context.psColors.textMuted)),
              ),
            ),
          ),
        ];
      }
      return [_recentListSliver(filtered, header: false)];
    }

    if (_links.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: _emptyState())];
    }

    final data = HomeDashboard.from(_links, _favorites.ids);
    return _dashboardSlivers(data);
  }

  List<Widget> _dashboardSlivers(HomeDashboard data) {
    final l10n = context.l10n;
    final slivers = <Widget>[];

    void section(Widget child, {EdgeInsets padding = const EdgeInsets.fromLTRB(20, 0, 20, 24)}) {
      slivers.add(SliverPadding(padding: padding, sliver: SliverToBoxAdapter(child: child)));
    }

    // Greeting.
    section(
      _greeting(l10n),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
    );

    // Active request hero.
    if (data.activeHero != null) {
      section(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PayspinHomeSectionHeader(title: l10n.sectionActiveRequest),
            _activeHero(data),
          ],
        ),
      );
    }

    // Favorites.
    if (data.favorites.isNotEmpty) {
      slivers.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: PayspinHomeSectionHeader(title: l10n.sectionFavorites),
        ),
      ));
      slivers.add(SliverToBoxAdapter(child: _favoritesStrip(data)));
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 24)));
    }

    // Recommended.
    if (data.recommended.isNotEmpty) {
      section(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PayspinHomeSectionHeader(title: l10n.sectionRecommended),
            for (var i = 0; i < data.recommended.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              _recommendedCard(data.recommended[i], data, l10n),
            ],
          ],
        ),
      );
    }

    // Recent links header.
    slivers.add(SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: PayspinHomeSectionHeader(title: l10n.sectionRecentLinks),
      ),
    ));
    slivers.add(_recentListSliver(data.recent, header: true));
    return slivers;
  }

  Widget _greeting(PayspinLocalizations l10n) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        l10n.homeGreeting(DateTime.now().hour),
        style: GoogleFonts.inter(fontSize: 13, color: context.psColors.textMuted, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _activeHero(HomeDashboard data) {
    final l10n = context.l10n;
    final hero = data.activeHero!;
    String? progressLabel;
    if (hero.isMulti) {
      if (data.activeProgressIsCapped && hero.maxUses != null) {
        progressLabel = l10n.paidOfTotal(hero.useCount, hero.maxUses!);
      } else {
        progressLabel = l10n.receivedCount(hero.useCount);
      }
    }
    return PayspinActiveRequestHero(
      link: hero,
      progress: data.activeProgress,
      progressLabel: progressLabel,
      onTap: () => context.push('/links/${hero.id}'),
    );
  }

  Widget _favoritesStrip(HomeDashboard data) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: data.favorites.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final link = data.favorites[i];
          return PayspinFavoriteLinkCard(
            link: link,
            tintIndex: i,
            onTap: () => context.push('/links/${link.id}'),
            onUnfavorite: () => _toggleFavorite(link),
          );
        },
      ),
    );
  }

  Widget _recommendedCard(HomeRecommendation rec, HomeDashboard data, PayspinLocalizations l10n) {
    switch (rec) {
      case HomeRecommendation.requestAgain:
        final desc = data.requestAgainSource?.description?.trim() ?? '';
        return PayspinPromoGradientCard(
          icon: Icons.replay_rounded,
          title: l10n.recRequestAgainTitle,
          subtitle: l10n.recRequestAgainSubtitle(desc),
          onTap: () => context.push('/send/amount'),
        );
      case HomeRecommendation.groepies:
        return PayspinPromoGradientCard(
          icon: Icons.groups_rounded,
          title: l10n.recGroepiesTitle,
          subtitle: l10n.recGroepiesSubtitle,
          onTap: () => context.push('/home/groepies'),
        );
      case HomeRecommendation.dinner:
        return PayspinPromoGradientCard(
          icon: Icons.restaurant_rounded,
          title: l10n.recDinnerTitle,
          subtitle: l10n.recDinnerSubtitle,
          onTap: () => context.push('/send/amount'),
        );
    }
  }

  Widget _recentListSliver(List<PaymentLink> links, {required bool header}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final link = links[i];
            return PayspinTikkieRow(
              link: link,
              tintIndex: i,
              isFavorite: _favorites.isFavorite(link.id),
              onToggleFavorite: () => _toggleFavorite(link),
              onCopy: () => _copyLink(link),
              onShare: link.isPayable ? () => _shareLink(link) : null,
              onTap: () => context.push('/links/${link.id}'),
            );
          },
          childCount: links.length,
        ),
      ),
    );
  }

  Widget _loadingSliver() {
    return const SliverPadding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 120),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active-hero placeholder.
            PayspinSkeleton(width: double.infinity, height: 96, radius: 22),
            SizedBox(height: 24),
            PayspinSkeletonRow(),
            PayspinSkeletonRow(),
            PayspinSkeletonRow(),
            PayspinSkeletonRow(),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    final l10n = context.l10n;
    return PayspinEmptyState(
      emoji: '💸',
      title: l10n.emptyTikkiesTitle,
      subtitle: l10n.emptyTikkiesSubtitle,
      primary: PayspinGradientPillButton(
        label: l10n.createTikkie,
        icon: const Icon(Icons.add, color: PayspinTokens.onBrand, size: 20),
        onPressed: () => context.push('/send/amount'),
      ),
    );
  }
}
