import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_finance_particles.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_radial_glow.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/onboarding/intro_store.dart';
import 'scenes/intro_scene_1_bill_to_links.dart';
import 'scenes/intro_scene_2_europe_map.dart';
import 'scenes/intro_scene_3_one_tap_pay.dart';
import 'scenes/intro_scene_4_value_loop.dart';
import 'scenes/intro_scene_5_use_cases.dart';

/// Wise-style 5-scene pre-onboarding storyboard. Skippable, localized, and
/// shown once (first launch) before [WelcomePage]. Each scene has a short
/// looping motion illustration plus a localized headline + body.
class PayspinIntroFlow extends StatefulWidget {
  const PayspinIntroFlow({super.key});

  static const sceneCount = 5;

  @override
  State<PayspinIntroFlow> createState() => _PayspinIntroFlowState();
}

class _PayspinIntroFlowState extends State<PayspinIntroFlow> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await IntroStore.markSeen();
    if (mounted) context.go('/welcome');
  }

  void _next() {
    if (_page >= PayspinIntroFlow.sceneCount - 1) {
      _finish();
      return;
    }
    HapticFeedback.selectionClick();
    _controller.nextPage(
      duration: PayspinMotion.medium,
      curve: PayspinMotion.easeEnter,
    );
  }

  Widget _sceneFor(int i) => switch (i) {
        0 => const IntroScene1(),
        1 => const IntroScene2(),
        2 => const IntroScene3(),
        3 => const IntroScene4(),
        _ => const IntroScene5(),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final l10n = context.l10n;
    final isLast = _page == PayspinIntroFlow.sceneCount - 1;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: PayspinRadialGlow(size: 420, animate: false)),
          Positioned.fill(child: PayspinFinanceParticles(intensity: isLight ? 0.75 : 0.5)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          l10n.introSkip,
                          style: GoogleFonts.inter(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: PayspinIntroFlow.sceneCount,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => _IntroPage(
                      scene: _sceneFor(i),
                      title: l10n.introSceneTitle(i + 1),
                      body: l10n.introSceneBody(i + 1),
                    ),
                  ),
                ),
                _Dots(count: PayspinIntroFlow.sceneCount, active: _page),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: PayspinGradientPillButton(
                    label: isLast ? l10n.introGetStarted : l10n.introNext,
                    shimmer: isLast,
                    onPressed: _next,
                    icon: Icon(
                      isLast ? Icons.arrow_forward_rounded : Icons.chevron_right_rounded,
                      color: PayspinTokens.onBrand,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.scene, required this.title, required this.body});

  final Widget scene;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(flex: 5, child: scene),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.raleway(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.55,
                    color: colors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: PayspinMotion.fast,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              gradient: i == active ? PayspinTokens.gradientPink : null,
              color: i == active ? null : colors.glassBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
