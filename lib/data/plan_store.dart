import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'plan.dart';

/// How a calendar day looks: nothing planned, a rest day, fully done, partly
/// done or missed (past days), today still open, or a study day still ahead.
enum DayState { none, rest, done, partial, missed, today, upcoming }

/// The memorization plan, which of each day's tasks are ticked, and whether
/// the full "How it works" explainer has been shown. Saved on the device.
class PlanStore extends ChangeNotifier {
  PlanStore._(this._prefs, this._plan, this._done, this._howSeen);

  /// Reads the saved state; anything unreadable starts empty.
  factory PlanStore.load(SharedPreferences prefs) {
    Plan? plan;
    final done = <String, Set<String>>{};
    try {
      final raw = prefs.getString(planKey);
      if (raw != null) plan = Plan.fromJson((jsonDecode(raw) as Map).cast());
    } catch (_) {}
    try {
      final raw = prefs.getString(doneKey);
      if (raw != null) {
        for (final MapEntry(:key, :value) in (jsonDecode(raw) as Map).entries) {
          done[key as String] = {for (final id in value as List) id as String};
        }
      }
    } catch (_) {}
    return PlanStore._(prefs, plan, done, prefs.getBool(howSeenKey) ?? false);
  }

  static const planKey = 'hifdth.plan.v1';
  static const doneKey = 'hifdth.plan.done.v1';
  static const howSeenKey = 'hifdth.howseen.v1';

  final SharedPreferences _prefs;
  Plan? _plan;
  final Map<String, Set<String>> _done;
  bool _howSeen;

  Plan? get plan => _plan;
  bool get howSeen => _howSeen;

  /// A new plan clears the ticks and starts [today]; an update keeps both.
  Future<void> save(Plan plan, {DateTime? today}) async {
    final old = _plan;
    _doneVersion++;
    if (old == null) {
      _done.clear();
      _plan = plan.copyWith(startDate: today ?? DateTime.now());
    } else {
      _plan = plan.copyWith(startDate: old.startDate);
    }
    notifyListeners();
    await _prefs.setString(planKey, jsonEncode(_plan!.toJson()));
    await _saveDone();
  }

  /// Evening lessons ticked so far (each one a lesson learned).
  int get lessonsLearned => _done.values.where((ids) => ids.contains('new')).length;

  bool isDone(DateTime day, String id) => _done[dateKey(day)]?.contains(id) ?? false;

  Future<void> toggle(DateTime day, String id) async {
    final k = dateKey(day);
    final set = _done.putIfAbsent(k, () => {});
    if (!set.remove(id)) set.add(id);
    if (set.isEmpty) _done.remove(k);
    _doneVersion++;
    notifyListeners();
    await _saveDone();
  }

  Future<void> markHowSeen() async {
    if (_howSeen) return;
    _howSeen = true;
    notifyListeners();
    await _prefs.setBool(howSeenKey, true);
  }

  Future<void> _saveDone() =>
      _prefs.setString(doneKey, jsonEncode({for (final e in _done.entries) e.key: e.value.toList()..sort()}));

  // ------------------------------------------------------------ the schedule

  /// One study day: its number from the start (1-based), the lesson to memorize
  /// that evening, and the lessons recited that morning (newest first).
  /// Past days use the real ticks; today and later assume every evening gets learned.
  ({int number, int lesson, List<int> recite})? scheduleOn(DateTime day, DateTime now) =>
      _schedule(now).days[dateOnly(day)];

  /// Past study days whose evening lesson wasn't learned. Each one moves the
  /// lesson to the next study day and the finish one study day later.
  int skipped(DateTime now) => _schedule(now).skipped;

  /// Study days from the start to the (projected) finish: lessons + skipped.
  int totalDays(DateTime now) => _schedule(now).days.length;

  /// The last study day, assuming every evening from today on gets learned.
  DateTime? finishDate(DateTime now) => _schedule(now).last;

  /// Every lesson has been learned (the day after the last evening).
  bool finished(DateTime now) {
    final p = _plan;
    final last = _schedule(now).last;
    return p != null && last != null && dateOnly(now).isAfter(last);
  }

  _Schedule? _cache;
  String? _cacheKey;

  _Schedule _schedule(DateTime now) {
    final p = _plan;
    final key = '${identityHashCode(p)}|${dateKey(now)}|$_doneVersion';
    if (_cache != null && _cacheKey == key) return _cache!;
    final days = <DateTime, ({int number, int lesson, List<int> recite})>{};
    var skipped = 0;
    DateTime? last;
    if (p != null) {
      final total = p.lessons.length;
      final today = dateOnly(now);
      final learnedOn = <int?>[]; // per study day: the lesson learned that evening, or null
      var learned = 0;
      var d = p.startDate;
      for (var guard = 0; learned < total && guard < 20000; guard++, d = DateTime(d.year, d.month, d.day + 1)) {
        if (d.weekday == p.restWeekday) continue;
        final recite = [
          for (var i = learnedOn.length - 1; i >= 0 && i >= learnedOn.length - 3; i--)
            if (learnedOn[i] != null) learnedOn[i]!,
        ];
        days[d] = (number: learnedOn.length + 1, lesson: learned, recite: recite);
        final got = d.isBefore(today) ? isDone(d, 'new') : true;
        if (got) {
          learnedOn.add(learned);
          learned++;
        } else {
          learnedOn.add(null);
          skipped++;
        }
        last = d;
      }
    }
    _cacheKey = key;
    return _cache = _Schedule(days, skipped, last);
  }

  var _doneVersion = 0;

  // ------------------------------------------------------------ the day

  /// [day]'s tasks: morning recitation of what was learned on the three study
  /// days before it, then the evening lesson. Empty on a rest day, before the
  /// start or after the last lesson.
  List<PlanTask> tasksOn(DateTime day, [DateTime? now]) {
    final p = _plan;
    final s = scheduleOn(day, now ?? DateTime.now());
    return p == null || s == null ? const [] : p.tasksForLessons(s.lesson, s.recite);
  }

  /// Every one of [day]'s tasks is ticked (false when it has none).
  bool allDone(DateTime day, [DateTime? now]) {
    final tasks = tasksOn(day, now);
    return tasks.isNotEmpty && tasks.every((t) => isDone(day, t.id));
  }

  /// Tasks whose time has passed today without being ticked: Morning after 12:00, Evening after 22:00.
  int behind(DateTime now) => tasksOn(now, now).where((t) => now.hour >= t.dueHour && !isDone(now, t.id)).length;

  /// [day]'s state as of [now] (see [DayState]).
  DayState dayState(DateTime day, DateTime now) {
    final p = _plan;
    if (p == null) return DayState.none;
    final d = dateOnly(day), today = dateOnly(now);
    if (!d.isBefore(p.startDate) && d.weekday == p.restWeekday) {
      final last = finishDate(now);
      return last == null || !d.isAfter(last) ? DayState.rest : DayState.none;
    }
    final tasks = tasksOn(d, now);
    if (tasks.isEmpty) return DayState.none;
    final done = tasks.every((t) => isDone(d, t.id));
    if (d == today) return done ? DayState.done : DayState.today;
    if (d.isAfter(today)) return DayState.upcoming;
    if (done) return DayState.done;
    return tasks.any((t) => isDone(d, t.id)) ? DayState.partial : DayState.missed;
  }

  /// Study days in a row, going back from today, with every task ticked.
  /// Rest days are skipped; an unfinished today doesn't break it (counting starts at yesterday).
  int streak(DateTime now) {
    final p = _plan;
    if (p == null) return 0;
    var n = 0;
    var d = dateOnly(now);
    if (!allDone(d, now)) d = DateTime(d.year, d.month, d.day - 1);
    while (!d.isBefore(p.startDate)) {
      if (d.weekday != p.restWeekday) {
        if (!allDone(d, now)) break;
        n++;
      }
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  /// The longest run of fully done study days so far (rest days don't break it).
  int longestStreak(DateTime now) {
    final p = _plan;
    if (p == null) return 0;
    final today = dateOnly(now);
    var best = 0, run = 0;
    for (var d = p.startDate; !d.isAfter(today); d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.weekday == p.restWeekday) continue;
      if (allDone(d, now)) {
        run++;
        if (run > best) best = run;
      } else if (d != today) {
        run = 0;
      }
    }
    return best;
  }

  /// This week's study days that are fully done, and how many study days it has.
  (int, int) weekProgress(DateTime now) {
    final monday = dateOnly(now).subtract(Duration(days: now.weekday - 1));
    var done = 0, total = 0;
    for (var i = 0; i < 7; i++) {
      final d = DateTime(monday.year, monday.month, monday.day + i);
      if (tasksOn(d, now).isEmpty) continue;
      total++;
      if (allDone(d, now)) done++;
    }
    return (done, total);
  }

  /// This week, Monday to Sunday: whether each day was fully done.
  List<bool> week(DateTime now) {
    final monday = dateOnly(now).subtract(Duration(days: now.weekday - 1));
    return [for (var i = 0; i < 7; i++) allDone(DateTime(monday.year, monday.month, monday.day + i), now)];
  }
}

class _Schedule {
  _Schedule(this.days, this.skipped, this.last);
  final Map<DateTime, ({int number, int lesson, List<int> recite})> days;
  final int skipped;
  final DateTime? last;
}
