import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/tokens/payspin_tokens.dart';
import '../../core/design_system/widgets/payspin_bottom_nav.dart';
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
      backgroundColor: PayspinTokens.bg,
      body: body,
      floatingActionButton: _index == 0 && _homeTab != HomeTab.groepies && !location.contains('groepies')
          ? Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: PayspinGradientFab(onPressed: () => context.push('/send/amount')),
            )
          : null,
      bottomNavigationBar: PayspinBottomNav(currentIndex: _index, onTap: _onTap),
    );
  }
}
