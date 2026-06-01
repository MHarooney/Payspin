import 'package:flutter/material.dart';

import '../tokens/payspin_tokens.dart';

/// Shimmering placeholder block used for loading states.
class PayspinSkeleton extends StatefulWidget {
  const PayspinSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<PayspinSkeleton> createState() => _PayspinSkeletonState();
}

class _PayspinSkeletonState extends State<PayspinSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t) + 1, 0),
              colors: [
                PayspinTokens.surfaceRaised,
                PayspinTokens.border,
                PayspinTokens.surfaceRaised,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A skeleton shaped like a [PayspinTikkieRow] for list loading states.
class PayspinSkeletonRow extends StatelessWidget {
  const PayspinSkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PayspinTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PayspinTokens.border),
      ),
      child: const Row(
        children: [
          PayspinSkeleton(width: 44, height: 44, radius: 14),
          SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PayspinSkeleton(width: 140, height: 14),
              SizedBox(height: 8),
              PayspinSkeleton(width: 70, height: 12),
            ],
          ),
          Spacer(),
          PayspinSkeleton(width: 54, height: 16),
        ],
      ),
    );
  }
}
