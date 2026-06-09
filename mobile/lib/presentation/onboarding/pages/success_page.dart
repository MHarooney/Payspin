import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/design_system/theme/payspin_motion.dart';
import '../../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../../core/design_system/tokens/payspin_tokens.dart';
import '../../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../../core/design_system/widgets/payspin_emblem_assemble.dart';
import '../../../core/design_system/widgets/payspin_finance_particles.dart';
import '../../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../../core/design_system/widgets/payspin_gradient_text.dart';
import '../../../core/design_system/widgets/payspin_radial_glow.dart';
import '../onboarding_cubit.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> with SingleTickerProviderStateMixin {
  static const _timelineDuration = Duration(milliseconds: 2200);

  late final AnimationController _timeline = AnimationController(
    vsync: this,
    duration: _timelineDuration,
  );

  late final List<_ConfettiParticle> _confetti = List.generate(36, (i) {
    final rnd = math.Random(i * 11 + 5);
    return _ConfettiParticle(
      angle: rnd.nextDouble() * 2 * math.pi,
      speed: 0.55 + rnd.nextDouble() * 0.85,
      size: 4 + rnd.nextDouble() * 6,
      color: [PayspinTokens.mint, PayspinTokens.pink, PayspinTokens.mustard, PayspinTokens.blue][i % 4],
      isCircle: i % 3 == 0,
      spin: rnd.nextDouble() * math.pi,
    );
  });

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (PayspinMotion.reduced(context)) {
        _timeline.value = 1.0;
      } else {
        _timeline.forward();
      }
    });
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  Animation<double> _interval(double start, double end, {Curve curve = PayspinMotion.easeEnter}) {
    return CurvedAnimation(
      parent: _timeline,
      curve: Interval(start, end, curve: curve),
    );
  }

  Widget _reveal(double start, Widget child, {Offset slide = const Offset(0, 0.08)}) {
    if (PayspinMotion.reduced(context)) return child;
    final anim = _interval(start, (start + 0.22).clamp(0.0, 1.0));
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: slide, end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  String _welcomeMessage(String name) {
    if (name.isEmpty) {
      return 'Welcome aboard. Send and request payments in seconds.';
    }
    return 'Welcome aboard, $name. Send and request payments in seconds.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final colors = context.psColors;
    final reduced = PayspinMotion.reduced(context);
    final name = context.watch<OnboardingCubit>().state.displayName.trim();
    final burstOrigin = Offset(size.width * 0.5, size.height * 0.36);

    return Scaffold(
      backgroundColor: colors.bg,
      body: PayspinAmbientBackground(
        child: Stack(
          children: [
            if (!reduced)
              const PayspinFinanceParticles(intensity: 0.35),
            if (!reduced)
              AnimatedBuilder(
                animation: _timeline,
                builder: (context, _) {
                  return CustomPaint(
                    size: size,
                    painter: _ConfettiBurstPainter(
                      particles: _confetti,
                      progress: _timeline.value,
                      origin: burstOrigin,
                    ),
                  );
                },
              ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    SizedBox(height: math.max(16, size.height * 0.05)),
                    _SuccessHero(
                        timeline: _timeline,
                        reduced: reduced,
                        emblemStyle: colors.emblemStyle == PayspinEmblemStyle.auto
                            ? PayspinEmblemStyle.gradient
                            : colors.emblemStyle,
                      ),
                      const SizedBox(height: 20),
                  _reveal(
                    0.55,
                    Text(
                      'Nice!',
                      style: GoogleFonts.raleway(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                        letterSpacing: -1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _reveal(
                    0.62,
                    Text(
                      'You can now use',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.raleway(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colors.textBody,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _reveal(
                    0.69,
                    const PayspinGradientText('Payspin', wordmark: true, style: TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(height: 18),
                  _reveal(
                    0.76,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        _welcomeMessage(name),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.55,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: math.max(24, size.height * 0.04)),
                  _reveal(
                    0.84,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                      child: Text(
                        'One last step — lock your app',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: colors.textMuted),
                      ),
                    ),
                  ),
                  _reveal(
                    0.88,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: PayspinGradientPillButton(
                        label: 'Secure your account',
                        shimmer: true,
                        icon: const Icon(Icons.lock_outline, color: PayspinTokens.onBrand, size: 20),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final setupName = context.read<OnboardingCubit>().state.displayName;
                          context.go('/security/setup', extra: setupName);
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: _reveal(
                      0.92,
                      Text(
                        'Takes less than a minute',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: colors.textHint),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessHero extends StatelessWidget {
  const _SuccessHero({
    required this.timeline,
    required this.reduced,
    required this.emblemStyle,
  });

  final Animation<double> timeline;
  final bool reduced;
  final PayspinEmblemStyle emblemStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: timeline,
        builder: (context, _) {
          final t = timeline.value;
          final emblemDraw = ((t - 0.15) / 0.6).clamp(0.0, 1.0);
          final emblemScale = reduced
              ? 1.0
              : 0.82 + 0.3 * Curves.elasticOut.transform(emblemDraw);
          final checkT = ((t - 0.65) / 0.22).clamp(0.0, 1.0);
          final checkScale = reduced ? 1.0 : Curves.easeOutBack.transform(checkT);

          return Stack(
            alignment: Alignment.center,
            children: [
              if (!reduced) ...[
                _SuccessRippleRing(
                  progress: ((t - 0.08) / 0.35).clamp(0.0, 1.0),
                  color: PayspinTokens.pink,
                  maxSize: 280,
                ),
                _SuccessRippleRing(
                  progress: ((t - 0.14) / 0.35).clamp(0.0, 1.0),
                  color: PayspinTokens.mint,
                  maxSize: 240,
                ),
              ],
              const PayspinRadialGlow(size: 260, centered: true, animate: true),
              Transform.scale(
                scale: emblemScale,
                child: reduced
                    ? PayspinEmblemAssembleStatic(size: 96, style: emblemStyle, glow: true)
                    : PayspinEmblemAssemble(
                        size: 96,
                        progress: emblemDraw,
                        style: emblemStyle,
                        glow: true,
                      ),
              ),
              Positioned(
                right: 78,
                bottom: 78,
                child: Transform.scale(
                  scale: checkScale,
                  child: _SuccessCheckBadge(ringProgress: checkT),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SuccessRippleRing extends StatelessWidget {
  const _SuccessRippleRing({
    required this.progress,
    required this.color,
    required this.maxSize,
  });

  final double progress;
  final Color color;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();
    final size = 80 + (maxSize - 80) * progress;
    final opacity = (1 - progress) * 0.45;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: opacity), width: 2),
      ),
    );
  }
}

class _SuccessCheckBadge extends StatelessWidget {
  const _SuccessCheckBadge({required this.ringProgress});

  final double ringProgress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(44, 44),
            painter: _MintRingPainter(progress: ringProgress),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PayspinTokens.mint.withValues(alpha: 0.18),
              border: Border.all(color: PayspinTokens.mint.withValues(alpha: 0.65)),
            ),
            child: const Icon(Icons.check_rounded, color: PayspinTokens.mint, size: 22),
          ),
        ],
      ),
    );
  }
}

class _MintRingPainter extends CustomPainter {
  const _MintRingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = PayspinTokens.mint.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromLTWH(1, 1, size.width - 2, size.height - 2);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_MintRingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
    required this.isCircle,
    required this.spin,
  });

  final double angle;
  final double speed;
  final double size;
  final Color color;
  final bool isCircle;
  final double spin;
}

class _ConfettiBurstPainter extends CustomPainter {
  const _ConfettiBurstPainter({
    required this.particles,
    required this.progress,
    required this.origin,
  });

  final List<_ConfettiParticle> particles;
  final double progress;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final burstT = ((progress - 0.08) / 0.92).clamp(0.0, 1.0);
    if (burstT <= 0) return;

    for (final p in particles) {
      final t = burstT;
      final dx = math.cos(p.angle) * p.speed * 220 * t;
      final dy = math.sin(p.angle) * p.speed * 180 * t + 320 * t * t;
      final opacity = (1 - t * 1.1).clamp(0.0, 1.0);
      if (opacity <= 0) continue;

      final paint = Paint()..color = p.color.withValues(alpha: opacity * 0.9);
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin + t * 8);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.origin != origin;
}
