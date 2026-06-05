import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/injection.dart';
import '../../core/design_system/theme/payspin_semantic_colors.dart';
import '../../core/design_system/widgets/payspin_ambient_background.dart';
import '../../core/design_system/widgets/payspin_bottom_nav.dart';
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
  HomeTab _homeTab = HomeTab.tikkies;
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
    if (i == 1) {
      context.push('/scan');
      return;
    }
    setState(() => _index = i);
    context.go(i == 2 ? '/home/profile' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.contains('/profile')) {
      _index = 2;
    } else if (!location.contains('/scan')) {
      _index = 0;
    }

    Widget body = widget.child;
    if (location == '/home' || location == '/home/') {
      body = HomePage(onTabChanged: (tab) => setState(() => _homeTab = tab));
    } else if (location.contains('groepies')) {
      body = const GroepiesPage();
    } else if (location.contains('profile')) {
      body = ProfilePage(onGoHome: () => context.go('/home'));
    }

    return Scaffold(
      backgroundColor: context.psColors.bg,
      extendBody: true,
      body: PayspinAmbientBackground(child: body),
      floatingActionButton: _index == 0 && _homeTab != HomeTab.groepies && !location.contains('groepies')
          ? Padding(
              padding: const EdgeInsets.only(bottom: 84),
              child: PayspinGradientFab(onPressed: () => context.push('/send/amount')),
            )
          : null,
      bottomNavigationBar: PayspinBottomNav(currentIndex: _index, onTap: _onTap),
    );
  }
}
