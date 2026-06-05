import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_deals_placeholder.dart';
import '../../core/design_system/widgets/payspin_empty_state.dart';
import '../../core/design_system/widgets/payspin_glass_icon_button.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_groepies_promo_card.dart';
import '../../core/design_system/widgets/payspin_brand_mark.dart';
import '../../core/design_system/widgets/payspin_quick_settings.dart';
import '../../core/design_system/widgets/payspin_skeleton.dart';
import '../../core/design_system/widgets/payspin_tab_strip.dart';
import '../../core/design_system/widgets/payspin_tikkie_row.dart';
import '../../core/errors/api_exception.dart';
import '../../core/state/links_refresh_notifier.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/payment_link_repository.dart';
import '../notifications/notification_bell.dart';
import 'groepies_page.dart';

enum HomeTab { tikkies, deals, groepies }

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onTabChanged});

  final ValueChanged<HomeTab>? onTabChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeTab _tab = HomeTab.tikkies;
  List<PaymentLink> _links = [];
  bool _loading = true;
  String? _error;
  bool _searchOpen = false;
  String _query = '';

  final LinksRefreshNotifier _refresh = sl<LinksRefreshNotifier>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTabChanged?.call(_tab);
    });
    // Reload when a link is created/cancelled elsewhere in the nav stack.
    _refresh.addListener(_onLinksChanged);
    _load();
  }

  void _onLinksChanged() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    _refresh.removeListener(_onLinksChanged);
    super.dispose();
  }

  void _selectTab(HomeTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    widget.onTabChanged?.call(tab);
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
          SliverToBoxAdapter(child: _tabs()),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          if (_tab == HomeTab.deals)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: PayspinDealsPlaceholder(),
            )
          else if (_tab == HomeTab.groepies)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: GroepiesTabContent(),
            )
          else
            _tikkiesContent(),
        ],
      ),
    );
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

  Widget _header(BuildContext context) {
    final l10n = context.l10n;
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
                  onPressed: () => context.push('/scan'),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PayspinBrandMark.inline(size: 22),
                      const SizedBox(width: 8),
                      PayspinGradientText('Payspin', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                PayspinGlassIconButton(
                  icon: _searchOpen ? Icons.close_rounded : Icons.search,
                  semanticLabel: l10n.searchTikkies,
                  onPressed: () => setState(() => _searchOpen = !_searchOpen),
                ),
                const SizedBox(width: 8),
                const PayspinQuickSettings(rounded: true),
                const SizedBox(width: 8),
                NotificationBell(onTap: () => context.push('/notifications')),
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

  Widget _tabs() {
    final l10n = context.l10n;
    const tabs = [HomeTab.tikkies, HomeTab.deals, HomeTab.groepies];
    return PayspinTabStrip(
      labels: [l10n.tabTikkies, l10n.tabDeals, l10n.tabGroepies],
      selectedIndex: tabs.indexOf(_tab),
      onSelected: (i) => _selectTab(tabs[i]),
    );
  }

  Widget _tikkiesContent() {
    final filtered = _filtered;
    if (_loading) {
      return const SliverPadding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 120),
        sliver: SliverToBoxAdapter(
          child: Column(
            children: [
              PayspinSkeletonRow(),
              PayspinSkeletonRow(),
              PayspinSkeletonRow(),
              PayspinSkeletonRow(),
            ],
          ),
        ),
      );
    }
    if (_error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: PayspinEmptyState(
          emoji: '😕',
          title: context.l10n.errorTitle,
          subtitle: _error!,
          primary: PayspinGradientPillButton(label: context.l10n.tryAgain, onPressed: _load),
        ),
      );
    }
    if (filtered.isEmpty && _query.isEmpty) {
      return SliverFillRemaining(hasScrollBody: false, child: _emptyState());
    }
    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(context.l10n.noSearchResults, style: TextStyle(color: context.psColors.textMuted)),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == filtered.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: PayspinGroepiesPromoCard(onTap: () => _selectTab(HomeTab.groepies)),
              );
            }
            return PayspinTikkieRow(
              link: filtered[i],
              tintIndex: i,
              onTap: () => context.push('/links/${filtered[i].id}'),
            );
          },
          childCount: filtered.length + 1,
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
