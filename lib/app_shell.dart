import 'package:flutter/material.dart';

import 'player/player_controller.dart';
import 'screens/home_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/player_screen.dart';
import 'theme/tokens.dart';
import 'widgets/glass.dart';

/// Page background, bottom glow, the four tabs and the floating glass nav.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.player});

  final PlayerController player;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  HTab _tab = HTab.home;

  static const _navHeight = 68.0;
  static const _bottom = 28.0;

  @override
  Widget build(BuildContext context) {
    // Home and the placeholders scroll under the nav with an 18 px gap; Player sits 12 px above it.
    const contentInset = _bottom + _navHeight;
    final side = _tab == HTab.player ? 16.0 : 20.0;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HColors.bgTop, HColors.bgBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _tab.index,
                children: [
                  const HomeScreen(bottomInset: contentInset + 18),
                  PlayerScreen(controller: widget.player, bottomInset: contentInset + 12),
                  const PlaceholderScreen(title: 'My Method', bottomInset: contentInset),
                  const PlaceholderScreen(title: 'Settings', bottomInset: contentInset),
                ],
              ),
            ),
            const Positioned(left: 0, right: 0, bottom: 0, child: BottomGlow()),
            Positioned(
              left: side,
              right: side,
              bottom: _bottom,
              child: LiquidGlassNav(current: _tab, onSelect: (t) => setState(() => _tab = t)),
            ),
          ],
        ),
      ),
    );
  }
}
