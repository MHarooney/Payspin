import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../domain/entities/payment_link.dart';
import '../../l10n/payspin_localizations.dart';
import '../../utils/payment_visuals.dart';
import '../theme/payspin_motion.dart';
import '../theme/payspin_semantic_colors.dart';
import '../tokens/payspin_tokens.dart';
import 'payspin_glass_surface.dart';
import 'payspin_staggered_entrance.dart';
import 'payspin_status_chip.dart';

/// Payment history timeline with staggered entrance and pending pulse.
class PayspinPaymentTimeline extends StatelessWidget {
  const PayspinPaymentTimeline({super.key, required this.payments});

  final List<PaymentRecord> payments;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (payments.isEmpty) {
      return PayspinStaggeredEntrance(
        index: 0,
        child: _EmptyState(message: l10n.noPaymentsYet),
      );
    }

    return Column(
      children: List.generate(payments.length, (i) {
        return PayspinStaggeredEntrance(
          index: i + 1,
          child: _TimelineTile(
            record: payments[i],
            isLast: i == payments.length - 1,
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return PayspinGlassSurface(
      tier: PayspinGlassTier.flat,
      borderRadius: PayspinTokens.radiusCard,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(Icons.schedule, color: colors.textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: GoogleFonts.inter(color: colors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.record, required this.isLast});

  final PaymentRecord record;
  final bool isLast;

  bool get _isPending =>
      record.status == 'PENDING' ||
      record.status == 'PROCESSING' ||
      record.status == 'AWAITING_AUTHORIZATION';

  @override
  Widget build(BuildContext context) {
    final color = PaymentVisuals.recordStatusColor(record.status);
    final colors = context.psColors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _TimelineNode(color: color, pulse: _isPending),
              if (!isLast) Expanded(child: Container(width: 2, color: colors.border)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PayspinGlassSurface(
                tier: PayspinGlassTier.flat,
                borderRadius: PayspinTokens.radiusCard,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.amountLabel,
                        style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary),
                      ),
                    ),
                    PayspinStatusChip(label: record.statusLabel, color: color),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineNode extends StatefulWidget {
  const _TimelineNode({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_TimelineNode> createState() => _TimelineNodeState();
}

class _TimelineNodeState extends State<_TimelineNode> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_TimelineNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && _pulse == null) {
      _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);
    } else if (!widget.pulse && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = PayspinMotion.reduced(context);
    final pulseOn = widget.pulse && !reduced && _pulse != null;

    Widget dot(double scale, double alpha) {
      return Container(
        width: 16 * scale,
        height: 16 * scale,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: alpha),
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.4 * alpha), blurRadius: 8)],
        ),
      );
    }

    if (!pulseOn) {
      return dot(1, 1);
    }

    return AnimatedBuilder(
      animation: _pulse!,
      builder: (context, _) {
        final t = _pulse!.value;
        return SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            alignment: Alignment.center,
            children: [
              dot(1 + t * 0.35, 0.25),
              dot(1, 1),
            ],
          ),
        );
      },
    );
  }
}
