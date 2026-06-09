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
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_home_section_header.dart';
import '../../core/design_system/widgets/payspin_promo_gradient_card.dart';
import '../../core/design_system/widgets/payspin_skeleton.dart';
import '../../core/design_system/widgets/payspin_confirm_dialog.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/design_system/widgets/payspin_tikkie_row.dart';
import '../../core/design_system/widgets/payspin_peel_reveal.dart';
import '../../core/design_system/widgets/payspin_tikkie_slidable_row.dart';
import '../../core/errors/api_exception.dart';
import '../../core/state/links_refresh_notifier.dart';
import '../../core/storage/archived_links_store.dart';
import '../../core/storage/dismissed_recommendations_store.dart';
import '../../core/storage/favorite_links_store.dart';
import '../../core/design_system/widgets/payspin_share_sheet.dart';
import '../../core/design_system/widgets/payspin_morphing_sliver_header.dart';
import '../../core/design_system/widgets/payspin_shell_tab_headers.dart';
import '../send/request_again_flow.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/payment_link_repository.dart';
import '../notifications/notification_bell.dart';
import 'home_dashboard_data.dart';

enum RecentLinkFilter { all, active, paid }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<PaymentLink> _links = [];
  User? _user;
  bool _loading = true;
  String? _error;
  bool _searchOpen = false;
  String _query = '';
  RecentLinkFilter _recentFilter = RecentLinkFilter.all;
  String? _openPeelId;

  final LinksRefreshNotifier _refresh = sl<LinksRefreshNotifier>();
  final FavoriteLinksStore _favorites = sl<FavoriteLinksStore>();
  final ArchivedLinksStore _archived = sl<ArchivedLinksStore>();
  final DismissedRecommendationsStore _dismissed = sl<DismissedRecommendationsStore>();

  @override
  void initState() {
    super.initState();
    // Reload when a link is created/cancelled elsewhere in the nav stack.
    _refresh.addListener(_onLinksChanged);
    // Favorites are local — rebuild the strip + stars when toggled anywhere.
    _favorites.addListener(_onFavoritesChanged);
    _archived.addListener(_onArchivedChanged);
    _dismissed.addListener(_onDismissedChanged);
    _load();
  }

  void _onLinksChanged() {
    if (mounted) _load();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  void _onArchivedChanged() {
    if (mounted) setState(() {});
  }

  void _onDismissedChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refresh.removeListener(_onLinksChanged);
    _favorites.removeListener(_onFavoritesChanged);
    _archived.removeListener(_onArchivedChanged);
    _dismissed.removeListener(_onDismissedChanged);
    super.dispose();
  }

  void _setPeelOpen(String peelId, bool open) {
    setState(() => _openPeelId = open ? peelId : null);
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
    }
    try {
      _user = await sl<AuthRepository>().currentUser();
    } catch (_) {
      _user = null;
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
    setState(() => _openPeelId = null);
    showPayspinShareSheet(
      context,
      payload: ShareLinkPayload.fromLink(
        linkId: link.id,
        amountLabel: link.amountLabel,
        description: link.description,
        payUrl: link.payUrl,
        isPayable: link.isPayable,
      ),
      onShareDisabled: () => showPayspinSnackBar(context, context.l10n.linkCantBeShared),
    );
  }

  Future<void> _cancelLink(PaymentLink link) async {
    final l10n = context.l10n;
    final confirmed = await showPayspinConfirmDialog(
      context,
      title: l10n.cancelLinkTitle,
      message: l10n.cancelLinkMessage,
      confirmLabel: l10n.cancelLinkConfirm,
      cancelLabel: l10n.keepLink,
      destructive: true,
      icon: Icons.link_off,
    );
    if (!confirmed || !mounted) return;
    try {
      await sl<PaymentLinkRepository>().cancelLink(link.id);
      if (!mounted) return;
      showPayspinSnackBar(context, l10n.linkCancelled);
    } catch (e) {
      if (mounted) showPayspinSnackBar(context, apiErrorMessage(e));
    }
  }

  Future<void> _archiveLink(PaymentLink link) async {
    final l10n = context.l10n;
    await _archived.archive(link.id);
    if (!mounted) return;
    showPayspinSnackBar(
      context,
      l10n.hiddenFromRecent,
      actionLabel: l10n.undoHide,
      onAction: () => _archived.unarchive(link.id),
    );
  }

  List<PaymentLink> _filterRecentLinks(List<PaymentLink> links) {
    switch (_recentFilter) {
      case RecentLinkFilter.active:
        return links.where((l) => l.isPayable).toList();
      case RecentLinkFilter.paid:
        return links.where((l) => l.completedPaymentCount > 0).toList();
      case RecentLinkFilter.all:
        return links;
    }
  }

  void _openLinkActionsSheet(PaymentLink link) {
    showPayspinLinkActionsSheet(
      context,
      link: link,
      isFavorite: _favorites.isFavorite(link.id),
      onToggleFavorite: () => _toggleFavorite(link),
      onCopy: () => _copyLink(link),
      onShare: link.isPayable ? () => _shareLink(link) : null,
      onShowQr: () => context.push('/links/${link.id}/qr'),
      onRequestAgain: link.canRequestAgain ? () => RequestAgainFlow.launch(context, link) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (_openPeelId != null &&
            (notification is ScrollStartNotification || notification is ScrollUpdateNotification)) {
          setState(() => _openPeelId = null);
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: _load,
        color: PayspinTokens.pink,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            PayspinMorphingSliverHeader(
              expandedHeight: PayspinHomeShellHeaderMetrics.expanded(searchOpen: _searchOpen),
              collapsedHeight: PayspinHomeShellHeaderMetrics.collapsedHeight,
              freezeCollapse: _searchOpen,
              rebuildTrigger: Object.hash(_searchOpen, _loading, _error, _user?.id, _query),
              builder: (ctx, t, _) => PayspinHomeShellHeader(
                t: t,
                searchOpen: _searchOpen,
                greetingPhrase: !_loading && _error == null
                    ? ctx.l10n.homeGreeting(DateTime.now().hour)
                    : null,
                userName: _user?.greetingFirstName,
                onToggleSearch: () => setState(() => _searchOpen = !_searchOpen),
                onSearchChanged: (v) => setState(() => _query = v),
                notificationBell: NotificationBell(
                  bordered: false,
                  onTap: () => context.push('/notifications'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            ..._content(),
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
      return [_recentListSliver(filtered, animateEntrance: false)];
    }

    if (_links.isEmpty) {
      return [SliverFillRemaining(hasScrollBody: false, child: _emptyState())];
    }

    final data = HomeDashboard.from(
      _links,
      _favorites.ids,
      archivedIds: _archived.ids,
      dismissedRecommendations: _dismissed.ids,
    );
    return _dashboardSlivers(data);
  }

  List<Widget> _dashboardSlivers(HomeDashboard data) {
    final l10n = context.l10n;
    final slivers = <Widget>[];

    void section(Widget child, {EdgeInsets padding = const EdgeInsets.fromLTRB(20, 0, 20, 24)}) {
      slivers.add(SliverPadding(padding: padding, sliver: SliverToBoxAdapter(child: child)));
    }

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

    // Recent links header + filter chips.
    slivers.add(SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PayspinHomeSectionHeader(title: l10n.sectionRecentLinks),
            const SizedBox(height: 10),
            _recentFilterChips(l10n),
          ],
        ),
      ),
    ));
    slivers.add(_recentListSliver(_filterRecentLinks(data.recent)));
    return slivers;
  }

  Widget _recentFilterChips(PayspinLocalizations l10n) {
    final colors = context.psColors;
    Widget chip(RecentLinkFilter filter, String label) {
      final selected = _recentFilter == filter;
      return FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        labelStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: selected ? PayspinTokens.onBrand : colors.textBody,
        ),
        backgroundColor: colors.glassFill,
        selectedColor: PayspinTokens.pink,
        side: BorderSide(color: selected ? Colors.transparent : colors.glassBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        onSelected: (_) => setState(() => _recentFilter = filter),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(RecentLinkFilter.all, l10n.filterAll),
        chip(RecentLinkFilter.active, l10n.filterActive),
        chip(RecentLinkFilter.paid, l10n.filterPaid),
      ],
    );
  }

  Widget _buildSlidableLink({
    required String peelId,
    required PaymentLink link,
    required Widget Function(double revealProgress) content,
    double borderRadius = 18,
  }) {
    final l10n = context.l10n;
    return PayspinTikkieSlidableRow(
      link: link,
      borderRadius: borderRadius,
      isOpen: _openPeelId == peelId,
      onOpenChanged: (open) => _setPeelOpen(peelId, open),
      onCancel: link.canCancel ? () => _cancelLink(link) : null,
      onArchive: link.canCancel ? null : () => _archiveLink(link),
      onMore: () => _openLinkActionsSheet(link),
      cancelLabel: l10n.cancelLinkConfirm,
      archiveLabel: l10n.swipeHide,
      moreLabel: l10n.swipeMore,
      builder: content,
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
    return _buildSlidableLink(
      peelId: 'hero:${hero.id}',
      link: hero,
      borderRadius: 22,
      content: (revealProgress) => PayspinActiveRequestHero(
        link: hero,
        progress: data.activeProgress,
        progressLabel: progressLabel,
        onTap: () => context.push('/links/${hero.id}'),
        onCopy: () => _copyLink(hero),
        onShare: () => _shareLink(hero),
        onShareDisabled: () => showPayspinSnackBar(context, l10n.linkCantBeShared),
        swipeRevealProgress: revealProgress,
        useOpaqueSwipeBacking: true,
      ),
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
    final peelId = 'rec:${rec.name}';

    PayspinPromoGradientCard card(double revealProgress) {
      switch (rec) {
        case HomeRecommendation.requestAgain:
          final source = data.requestAgainSource;
          final desc = source?.description?.trim() ?? '';
          final subtitle = desc.isNotEmpty
              ? l10n.recRequestAgainSubtitle(desc)
              : l10n.recRequestAgainSubtitleAmount(source?.amountLabel ?? '');
          return PayspinPromoGradientCard(
            icon: Icons.replay_rounded,
            title: l10n.recRequestAgainTitle,
            subtitle: subtitle,
            onTap: () => RequestAgainFlow.launch(context, source!),
            swipeRevealProgress: revealProgress,
            useOpaqueSwipeBacking: true,
          );
        case HomeRecommendation.groepies:
          return PayspinPromoGradientCard(
            icon: Icons.groups_rounded,
            title: l10n.recGroepiesTitle,
            subtitle: l10n.recGroepiesSubtitle,
            onTap: () => context.push('/home/groepies'),
            swipeRevealProgress: revealProgress,
            useOpaqueSwipeBacking: true,
          );
        case HomeRecommendation.dinner:
          return PayspinPromoGradientCard(
            icon: Icons.restaurant_rounded,
            title: l10n.recDinnerTitle,
            subtitle: l10n.recDinnerSubtitle,
            onTap: () => context.push('/send/amount'),
            swipeRevealProgress: revealProgress,
            useOpaqueSwipeBacking: true,
          );
      }
    }

    return PayspinPeelReveal(
      peelId: peelId,
      isOpen: _openPeelId == peelId,
      onOpenChanged: (open) => _setPeelOpen(peelId, open),
      borderRadius: 20,
      actions: [
        PeelRevealAction(
          icon: Icons.close_rounded,
          label: l10n.dismissRecommendation,
          kind: PeelActionKind.dismiss,
          onTap: () => _dismissed.dismiss(rec),
        ),
      ],
      builder: card,
    );
  }

  Widget _recentListSliver(List<PaymentLink> links, {bool animateEntrance = true}) {
    final l10n = context.l10n;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final link = links[i];
            final row = _buildSlidableLink(
              peelId: link.id,
              link: link,
              content: (revealProgress) => PayspinTikkieRow(
                link: link,
                tintIndex: i,
                isFavorite: _favorites.isFavorite(link.id),
                onToggleFavorite: () => _toggleFavorite(link),
                onCopy: () => _copyLink(link),
                onShare: () => _shareLink(link),
                onShareDisabled: () => showPayspinSnackBar(context, l10n.linkCantBeShared),
                onShowQr: () => context.push('/links/${link.id}/qr'),
                onRequestAgain: link.canRequestAgain ? () => RequestAgainFlow.launch(context, link) : null,
                onTap: () => context.push('/links/${link.id}'),
                swipeRevealProgress: revealProgress,
                useOpaqueSwipeBacking: true,
              ),
            );

            if (!animateEntrance) return row;

            final staggerMs = (i.clamp(0, 7)) * 40;
            return TweenAnimationBuilder<double>(
              key: ValueKey('recent-enter-${link.id}'),
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 240 + staggerMs),
              curve: Curves.easeOutCubic,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
              ),
              child: row,
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
