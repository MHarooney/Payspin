import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/state/notifications_refresh_notifier.dart';
import '../../domain/repositories/notification_repository.dart';

/// Glass bell button with an unread badge. Refetches the unread count whenever
/// [NotificationsRefreshNotifier] bumps (push arrived / row marked read).
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key, required this.onTap, this.bordered = true});

  final VoidCallback onTap;

  /// When false, drops the glass fill + border for a flat app-bar look.
  final bool bordered;

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final NotificationsRefreshNotifier _refresh = sl<NotificationsRefreshNotifier>();
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _refresh.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _refresh.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final count = await sl<NotificationRepository>().unreadCount();
      if (mounted) setState(() => _unread = count);
    } catch (_) {/* ignore — badge is best-effort */}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: widget.bordered ? colors.glassFill : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: widget.bordered ? BorderSide(color: colors.glassBorder) : BorderSide.none,
          ),
          child: InkWell(
            onTap: () {
              widget.onTap();
              _load();
            },
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.notifications_outlined, color: colors.textPrimary, size: 20),
            ),
          ),
        ),
        if (_unread > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                gradient: PayspinTokens.gradientPink,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: colors.bg, width: 1.5),
              ),
              child: Center(
                child: Text(
                  _unread > 99 ? '99+' : '$_unread',
                  style: GoogleFonts.inter(
                    color: PayspinTokens.onBrand,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
