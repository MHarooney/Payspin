import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_emblem_loader.dart';
import '../../core/design_system/widgets/payspin_snackbar.dart';
import '../../core/errors/api_exception.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/state/support_refresh_notifier.dart';
import '../../domain/entities/support_thread.dart';
import '../../domain/repositories/support_repository.dart';

class SupportThreadPage extends StatefulWidget {
  const SupportThreadPage({super.key, required this.threadId});

  final String threadId;

  @override
  State<SupportThreadPage> createState() => _SupportThreadPageState();
}

class _SupportThreadPageState extends State<SupportThreadPage> {
  static const _pollInterval = Duration(seconds: 5);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final SupportRefreshNotifier _refresh = sl<SupportRefreshNotifier>();

  SupportThreadDetail? _thread;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load(markRead: true);
    _poll = Timer.periodic(_pollInterval, (_) => _refreshQuietly());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool markRead = false}) async {
    try {
      final thread = await sl<SupportRepository>().getThread(widget.threadId);
      if (!mounted) return;
      setState(() {
        _thread = thread;
        _loading = false;
      });
      _scrollToBottom();
      if (markRead && thread.userUnread) {
        await sl<SupportRepository>().markRead(widget.threadId);
        _refresh.bump();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = apiErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshQuietly() async {
    try {
      final thread = await sl<SupportRepository>().getThread(widget.threadId);
      if (!mounted) return;
      final wasAtBottom = _isNearBottom();
      final hadUnread = thread.userUnread;
      setState(() => _thread = thread);
      if (wasAtBottom) _scrollToBottom();
      if (hadUnread) {
        await sl<SupportRepository>().markRead(widget.threadId);
      }
    } catch (_) {
      // Keep last good state; retry next tick.
    }
  }

  bool _isNearBottom() {
    if (!_scroll.hasClients) return true;
    return _scroll.position.pixels >= _scroll.position.maxScrollExtent - 120;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final thread = await sl<SupportRepository>().sendMessage(widget.threadId, body);
      if (!mounted) return;
      setState(() {
        _thread = thread;
        _sending = false;
      });
      _controller.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        // Preserve the composer text so the user can retry after an error.
        setState(() => _sending = false);
        showPayspinSnackBar(context, apiErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final thread = _thread;
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        title: Text(
          thread?.subject ?? context.l10n.supportTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.raleway(fontWeight: FontWeight.w800, color: colors.textPrimary),
        ),
      ),
      body: _loading
          ? const PayspinPageLoader()
          : thread == null
              ? Center(
                  child: Text(_error ?? '', style: TextStyle(color: colors.textMuted)))
              : Column(
                  children: [
                    Expanded(child: _messages(thread)),
                    _composer(thread),
                  ],
                ),
    );
  }

  Widget _messages(SupportThreadDetail thread) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: thread.messages.length + (thread.isResolved ? 1 : 0),
      itemBuilder: (context, i) {
        if (thread.isResolved && i == thread.messages.length) {
          return _resolvedBanner();
        }
        return _bubble(thread.messages[i]);
      },
    );
  }

  Widget _bubble(SupportMessage m) {
    final colors = context.psColors;
    final fromUser = m.isFromUser;
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: fromUser ? PayspinTokens.mint.withValues(alpha: 0.18) : colors.glassFill,
          border: Border.all(
            color: fromUser
                ? PayspinTokens.mint.withValues(alpha: 0.45)
                : colors.border,
            width: 1,
          ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(fromUser ? 16 : 4),
            bottomRight: Radius.circular(fromUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!fromUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(context.l10n.supportTeam,
                    style: GoogleFonts.inter(
                        color: PayspinTokens.pink, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            Text(m.body, style: GoogleFonts.inter(color: colors.textPrimary, fontSize: 14, height: 1.4)),
            const SizedBox(height: 3),
            Text(m.timeLabel, style: GoogleFonts.inter(color: colors.textHint, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _resolvedBanner() {
    final colors = context.psColors;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.glassFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: colors.textMuted),
          const SizedBox(width: 8),
          Flexible(
            child: Text(context.l10n.supportResolvedBanner,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: colors.textMuted, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _composer(SupportThreadDetail thread) {
    final colors = context.psColors;
    final hint = thread.isResolved ? context.l10n.supportSendAnother : context.l10n.supportReplyHint;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: colors.bg,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colors.glassFill,
                  borderRadius: BorderRadius.circular(PayspinTokens.radiusPill),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 4000,
                  style: GoogleFonts.inter(color: colors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.inter(color: colors.textHint),
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: PayspinTokens.gradientPink,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(padding: EdgeInsets.all(13), child: PayspinEmblemLoader(size: 20))
                    : const Icon(Icons.arrow_upward, color: PayspinTokens.onBrand, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
