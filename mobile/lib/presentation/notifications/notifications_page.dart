import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/errors/api_exception.dart';
import '../../core/state/notifications_refresh_notifier.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsRefreshNotifier _refresh = sl<NotificationsRefreshNotifier>();
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh.addListener(_onChanged);
    _load();
  }

  void _onChanged() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    _refresh.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await sl<NotificationRepository>().list(limit: 50);
      _items = page.items;
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(AppNotification n) async {
    if (n.isUnread) {
      try {
        await sl<NotificationRepository>().markRead(n.id);
      } catch (_) {/* best-effort */}
    }
    final linkId = n.linkId;
    if (linkId != null && mounted) {
      context.push('/links/$linkId');
    }
  }

  Future<void> _markAll() async {
    try {
      await sl<NotificationRepository>().markAllRead();
      await _load();
    } catch (_) {/* best-effort */}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PayspinTokens.bg,
      appBar: AppBar(
        backgroundColor: PayspinTokens.bg,
        title: Text('Notifications',
            style: GoogleFonts.raleway(fontWeight: FontWeight.w800, color: Colors.white)),
        actions: [
          if (_items.any((n) => n.isUnread))
            TextButton(
              onPressed: _markAll,
              child: Text('Mark all read',
                  style: GoogleFonts.inter(color: PayspinTokens.mint, fontSize: 13)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: PayspinTokens.pink,
        child: _body(),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: PayspinTokens.pink));
    }
    if (_error != null) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text(_error!, style: const TextStyle(color: PayspinTokens.textMuted))),
      ]);
    }
    if (_items.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 140),
        const Center(child: Text('🔔', style: TextStyle(fontSize: 40))),
        const SizedBox(height: 12),
        Center(
          child: Text('No notifications yet',
              style: GoogleFonts.inter(color: PayspinTokens.textMuted, fontSize: 15)),
        ),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _row(_items[i]),
    );
  }

  Widget _row(AppNotification n) {
    return Material(
      color: n.isUnread ? PayspinTokens.bgElevated : PayspinTokens.glass,
      borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
      child: InkWell(
        onTap: () => _open(n),
        borderRadius: BorderRadius.circular(PayspinTokens.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  gradient: PayspinTokens.gradientPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.title,
                        style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(n.body,
                        style: GoogleFonts.inter(
                            color: PayspinTokens.textBody, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(n.timeLabel,
                        style: GoogleFonts.inter(
                            color: PayspinTokens.textHint, fontSize: 11)),
                  ],
                ),
              ),
              if (n.isUnread)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  decoration: const BoxDecoration(
                    color: PayspinTokens.mint,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
