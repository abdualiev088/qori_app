import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'plan.dart';

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

  bool isDone(DateTime day, String id) => _done[dateKey(day)]?.contains(id) ?? false;

  Future<void> toggle(DateTime day, String id) async {
    final k = dateKey(day);
    final set = _done.putIfAbsent(k, () => {});
    if (!set.remove(id)) set.add(id);
    if (set.isEmpty) _done.remove(k);
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

  // ------------------------------------------------------------ the day

  /// [day]'s tasks, empty on a rest day, before the start or after the end.
  List<PlanTask> tasksOn(DateTime day) {
    final p = _plan;
    final k = p?.lessonIndexOn(day);
    return p == null || k == null ? const [] : p.tasksFor(k);
  }

  /// Every one of [day]'s tasks is ticked (false when it has none).
  bool allDone(DateTime day) {
    final tasks = tasksOn(day);
    return tasks.isNotEmpty && tasks.every((t) => isDone(day, t.id));
  }

  /// Tasks whose time has passed today without being ticked: Morning after 12:00, Evening after 22:00.
  int behind(DateTime now) => tasksOn(now).where((t) => now.hour >= t.dueHour && !isDone(now, t.id)).length;

  /// Study days in a row, going back from today, with every task ticked.
  /// Rest days are skipped; an unfinished today doesn't break it (counting starts at yesterday).
  int streak(DateTime now) {
    final p = _plan;
    if (p == null) return 0;
    var n = 0;
    var d = dateOnly(now);
    if (!allDone(d)) d = DateTime(d.year, d.month, d.day - 1);
    while (true) {
      final k = p.lessonIndexOn(d);
      if (k == -1) break;
      if (k != null) {
        if (!allDone(d)) break;
        n++;
      }
      d = DateTime(d.year, d.month, d.day - 1);
    }
    return n;
  }

  /// This week, Monday to Sunday: whether each day was fully done.
  List<bool> week(DateTime now) {
    final monday = dateOnly(now).subtract(Duration(days: now.weekday - 1));
    return [for (var i = 0; i < 7; i++) allDone(DateTime(monday.year, monday.month, monday.day + i))];
  }
}
