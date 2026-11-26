import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/plan.dart' show dateOnly;
import '../data/plan_store.dart';
import '../l10n/l10n.dart';
import '../l10n/plan_text.dart';
import '../theme/tokens.dart';
import 'glass.dart';
import 'icons.dart';

/// Monday of [d]'s week, at midnight.
DateTime mondayOf(DateTime d) {
  final day = dateOnly(d);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// "Today", "Yesterday", "Tomorrow", otherwise "Tue, 24 Nov".
String dayLabel(AppLocalizations l, DateTime day, DateTime now) {
  final diff = dateOnly(day).difference(dateOnly(now)).inDays;
  return switch (diff) {
    0 => l.today,
    -1 => l.yesterday,
    1 => l.tomorrow,
    _ => dateShort(l, day, now: now),
  };
}

String dayStateLabel(AppLocalizations l, DayState s) => switch (s) {
      DayState.done => l.legendDone,
      DayState.partial => l.legendPartial,
      DayState.missed => l.legendMissed,
      DayState.rest => l.restDay,
      DayState.today => l.today,
      DayState.upcoming => l.legendUpcoming,
      DayState.none => '',
    };

/// ‹ Today › — a 46 px frosted-glass pill that floats in Home's top bar beside
/// the round glass buttons. The arrows step one day; tapping the label opens
/// the month. The label slides the way the day moved (180 ms).
class DayPill extends StatelessWidget {
  const DayPill({
    super.key,
    required this.label,
    required this.direction,
    required this.onPrev,
    required this.onNext,
    required this.onOpen,
  });

  final String label;

  /// -1 when the last move went back, 1 forward; the new label comes in from that side.
  final int direction;
  final VoidCallback onPrev, onNext, onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reduce = MediaQuery.disableAnimationsOf(context);
    Widget arrow(IconData icon, String label, VoidCallback onTap) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: _Press(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: SizedBox(width: 40, height: 46, child: Icon(icon, size: 24, color: HColors.ink)),
          ),
        );
    return SizedBox(
      height: 46,
      child: LiquidGlass(
        radius: 23,
        blur: 20,
        borderColor: const Color(0xD9FFFFFF),
        shadows: const [
          BoxShadow(color: Color(0x2414462D), offset: Offset(0, 8), blurRadius: 20),
          BoxShadow(color: Color(0x1A14462D), offset: Offset(0, 1), blurRadius: 3),
        ],
        fill: const RadialGradient(
          center: Alignment(-0.6, -0.8),
          radius: 2.2,
          colors: [Color(0xF2FFFFFF), Color(0x8CFFFFFF), Color(0x80D6F0E2)],
          stops: [0, .45, 1],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          arrow(Icons.chevron_left_rounded, l.previousDay, onPrev),
          Semantics(
            button: true,
            label: '$label. ${l.openCalendar}',
            excludeSemantics: true,
            child: _Press(
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 88, minHeight: 46),
                child: Center(
                  child: ClipRect(
                    child: AnimatedSwitcher(
                      duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) {
                        final incoming = child.key == ValueKey(label);
                        final from = (incoming ? 0.4 : -0.4) * direction;
                        return FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween(begin: Offset(from, 0), end: Offset.zero).animate(anim),
                            child: child,
                          ),
                        );
                      },
                      child: Text(label,
                          key: ValueKey(label),
                          style: HText.inter(size: 16, weight: FontWeight.w600, letterSpacing: -0.2)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          arrow(Icons.chevron_right_rounded, l.nextDay, onNext),
        ]),
      ),
    );
  }
}

/// Monday to Sunday of the selected day's week: seven white 16 px-radius cells,
/// each a weekday and its state. The chosen day is mint-framed. A sideways swipe
/// moves a week; a new week slides in from the side it came from.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required this.selected,
    required this.now,
    required this.stateOf,
    required this.direction,
    required this.onSelect,
  });

  final DateTime selected, now;
  final DayState Function(DateTime) stateOf;
  final int direction;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final monday = mondayOf(selected);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < 200) return;
        HapticFeedback.selectionClick();
        onSelect(addDays(selected, v < 0 ? 7 : -7));
      },
      // Clips only the sides, out to the screen edge (the 16 px gutter), so a
      // sliding week disappears there while today's glow below isn't cut.
      child: ClipRect(
        clipper: const _SidesOnly(16),
        child: AnimatedSwitcher(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 260),
          switchInCurve: const Cubic(0.32, 0.72, 0, 1),
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(children: [...previous, if (current != null) current]),
          transitionBuilder: (child, anim) {
            final incoming = child.key == ValueKey(monday);
            final from = (incoming ? 1.0 : -1.0) * direction;
            return SlideTransition(
              position: Tween(begin: Offset(from, 0), end: Offset.zero).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            );
          },
          child: Row(
            key: ValueKey(monday),
            children: [
              for (var i = 0; i < 7; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: _DayCell(
                    day: addDays(monday, i),
                    now: now,
                    selected: dateOnly(selected) == addDays(monday, i),
                    state: stateOf(addDays(monday, i)),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSelect(addDays(monday, i));
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A clip that trims left and right ([overhang] px past the edges) but lets
/// shadows spill freely above and below.
class _SidesOnly extends CustomClipper<Rect> {
  const _SidesOnly(this.overhang);
  final double overhang;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(-overhang, -40, size.width + overhang, size.height + 40);

  @override
  bool shouldReclip(_SidesOnly old) => old.overhang != overhang;
}

/// One day in the strip: weekday, date and state badge. Today is always the
/// filled green cell, so it's the first thing the eye finds; another picked
/// day gets a mint frame.
class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.now, required this.selected, required this.state, required this.onTap});

  final DateTime day, now;
  final bool selected;
  final DayState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isToday = dateOnly(day) == dateOnly(now);
    final stateText = dayStateLabel(l, state);
    final ink = isToday ? Colors.white : HColors.ink;
    final soft = isToday ? Colors.white.withValues(alpha: 0.85) : HColors.ink2;
    return Semantics(
      button: true,
      selected: selected,
      label: [
        weekdayTitle(l, day.weekday),
        '${day.day}',
        if (isToday) l.today,
        if (stateText.isNotEmpty && state != DayState.today) stateText,
      ].join(', '),
      excludeSemantics: true,
      child: _Press(
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: isToday ? null : (selected ? HColors.mintSelected : HColors.surface),
            gradient: isToday
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2CC774), Color(0xFF169A55)],
                  )
                : null,
            borderRadius: BorderRadius.circular(16),
            // Picking today again (or leaving it) shows as a darker ring on the green.
            border: Border.all(
              color: isToday
                  ? (selected ? HColors.accentDeep : const Color(0xFF2CC774))
                  : (selected ? HColors.mintRing : HColors.surface),
              width: isToday && selected ? 2 : 1.5,
            ),
            boxShadow: isToday
                ? const [BoxShadow(color: Color(0x4022B567), offset: Offset(0, 6), blurRadius: 14)]
                : const [BoxShadow(color: Color(0x0A14281E), offset: Offset(0, 1), blurRadius: 3)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(weekdayShort(l, day.weekday),
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: HText.inter(size: 11, weight: FontWeight.w600, color: soft)),
            const SizedBox(height: 1),
            Text('${day.day}',
                style: HText.inter(size: 17, weight: FontWeight.w700, tabular: true, color: ink, height: 1.2)),
            const SizedBox(height: 5),
            DayStateIcon(state: state, size: 24, onAccent: isToday),
          ]),
        ),
      ),
    );
  }
}

/// A day's state as a round badge: a green check (done), a half amber ring
/// (partly), a soft red cross (missed), a green flame on mint (today), a gray
/// flame (coming up), a sofa (rest, as on the plan card), or an empty ring (nothing planned).
class DayStateIcon extends StatelessWidget {
  const DayStateIcon({super.key, required this.state, this.size = 28, this.onAccent = false});

  final DayState state;
  final double size;

  /// On today's green cell: a white disc with a green glyph.
  final bool onAccent;

  @override
  Widget build(BuildContext context) {
    final glyph = size * 0.55;
    final (Color fill, Widget? inner) = switch (state) {
      DayState.done => (HColors.accent, HIcon.check(Colors.white, size: glyph, width: 2.6)),
      DayState.partial => (
          HColors.morningSoft,
          CustomPaint(size: Size.square(size), painter: const _HalfRing(HColors.morningInk)),
        ),
      DayState.missed => (HColors.warnSoft, Icon(Icons.close_rounded, size: glyph, color: HColors.warn)),
      DayState.today => (
          HColors.mintWash,
          Icon(Icons.local_fire_department_rounded, size: glyph + 2, color: HColors.accent),
        ),
      DayState.upcoming => (
          HColors.bgTop,
          Icon(Icons.local_fire_department_rounded, size: glyph + 2, color: const Color(0xFFC3CAD1)),
        ),
      DayState.rest => (HColors.bgTop, Icon(Icons.weekend_rounded, size: glyph, color: const Color(0xFFAAB3BD))),
      DayState.none => (Colors.transparent, null),
    };
    if (onAccent) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: switch (state) {
          DayState.done => HIcon.check(HColors.accentDeep, size: glyph, width: 2.6),
          DayState.rest => Icon(Icons.weekend_rounded, size: glyph, color: HColors.accentDeep),
          DayState.none => null,
          _ => Icon(Icons.local_fire_department_rounded, size: glyph + 2, color: HColors.accent),
        },
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: state == DayState.none ? Border.all(color: HColors.track, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: inner,
    );
  }
}

class _HalfRing extends CustomPainter {
  const _HalfRing(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - 5;
    final c = size.center(Offset.zero);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(c, r, p..color = color.withValues(alpha: 0.2));
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, math.pi, false, p..color = color);
  }

  @override
  bool shouldRepaint(_HalfRing old) => old.color != color;
}

// ---------------------------------------------------------------- the month

/// The whole month in a bottom sheet: ‹ November 2026 ›, a Monday-first grid
/// where each day shows its state, a legend, and "Back to today". Tapping a day
/// closes the sheet and returns it.
class MonthCalendarSheet extends StatefulWidget {
  const MonthCalendarSheet({super.key, required this.selected, required this.now, required this.stateOf});

  final DateTime selected, now;
  final DayState Function(DateTime) stateOf;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime selected,
    required DateTime now,
    required DayState Function(DateTime) stateOf,
  }) =>
      showModalBottomSheet<DateTime>(
        context: context,
        isScrollControlled: true,
        backgroundColor: HColors.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(HRadii.panel))),
        builder: (_) => MonthCalendarSheet(selected: selected, now: now, stateOf: stateOf),
      );

  @override
  State<MonthCalendarSheet> createState() => _MonthCalendarSheetState();
}

class _MonthCalendarSheetState extends State<MonthCalendarSheet> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);
  int _dir = 1;

  void _move(int d) {
    HapticFeedback.selectionClick();
    setState(() {
      _dir = d;
      _month = DateTime(_month.year, _month.month + d);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final months = l.monthsStandalone.split(',');
    final title = l.monthYear(months[_month.month - 1].trim(), _month.year);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final letters = l.weekdayLetters.split(',');

    Widget navButton(IconData icon, String label, int d) => Semantics(
          button: true,
          label: label,
          excludeSemantics: true,
          child: _Press(
            onTap: () => _move(d),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: HColors.bgTop, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: HColors.ink),
            ),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          navButton(Icons.chevron_left_rounded, l.previousMonth, -1),
          Expanded(
            child: Semantics(
              header: true,
              liveRegion: true,
              child: Text(title,
                  textAlign: TextAlign.center, style: HText.inter(size: 18, weight: FontWeight.w700, letterSpacing: -0.2)),
            ),
          ),
          navButton(Icons.chevron_right_rounded, l.nextMonth, 1),
        ]),
        const SizedBox(height: 14),
        ExcludeSemantics(
          child: Row(children: [
            for (final s in letters)
              Expanded(
                child: Text(s.trim(),
                    textAlign: TextAlign.center,
                    style: HText.inter(size: 12, weight: FontWeight.w600, color: HColors.inkMuted)),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v.abs() > 200) _move(v < 0 ? 1 : -1);
          },
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: reduce ? Duration.zero : const Duration(milliseconds: 260),
              switchInCurve: const Cubic(0.32, 0.72, 0, 1),
              switchOutCurve: Curves.easeIn,
              layoutBuilder: (current, previous) =>
                  Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
              transitionBuilder: (child, anim) {
                final incoming = child.key == ValueKey(_month);
                return SlideTransition(
                  position: Tween(begin: Offset((incoming ? 0.3 : -0.3) * _dir, 0), end: Offset.zero).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
              child: _MonthGrid(
                key: ValueKey(_month),
                month: _month,
                now: widget.now,
                selected: widget.selected,
                stateOf: widget.stateOf,
                onPick: (d) => Navigator.of(context).pop(d),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 8, alignment: WrapAlignment.center, children: [
          for (final s in const [DayState.done, DayState.partial, DayState.missed, DayState.rest, DayState.upcoming])
            Row(mainAxisSize: MainAxisSize.min, children: [
              DayStateIcon(state: s, size: 18),
              const SizedBox(width: 5),
              Text(dayStateLabel(l, s), style: HText.inter(size: 12, color: HColors.ink2)),
            ]),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(dateOnly(widget.now)),
            style: OutlinedButton.styleFrom(
              foregroundColor: HColors.ink,
              side: const BorderSide(color: HColors.track),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: HText.inter(size: 15, weight: FontWeight.w600),
            ),
            child: Text(l.backToToday),
          ),
        ),
      ]),
    );
  }
}

/// Six rows of seven 44 px day cells; days outside [month] are left blank.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    super.key,
    required this.month,
    required this.now,
    required this.selected,
    required this.stateOf,
    required this.onPick,
  });

  final DateTime month, now, selected;
  final DayState Function(DateTime) stateOf;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    final rows = ((lead + days) / 7).ceil();
    return Column(children: [
      for (var r = 0; r < rows; r++)
        Row(children: [
          for (var c = 0; c < 7; c++)
            Expanded(
              child: Builder(builder: (context) {
                final n = r * 7 + c - lead + 1;
                if (n < 1 || n > days) return const SizedBox(height: 46);
                final day = DateTime(month.year, month.month, n);
                final state = stateOf(day);
                final isToday = day == dateOnly(now);
                final isSelected = day == dateOnly(selected);
                final (Color fill, Color ink, Color? ring) = switch (state) {
                  DayState.done => (HColors.accent, Colors.white, null),
                  DayState.partial => (HColors.morningSoft, HColors.morningInk, null),
                  DayState.missed => (HColors.warnSoft, HColors.warn, null),
                  DayState.today => (HColors.mintWash, HColors.accentDeep, null),
                  DayState.rest => (Colors.transparent, const Color(0xFFAAB3BD), null),
                  DayState.upcoming => (Colors.transparent, HColors.ink, HColors.track),
                  DayState.none => (Colors.transparent, HColors.inkMuted, null),
                };
                final stateText = dayStateLabel(l, state);
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: [dateLong(l, day), if (stateText.isNotEmpty) stateText].join(', '),
                  excludeSemantics: true,
                  child: _Press(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onPick(day);
                    },
                    child: SizedBox(
                      height: 46,
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: fill,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: HColors.ink, width: 2)
                                : isToday
                                    ? Border.all(color: HColors.accentDeep, width: 1.5)
                                    : ring == null
                                        ? null
                                        : Border.all(color: ring, width: 1),
                          ),
                          child: Text('$n',
                              style: HText.inter(
                                  size: 14,
                                  weight: isToday || state == DayState.done ? FontWeight.w700 : FontWeight.w500,
                                  tabular: true,
                                  color: ink)),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
        ]),
    ]);
  }
}

/// Shrinks to 0.96 while pressed (100 ms in, eased back on release).
class _Press extends StatefulWidget {
  const _Press({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Press> createState() => _PressState();
}

class _PressState extends State<_Press> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}
