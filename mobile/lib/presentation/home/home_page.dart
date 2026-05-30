import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../core/design_system/widgets/payspin_logo.dart';
import '../../core/design_system/widgets/payspin_tikkie_row.dart';
import '../../core/errors/api_exception.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/payment_link_repository.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTabChanged?.call(_tab);
    });
    _load();
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
          if (_tab == HomeTab.deals)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('Deals — coming soon', style: TextStyle(color: PayspinTokens.textMuted))),
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
              ],
            ),
            if (_searchOpen)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.inter(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Search Tikkies…'),
                ),
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
    Widget tab(String label, HomeTab id) {
      final active = _tab == id;
      return GestureDetector(
        onTap: () => _selectTab(id),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(label, style: GoogleFonts.inter(fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 14, color: active ? PayspinTokens.textPrimary : PayspinTokens.textMuted)),
              const SizedBox(height: 6),
              Container(height: 2, width: 48, color: active ? PayspinTokens.mint : Colors.transparent),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [tab('Tikkies', HomeTab.tikkies), const SizedBox(width: 24), tab('Deals', HomeTab.deals), const SizedBox(width: 24), tab('Groepies', HomeTab.groepies)]),
    );
  }

  Widget _tikkiesContent() {
    final filtered = _filtered;
    if (_loading) {
      return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: PayspinTokens.pink)));
    }
    if (_error != null) {
      return SliverFillRemaining(child: Center(child: Text(_error!)));
    }
    if (filtered.isEmpty && _query.isEmpty) {
      return SliverFillRemaining(child: _emptyState());
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => PayspinTikkieRow(
            link: filtered[i],
            tintIndex: i,
            onTap: () => context.push('/links/${filtered[i].id}'),
          ),
          childCount: filtered.length,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Time for Your First Tikkie!', style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary)),
        const SizedBox(height: 8),
        Text('Cash your money quickly.', style: GoogleFonts.inter(color: PayspinTokens.textMuted)),
      ],
    );
  }
}
