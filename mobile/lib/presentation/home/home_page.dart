import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_deals_placeholder.dart';
import '../../core/design_system/widgets/payspin_empty_state.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_groepies_promo_card.dart';
import '../../core/design_system/widgets/payspin_logo.dart';
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
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          children: [
            Row(
              children: [
                _glassIcon(Icons.qr_code_2, () => context.push('/scan')),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const PayspinLogo(size: 22),
                      const SizedBox(width: 8),
                      PayspinGradientText('Payspin', style: GoogleFonts.raleway(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                _glassIcon(Icons.search, () => setState(() => _searchOpen = !_searchOpen)),
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
                      child: TextField(
                        autofocus: true,
                        onChanged: (v) => setState(() => _query = v),
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: const InputDecoration(hintText: 'Search Tikkies…'),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: PayspinTokens.glass,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: PayspinTokens.border)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 40, height: 40, child: Icon(icon, color: Colors.white, size: 20)),
      ),
    );
  }

  Widget _tabs() {
    const tabs = [HomeTab.tikkies, HomeTab.deals, HomeTab.groepies];
    return PayspinTabStrip(
      labels: const ['Tikkies', 'Deals', 'Groepies'],
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
          title: 'Something went wrong',
          subtitle: _error!,
          primary: PayspinGradientPillButton(label: 'Try again', onPressed: _load),
        ),
      );
    }
    if (filtered.isEmpty && _query.isEmpty) {
      return SliverFillRemaining(hasScrollBody: false, child: _emptyState());
    }
    if (filtered.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text('No Tikkies match your search.', style: TextStyle(color: PayspinTokens.textMuted)),
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
    return PayspinEmptyState(
      emoji: '💸',
      title: 'Time for your first Tikkie',
      subtitle: 'Request money from friends in seconds — they pay straight from their bank.',
      primary: PayspinGradientPillButton(
        label: 'Create a Tikkie',
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        onPressed: () => context.push('/send/amount'),
      ),
    );
  }
}
