import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_empty_state.dart';
import '../../core/design_system/widgets/payspin_explainer_sheet.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
import '../../core/design_system/widgets/payspin_skeleton.dart';
import '../../core/errors/api_exception.dart';
import '../../core/state/circles_refresh_notifier.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';
import '../circles/circle_row.dart';

/// Groepies tab body — keep inside [HomePage] scroll so header + tabs stay visible.
class GroepiesTabContent extends StatefulWidget {
  const GroepiesTabContent({super.key});

  @override
  State<GroepiesTabContent> createState() => _GroepiesTabContentState();
}

class _GroepiesTabContentState extends State<GroepiesTabContent> {
  List<Circle> _circles = [];
  bool _loading = true;
  String? _error;
  final CirclesRefreshNotifier _refresh = sl<CirclesRefreshNotifier>();

  @override
  void initState() {
    super.initState();
    _refresh.addListener(_onRefresh);
    _load();
  }

  void _onRefresh() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    _refresh.removeListener(_onRefresh);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _circles = await sl<CircleRepository>().listCircles();
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 120),
        child: Column(
          children: [
            PayspinSkeletonRow(),
            PayspinSkeletonRow(),
            PayspinSkeletonRow(),
          ],
        ),
      );
    }
    if (_error != null) {
      return PayspinEmptyState(
        emoji: '😕',
        title: 'Could not load Groepies',
        subtitle: _error!,
        primary: PayspinGradientPillButton(label: 'Try again', onPressed: _load),
      );
    }
    if (_circles.isEmpty) {
      return _emptyState(context);
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: PayspinTokens.pink,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        itemCount: _circles.length,
        itemBuilder: (_, i) => CircleRow(
          circle: _circles[i],
          onTap: () => context.push('/circles/${_circles[i].id}'),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return PayspinEmptyState(
      emoji: '👥',
      title: 'Track group expenses?',
      subtitle: 'Create a Groepie and invite friends to save together in rotation.',
      primary: PayspinGradientPillButton(
        label: 'Create Groepie',
        icon: const Icon(Icons.add, color: Colors.white, size: 20),
        onPressed: () => context.push('/circles/create'),
      ),
      secondary: TextButton(
        onPressed: () => _showExplainer(context),
        child: Text('How does it work?', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: PayspinTokens.mint)),
      ),
      tertiary: TextButton(
        onPressed: () => context.push('/circles/join'),
        child: Text('Join with invite code', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: PayspinTokens.textMuted)),
      ),
    );
  }

  void _showExplainer(BuildContext context) {
    PayspinExplainerSheet.show(
      context,
      title: 'How Groepies work',
      steps: const [
        (emoji: '➕', title: 'Create a Groepie', body: 'Start a shared pot and give it a name.'),
        (emoji: '✉️', title: 'Invite friends', body: 'Share an invite code so others can join.'),
        (emoji: '🔁', title: 'Save in rotation', body: 'Everyone contributes and takes turns receiving.'),
      ],
    );
  }
}

/// Standalone route wrapper (e.g. deep link to /home/groepies).
class GroepiesPage extends StatelessWidget {
  const GroepiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: GroepiesTabContent());
  }
}
