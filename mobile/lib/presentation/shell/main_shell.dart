import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_bottom_nav.dart';
import '../../core/design_system/widgets/payspin_draggable_fab.dart';
import '../../core/notifications/push_service.dart';
import '../home/groepies_page.dart';
import '../home/home_page.dart';
import '../profile/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final PushService _push = sl<PushService>();

  @override
  void initState() {
    super.initState();
    // A tapped push (background/killed) asks the shell to open a link detail.
    _push.openLinkRequests.addListener(_onOpenLinkRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onOpenLinkRequested());
  }

  @override
  void dispose() {
    _push.openLinkRequests.removeListener(_onOpenLinkRequested);
    super.dispose();
  }

  void _onOpenLinkRequested() {
    final linkId = _push.openLinkRequests.value;
    if (linkId != null && mounted) {
      _push.openLinkRequests.value = null;
      context.push('/links/$linkId');
    }
  }

  void _onTap(int i) {
    setState(() => _index = i);
    // 0 = Home, 1 = Payspin (Groepies / community — "coming soon").
    context.go(i == 1 ? '/home/groepies' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isGroepies = location.contains('groepies');
    final isProfile = location.contains('profile');
    _index = isGroepies ? 1 : 0;

    Widget body = widget.child;
    if (location == '/home' || location == '/home/') {
      body = const HomePage();
    } else if (isGroepies) {
      body = const GroepiesPage();
    } else if (isProfile) {
      body = ProfilePage(onGoHome: () => context.go('/home'));
    }

    // The create-link FAB only belongs on the Home (tikkies) screen.
    final showFab = location == '/home' || location == '/home/';

    return Scaffold(
      backgroundColor: context.psColors.bg,
      extendBody: true,
      body: Stack(
        children: [
          PayspinAmbientBackground(child: body),
          if (showFab)
            Positioned.fill(
              child: PayspinDraggableFab(
                child: PayspinGradientFab(onPressed: () => context.push('/send/amount')),
              ),
            ),
        ],
      ),
      bottomNavigationBar: PayspinBottomNav(currentIndex: _index, onTap: _onTap),
    );
  }
}
