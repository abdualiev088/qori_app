import 'package:flutter/material.dart';

import 'data/auth_api.dart';
import 'data/learned_store.dart';
import 'player/player_controller.dart';
import 'screens/home_screen.dart';
import 'screens/placeholder_screen.dart';
import 'screens/player_tab.dart';
import 'theme/tokens.dart';
import 'widgets/glass.dart';
import 'widgets/mini_player.dart';

/// Page background, bottom glow, the four tabs and the floating glass nav.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.player, required this.learned, required this.auth});

  final PlayerController player;
  final LearnedStore learned;
  final AuthApi auth;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  HTab _tab = HTab.home;

  final _playerNav = GlobalKey<NavigatorState>();
  final _playerObserver = PlayerOpenObserver();
  final _surahsTitle = FocusNode();

  /// The surah list's bottom padding: the nav, plus the mini-player while it shows.
  final _listInset = ValueNotifier<double>(_listBase);

  static const _listBase = _bottom + _navHeight + 18;
  static const _miniGap = 8.0;

  @override
  void dispose() {
    _surahsTitle.dispose();
    _listInset.dispose();
    super.dispose();
  }

  void _select(HTab t) {
    // Tapping the Player tab again goes back to the list.
    if (t == HTab.player && _tab == HTab.player) _playerNav.currentState?.popUntil((r) => r.isFirst);
    setState(() => _tab = t);
  }

  void _reopenPlayer() {
    final s = widget.player.surah;
    final nav = _playerNav.currentState;
    if (s == null || nav == null) return;
    openPlayer(nav, controller: widget.player, surah: s, bottomInset: _bottom + _navHeight, observer: _playerObserver);
  }

  void _closePlayer() {
    widget.player.close();
    _surahsTitle.requestFocus();
  }

  static const _navHeight = 68.0;
  static const _bottom = 28.0;
  static const _side = 16.0;

  @override
  Widget build(BuildContext context) {
    // Home and the placeholders scroll under the nav with an 18 px gap; Player sits 12 px above it.
    const contentInset = _bottom + _navHeight;

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
                  HomeScreen(bottomInset: contentInset + 18, learned: widget.learned, auth: widget.auth),
                  PlayerTab(
                    navigatorKey: _playerNav,
                    observer: _playerObserver,
                    controller: widget.player,
                    learned: widget.learned,
                    listBottomInset: _listInset,
                    playerBottomInset: contentInset,
                    titleFocus: _surahsTitle,
                  ),
                  const PlaceholderScreen(title: 'My Method', bottomInset: contentInset),
                  const PlaceholderScreen(title: 'Settings', bottomInset: contentInset),
                ],
              ),
            ),
            const Positioned(left: 0, right: 0, bottom: 0, child: BottomGlow()),
            // The mini-player: on the surah list while a surah is active, never over the player.
            Positioned(
              left: _side,
              right: _side,
              bottom: _bottom + _navHeight + _miniGap,
              child: ListenableBuilder(
                listenable: Listenable.merge([widget.player, _playerObserver.open]),
                builder: (context, _) {
                  final visible = _tab == HTab.player && widget.player.surah != null && !_playerObserver.open.value;
                  final inset = _listBase + (visible ? MiniPlayer.height + _miniGap : 0);
                  if (_listInset.value != inset) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _listInset.value = inset);
                  }
                  return MiniPlayer(
                    controller: widget.player,
                    visible: visible,
                    onOpen: _reopenPlayer,
                    onClose: _closePlayer,
                  );
                },
              ),
            ),
            Positioned(
              left: _side,
              right: _side,
              bottom: _bottom,
              child: LiquidGlassNav(current: _tab, onSelect: _select),
            ),
          ],
        ),
      ),
    );
  }
}
