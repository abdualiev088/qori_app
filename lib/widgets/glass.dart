import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'icons.dart';

/// Blur plus a 180% saturation boost, like `backdrop-filter: blur() saturate(180%)`.
ui.ImageFilter glassFilter(double blur) {
  const s = 1.8;
  const r = 0.2126 * (1 - s), g = 0.7152 * (1 - s), b = 0.0722 * (1 - s);
  return ui.ImageFilter.compose(
    outer: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), // CSS blur() is a standard deviation too
    inner: const ColorFilter.matrix([
      r + s, g, b, 0, 0, //
      r, g + s, b, 0, 0, //
      r, g, b + s, 0, 0, //
      0, 0, 0, 1, 0,
    ]),
  );
}

/// A 1.5 px bright edge along the top inside a rounded shape (the CSS inset highlight).
class _TopHighlight extends StatelessWidget {
  const _TopHighlight({required this.radius, this.opacity = 1});

  final double radius;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(painter: _TopHighlightPainter(radius, opacity), size: Size.infinite),
      );
}

class _TopHighlightPainter extends CustomPainter {
  _TopHighlightPainter(this.radius, this.opacity);

  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    final inner = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 1.5, size.width, size.height - 1.5), Radius.circular(radius));
    canvas.drawDRRect(
      outer,
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [Colors.white.withValues(alpha: opacity), Colors.white.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_TopHighlightPainter old) => old.radius != radius || old.opacity != opacity;
}

/// Frosted glass in a rounded rectangle: outer shadows, blurred backdrop,
/// translucent fill, white hairline and a top highlight.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.radius,
    required this.fill,
    required this.child,
    this.blur = 24,
    this.shadows = const [
      BoxShadow(color: Color(0x2914462D), offset: Offset(0, 14), blurRadius: 34),
      BoxShadow(color: Color(0x1414462D), offset: Offset(0, 2), blurRadius: 6),
    ],
    this.borderColor = const Color(0xCCFFFFFF),
    this.highlight = 1,
  });

  final double radius;
  final Gradient fill;
  final Widget child;
  final double blur;
  final List<BoxShadow> shadows;
  final Color borderColor;
  final double highlight;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: shadows),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: glassFilter(blur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: fill,
              border: Border.all(color: borderColor),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                child,
                Positioned.fill(child: _TopHighlight(radius: radius, opacity: highlight)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 46 px glass profile button on Home.
class GlassProfileButton extends StatelessWidget {
  const GlassProfileButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Profile',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: 46,
          child: LiquidGlass(
            radius: 23,
            blur: 20,
            borderColor: const Color(0xD9FFFFFF),
            shadows: const [
              BoxShadow(color: Color(0x2414462D), offset: Offset(0, 8), blurRadius: 20),
              BoxShadow(color: Color(0x1A14462D), offset: Offset(0, 1), blurRadius: 3),
            ],
            fill: const RadialGradient(
              center: Alignment(-0.4, -0.6),
              radius: 1.1,
              colors: [Color(0xF2FFFFFF), Color(0x59FFFFFF), Color(0x73D6F0E2)],
              stops: [0, .45, 1],
            ),
            child: Center(child: HIcon.profile(HColors.ink)),
          ),
        ),
      ),
    );
  }
}

/// The mint/lilac glow at the bottom of the screen that gives the nav glass color to blur.
class BottomGlow extends StatelessWidget {
  const BottomGlow({super.key});

  @override
  Widget build(BuildContext context) => const IgnorePointer(
        child: SizedBox(
          height: 170,
          width: double.infinity,
          child: CustomPaint(painter: _BottomGlowPainter()),
        ),
      );
}

class _BottomGlowPainter extends CustomPainter {
  const _BottomGlowPainter();

  void _ellipse(Canvas c, Size s, double cx, double cy, double rx, double ry, Color color) {
    final center = Offset(s.width * cx, s.height * cy);
    final w = s.width * rx, h = s.height * ry;
    c
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(1, h / w);
    c.drawCircle(
      Offset.zero,
      w,
      Paint()
        ..shader = ui.Gradient.radial(Offset.zero, w, [color, color.withValues(alpha: 0)], const [0, .7]),
    );
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    _ellipse(canvas, size, .85, .95, .45, .60, const Color(0x73C9C2EE));
    _ellipse(canvas, size, .30, 1, .55, .70, const Color(0x8C8FDDB4));
  }

  @override
  bool shouldRepaint(_BottomGlowPainter old) => false;
}

enum HTab { home, player, method, settings }

/// The liquid-glass bottom nav: 68 tall, radius 34, four equal columns.
///
/// Tap a tab to switch, or hold or swipe along the bar: the highlight follows
/// the finger and the tab under it is selected on release.
class LiquidGlassNav extends StatefulWidget {
  const LiquidGlassNav({super.key, required this.current, required this.onSelect});

  final HTab current;
  final ValueChanged<HTab> onSelect;

  @override
  State<LiquidGlassNav> createState() => _LiquidGlassNavState();
}

class _LiquidGlassNavState extends State<LiquidGlassNav> {
  static const _gap = 4.0;

  /// Finger position along the bar while dragging; null otherwise.
  double? _dragX;

  /// The tab under the finger while dragging.
  HTab? _hover;

  double _itemWidth(double width) => (width - _gap * (HTab.values.length - 1)) / HTab.values.length;

  HTab _tabAt(double x, double width) {
    final i = (x / (_itemWidth(width) + _gap)).floor().clamp(0, HTab.values.length - 1);
    return HTab.values[i];
  }

  void _start(double x, double width) => setState(() {
        _dragX = x;
        _hover = _tabAt(x, width);
      });

  void _move(double x, double width) {
    final tab = _tabAt(x, width);
    if (tab != _hover) HapticFeedback.selectionClick();
    setState(() {
      _dragX = x;
      _hover = tab;
    });
  }

  void _end() {
    final tab = _hover;
    setState(() {
      _dragX = null;
      _hover = null;
    });
    if (tab != null && tab != widget.current) widget.onSelect(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Main',
      child: SizedBox(
        height: 68,
        child: LiquidGlass(
          radius: HRadii.nav,
          fill: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xB8FFFFFF), Color(0x52FFFFFF), Color(0x8CFFFFFF)],
            stops: [0, .5, 1],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5), // 6 px minus the 1 px border
            child: LayoutBuilder(builder: (context, box) {
              final width = box.maxWidth;
              final itemWidth = _itemWidth(width);
              final dragX = _dragX;
              final dragging = dragX != null;
              final shown = _hover ?? widget.current;
              final left = dragging
                  ? (dragX - itemWidth / 2).clamp(0.0, width - itemWidth)
                  : widget.current.index * (itemWidth + _gap);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (d) => _start(d.localPosition.dx, width),
                onHorizontalDragUpdate: (d) => _move(d.localPosition.dx, width),
                onHorizontalDragEnd: (_) => _end(),
                onLongPressStart: (d) {
                  HapticFeedback.mediumImpact();
                  _start(d.localPosition.dx, width);
                },
                onLongPressMoveUpdate: (d) => _move(d.localPosition.dx, width),
                onLongPressEnd: (_) => _end(),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: Duration(milliseconds: dragging ? 90 : 320),
                      curve: dragging ? Curves.easeOut : Curves.easeOutCubic,
                      left: left,
                      top: 0,
                      bottom: 0,
                      width: itemWidth,
                      child: AnimatedScale(
                        scale: dragging ? 1.08 : 1,
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        child: const _ActivePill(),
                      ),
                    ),
                    Row(
                      children: [
                        for (final (i, tab) in HTab.values.indexed) ...[
                          if (i > 0) const SizedBox(width: _gap),
                          Expanded(
                            child: _NavItem(tab: tab, active: tab == shown, onTap: () => widget.onSelect(tab)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// The bright glass highlight behind the active tab.
class _ActivePill extends StatelessWidget {
  const _ActivePill();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.6,
            colors: [Color(0xFAFFFFFF), Color(0xD9E8F8EF), Color(0xCCD0F0DE)],
            stops: [0, .6, 1],
          ),
          boxShadow: [BoxShadow(color: Color(0x1F145A37), offset: Offset(0, 4), blurRadius: 10)],
        ),
      );
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.tab, required this.active, required this.onTap});

  final HTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? HColors.accentDeep : HColors.navInk;
    final (icon, label) = switch (tab) {
      HTab.home => (HIcon.home(color, active: active), 'Home'),
      HTab.player => (HIcon.player(color, active: active), 'Player'),
      HTab.method => (HIcon.method(color, active: active), 'My Method'),
      HTab.settings => (HIcon.settings(color, active: active), 'Settings'),
    };
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: HText.inter(size: 11, weight: active ? FontWeight.w600 : FontWeight.w500, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
