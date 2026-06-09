import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/design_system/theme/payspin_motion.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_emblem_assemble.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_quick_settings.dart';
import '../../core/l10n/payspin_localizations.dart';
import '../../core/onboarding/intro_store.dart';
import 'intro_page_transformer.dart';
import 'intro_scene_choreography.dart';
import 'intro_scene_scope.dart';
import 'payspin_intro_progress_rail.dart';
import 'payspin_intro_shell.dart';
import 'scenes/intro_scene_1_bill_to_links.dart';
import 'scenes/intro_scene_2_europe_map.dart';
import 'scenes/intro_scene_3_one_tap_pay.dart';
import 'scenes/intro_scene_4_value_loop.dart';
import 'scenes/intro_scene_5_use_cases.dart';

/// Aurora Prelude — 5-scene cinematic intro before [WelcomePage].
class PayspinIntroFlow extends StatefulWidget {
  const PayspinIntroFlow({super.key});

  static const sceneCount = 5;

  @override
  State<PayspinIntroFlow> createState() => _PayspinIntroFlowState();
}

class _PayspinIntroFlowState extends State<PayspinIntroFlow> {
  final PageController _controller = PageController();
  final ValueNotifier<double> _offsetNotifier = ValueNotifier(0);
  int _page = 0;
  double _pageOffset = 0;
  bool _exitingIllustration = false;
  bool _finaleFlash = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _controller.page ?? _page.toDouble();
    _offsetNotifier.value = offset;
    if ((offset - _pageOffset).abs() > 0.001) {
      setState(() => _pageOffset = offset);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _offsetNotifier.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({bool withFlash = false}) async {
    if (withFlash) {
      setState(() => _finaleFlash = true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    await IntroStore.markSeen();
    if (mounted) context.go('/welcome');
  }

  Future<void> _next() async {
    if (_page >= PayspinIntroFlow.sceneCount - 1) {
      HapticFeedback.mediumImpact();
      await _finish(withFlash: true);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _exitingIllustration = true);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    await _controller.nextPage(
      duration: PayspinMotion.medium,
      curve: PayspinMotion.easeEnter,
    );
    if (mounted) setState(() => _exitingIllustration = false);
  }

  void _onPageChanged(int i) {
    HapticFeedback.selectionClick();
    setState(() => _page = i);
  }

  Widget _sceneFor(int i) => switch (i) {
        0 => const IntroScene1(sceneIndex: 0),
        1 => const IntroScene2(sceneIndex: 1),
        2 => const IntroScene3(sceneIndex: 2),
        3 => const IntroScene4(sceneIndex: 3),
        _ => const IntroScene5(sceneIndex: 4),
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.psColors;
    final l10n = context.l10n;
    final isLast = _page == PayspinIntroFlow.sceneCount - 1;

    return Scaffold(
      backgroundColor: colors.bg,
      body: Stack(
        children: [
          PayspinIntroBackdrop(
            sceneIndex: _page,
            child: IntroSceneScope(
              pageOffset: _pageOffset,
              offsetListenable: _offsetNotifier,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                      child: Row(
                        children: [
                          const PayspinQuickSettings(),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _finish(),
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
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, i) => IntroPageTransformer(
                          pageOffset: _pageOffset,
                          index: i,
                          child: _IntroPage(
                            scene: IntroIllustrationTransition(
                              exiting: _exitingIllustration && i == _page,
                              child: _sceneFor(i),
                            ),
                            title: l10n.introSceneTitle(i + 1),
                            body: l10n.introSceneBody(i + 1),
                            sceneKey: i,
                            colors: colors,
                          ),
                        ),
                      ),
                    ),
                    PayspinIntroProgressRail(
                      count: PayspinIntroFlow.sceneCount,
                      active: _page,
                      pageOffset: _pageOffset,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      child: AnimatedScale(
                        scale: _exitingIllustration ? 0.97 : 1,
                        duration: PayspinMotion.fast,
                        child: PayspinGradientPillButton(
                          key: const Key('intro_next'),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_finaleFlash)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: PayspinTokens.pink.withValues(alpha: 0.12),
                  child: Center(
                    child: PayspinEmblemAssemble(
                      size: 72,
                      progress: 1,
                      style: PayspinEmblemStyle.gradient,
                      glow: true,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({
    required this.scene,
    required this.title,
    required this.body,
    required this.sceneKey,
    required this.colors,
  });

  final Widget scene;
  final String title;
  final String body;
  final int sceneKey;
  final PayspinSemanticColors colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Expanded(flex: 5, child: scene),
          Expanded(
            flex: 3,
            child: IntroSceneCopy(
              title: title,
              body: body,
              sceneKey: sceneKey,
              titleStyle: GoogleFonts.raleway(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: colors.textPrimary,
              ),
              bodyStyle: GoogleFonts.inter(
                fontSize: 15,
                height: 1.55,
                color: colors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
