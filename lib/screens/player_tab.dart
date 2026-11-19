import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../data/learned_store.dart';
import '../player/player_controller.dart';
import 'player_screen.dart';
import 'surah_list_screen.dart';

/// The Player tab: the surah list, with the player pushed on top of it.
/// Its own navigator, so the bottom nav stays put while the player slides in.
class PlayerTab extends StatelessWidget {
  const PlayerTab({
    super.key,
    required this.navigatorKey,
    required this.observer,
    required this.controller,
    required this.learned,
    required this.listBottomInset,
    required this.playerBottomInset,
    this.titleFocus,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final PlayerOpenObserver observer;
  final PlayerController controller;
  final LearnedStore learned;

  /// Grows while the mini-player shows.
  final ValueListenable<double> listBottomInset;
  final double playerBottomInset;
  final FocusNode? titleFocus;

  @override
  Widget build(BuildContext context) => NavigatorPopHandler(
        // The system back button closes the player before leaving the app.
        onPopWithResult: (_) => navigatorKey.currentState?.maybePop(),
        child: Navigator(
          key: navigatorKey,
          observers: [observer],
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondary) => SurahListScreen(
              learned: learned,
              bottomInset: listBottomInset,
              titleFocus: titleFocus,
              onOpen: (surah, ayah) => openPlayer(
                navigatorKey.currentState!,
                controller: controller,
                surah: surah,
                ayah: ayah,
                bottomInset: playerBottomInset,
                observer: observer,
              ),
            ),
          ),
        ),
      );
}

/// Opens [surah] in the player, at [ayah] if given (otherwise where it was
/// left), and pushes the player screen unless it's already showing.
void openPlayer(
  NavigatorState navigator, {
  required PlayerController controller,
  required int surah,
  int? ayah,
  required double bottomInset,
  required PlayerOpenObserver observer,
}) {
  controller.openSurah(surah, ayah: ayah);
  if (observer.open.value) return;
  final reduce = MediaQuery.disableAnimationsOf(navigator.context);
  Widget page(BuildContext context) => PlayerScreen(
        controller: controller,
        bottomInset: bottomInset,
        onBack: () => Navigator.of(context).maybePop(),
      );
  navigator.push(reduce ? _InstantPlayerRoute(builder: page) : _PlayerRoute(builder: page));
}

/// Marks the routes that show the player, so the shell knows when it's open.
mixin PlayerRouteMarker on PageRoute<void> {}

/// The native iOS push (with swipe back), timed like the prototype: 360 ms in, 260 ms back.
class _PlayerRoute extends CupertinoPageRoute<void> with PlayerRouteMarker {
  _PlayerRoute({required super.builder});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 360);
  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);
}

/// No motion under Reduce Motion.
class _InstantPlayerRoute extends PageRouteBuilder<void> with PlayerRouteMarker {
  _InstantPlayerRoute({required WidgetBuilder builder})
      : super(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondary) => builder(context),
        );
}

/// Tracks whether the player screen is showing in the Player tab.
class PlayerOpenObserver extends NavigatorObserver {
  final open = ValueNotifier(false);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PlayerRouteMarker) open.value = true;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PlayerRouteMarker) open.value = false;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PlayerRouteMarker) open.value = false;
  }
}
