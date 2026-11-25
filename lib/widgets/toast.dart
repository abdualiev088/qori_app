import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../l10n/l10n.dart';

/// A dark pill floating above the bottom nav, with an optional Undo button.
/// One at a time: a new toast replaces the one showing.
abstract final class Toast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  /// Space for the floating nav (68 tall, 28 from the bottom) plus a gap.
  static const _aboveNav = 28 + 68 + 12.0;

  static void show(BuildContext context, String message, {VoidCallback? onUndo}) {
    final overlay = Overlay.of(context, rootOverlay: true);
    hide();
    final words = message.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final ms = math.max(4000, words * 240 + 2000);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastView(
        message: message,
        onUndo: onUndo == null
            ? null
            : () {
                hide();
                onUndo();
              },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(Duration(milliseconds: ms), () {
      if (identical(_entry, entry)) hide();
    });
  }

  static void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastView extends StatelessWidget {
  const _ToastView({required this.message, this.onUndo});

  final String message;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + Toast._aboveNav;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: reduce ? 1 : 0, end: 1),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
          ),
          child: Semantics(
            liveRegion: true,
            container: true,
            child: Material(
              color: HColors.ink,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, onUndo == null ? 16 : 8, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(message, style: HText.inter(size: 14, color: Colors.white)),
                      ),
                    ),
                    if (onUndo != null) ...[
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: onUndo,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          textStyle: HText.inter(size: 14, weight: FontWeight.w600, color: Colors.white),
                        ),
                        child: Text(context.l10n.undo),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
