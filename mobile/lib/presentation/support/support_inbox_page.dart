import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_empty_state.dart';
import '../../core/design_system/widgets/payspin_emblem_loader.dart';
import '../../core/design_system/widgets/payspin_glass_surface.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/errors/api_exception.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/state/support_refresh_notifier.dart';
import '../../domain/entities/support_thread.dart';
import '../../domain/repositories/support_repository.dart';

class SupportInboxPage extends StatefulWidget {
  const SupportInboxPage({super.key});

  @override
  State<SupportInboxPage> createState() => _SupportInboxPageState();
}

class _SupportInboxPageState extends State<SupportInboxPage> {
  static const _pollInterval = Duration(seconds: 5);

  final SupportRefreshNotifier _refresh = sl<SupportRefreshNotifier>();
  List<SupportThread> _items = [];
  bool _loading = true;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh.addListener(_onChanged);
    _load();
    _poll = Timer.periodic(_pollInterval, (_) => _refreshQuietly());
  }

  void _onChanged() {
    if (mounted) _refreshQuietly();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _refresh.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _items = await sl<SupportRepository>().listThreads();
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshQuietly() async {
    try {
      final items = await sl<SupportRepository>().listThreads();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // Keep last good state; try again next tick.
    }
  }

  Future<void> _openNew() async {
    await context.push('/support/new');
    if (mounted) _refreshQuietly();
  }

  Future<void> _open(SupportThread t) async {
    await context.push('/support/${t.id}');
    if (mounted) _refreshQuietly();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        title: Text(context.l10n.supportTitle,
            style: GoogleFonts.raleway(fontWeight: FontWeight.w800, color: colors.textPrimary)),
      ),
      floatingActionButton: _items.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _openNew,
              backgroundColor: PayspinTokens.pink,
              icon: const Icon(Icons.add_comment_outlined, color: PayspinTokens.onBrand),
              label: Text(context.l10n.supportNewRequest,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: PayspinTokens.onBrand)),
            ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: PayspinTokens.pink,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const PayspinPageLoader();
    final colors = context.psColors;
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: colors.textMuted))),
        const SizedBox(height: 20),
        Center(
          child: SizedBox(
            width: 180,
            child: PayspinGradientPillButton(label: context.l10n.tryAgain, onPressed: _load),
          ),
        ),
      ]);
    }
    if (_items.isEmpty) {
      return PayspinEmptyState(
        emoji: '💬',
        title: context.l10n.supportEmptyTitle,
        subtitle: '${context.l10n.supportEmptySubtitle}\n${context.l10n.supportSlaHint}',
        primary: SizedBox(
          width: 220,
          child: PayspinGradientPillButton(
            label: context.l10n.supportContactSupport,
            onPressed: _openNew,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _row(_items[i]),
    );
  }

  Widget _row(SupportThread t) {
    final colors = context.psColors;
    final category = t.category;
    return Semantics(
      button: true,
      label: '${t.userUnread ? "Unread. " : ""}${t.subject}. ${t.preview}',
      child: PayspinGlassSurface(
        tier: PayspinGlassTier.flat,
        borderRadius: PayspinTokens.radiusCard,
        onTap: () => _open(t),
        border: t.userUnread
            ? Border.all(color: PayspinTokens.pink.withValues(alpha: 0.35), width: 1)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: t.isResolved ? null : PayspinTokens.gradientPink,
                  color: t.isResolved ? colors.glassFill : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  t.isResolved ? Icons.check_circle_outline : Icons.support_agent,
                  color: t.isResolved ? colors.textMuted : PayspinTokens.onBrand,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(t.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  color: colors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                        if (category != null) ...[
                          const SizedBox(width: 8),
                          _chip(context.l10n.supportCategory(category.wire)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(t.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: colors.textBody, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(t.timeLabel, style: GoogleFonts.inter(color: colors.textHint, fontSize: 11)),
                  ],
                ),
              ),
              if (t.userUnread)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  decoration: const BoxDecoration(color: PayspinTokens.mint, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    final colors = context.psColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: GoogleFonts.inter(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}
