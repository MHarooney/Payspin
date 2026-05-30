import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_gradient_pill_button.dart';
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
      return const Center(child: CircularProgressIndicator(color: PayspinTokens.pink));
    }
    if (_error != null) {
      return Center(child: Text(_error!, textAlign: TextAlign.center));
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Track Group Expenses?',
            textAlign: TextAlign.center,
            style: GoogleFonts.raleway(fontSize: 26, fontWeight: FontWeight.w800, color: PayspinTokens.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            'Create a Groepie and invite friends to save together in rotation.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: PayspinTokens.textMuted, height: 1.6),
          ),
          const SizedBox(height: 28),
          PayspinGradientPillButton(
            label: 'Create Groepie',
            icon: const Icon(Icons.add, color: Colors.white, size: 20),
            onPressed: () => context.push('/circles/create'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.push('/circles/join'),
            child: Text('Join with invite code', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: PayspinTokens.mint)),
          ),
        ],
      ),
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
