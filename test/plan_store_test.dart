import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/plan.dart';
import 'package:qori_app/data/plan_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Plan plan({int lines = 5}) => Plan(
      order: ReadingOrder.fromEnd,
      start: const Pos(114, 1),
      end: const Pos(78, 40),
      linesPerDay: lines,
      restWeekday: DateTime.friday,
      startDate: DateTime(2000),
    );

void main() {
  final mon = DateTime(2026, 11, 23);
  DateTime day(int i) => DateTime(2026, 11, 23 + i);

  Future<PlanStore> fresh([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return PlanStore.load(await SharedPreferences.getInstance());
  }

  test('a new plan starts today; an update keeps its start and the ticks', () async {
    final store = await fresh();
    await store.save(plan(), today: mon);
    expect(store.plan!.startDate, mon);
    await store.toggle(mon, 'new');
    expect(store.isDone(mon, 'new'), isTrue);

    await store.save(plan(lines: 7), today: day(3));
    expect(store.plan!.startDate, mon);
    expect(store.plan!.linesPerDay, 7);
    expect(store.isDone(mon, 'new'), isTrue);

    // Saved and read back.
    final again = PlanStore.load(await SharedPreferences.getInstance());
    expect(again.plan!.linesPerDay, 7);
    expect(again.isDone(mon, 'new'), isTrue);
  });

  test('streak counts fully done study days, skips rest days, and waits for today', () async {
    final store = await fresh();
    await store.save(plan(), today: mon);
    // Mon: new. Tue–Thu: m33 + new. Fri: rest. Sat: m33 + new.
    await store.toggle(day(0), 'new');
    for (final i in [1, 2, 3]) {
      await store.toggle(day(i), 'm33');
      await store.toggle(day(i), 'new');
    }
    expect(store.streak(day(4)), 4); // Friday, resting
    expect(store.streak(day(5).add(const Duration(hours: 9))), 4); // Saturday, not finished yet
    await store.toggle(day(5), 'm33');
    await store.toggle(day(5), 'new');
    expect(store.streak(day(5)), 5);
    expect(store.week(day(5)), [true, true, true, true, false, true, false]);
    expect(store.streak(day(7)), 0); // Sunday was missed
  });

  test('a task is behind once its time has passed', () async {
    final store = await fresh();
    await store.save(plan(), today: mon);
    await store.toggle(mon, 'new'); // Monday's lesson learned, so Tuesday recites it
    expect(store.behind(day(1).add(const Duration(hours: 11))), 0);
    expect(store.behind(day(1).add(const Duration(hours: 13))), 1);
    expect(store.behind(day(1).add(const Duration(hours: 23))), 2);
    await store.toggle(day(1), 'm33');
    expect(store.behind(day(1).add(const Duration(hours: 23))), 1);
  });

  test('the explainer is shown once', () async {
    final store = await fresh();
    expect(store.howSeen, isFalse);
    await store.markHowSeen();
    expect(PlanStore.load(await SharedPreferences.getInstance()).howSeen, isTrue);
  });

  test('each day has a state: done, partly, missed, rest, today, upcoming', () async {
    final store = await fresh();
    await store.save(plan(), today: mon);
    await store.toggle(day(0), 'new'); // Mon done
    await store.toggle(day(1), 'm33'); // Tue partly
    final now = day(3).add(const Duration(hours: 9)); // Thursday morning
    expect(store.dayState(mon.subtract(const Duration(days: 1)), now), DayState.none);
    expect(store.dayState(day(0), now), DayState.done);
    expect(store.dayState(day(1), now), DayState.partial);
    expect(store.dayState(day(2), now), DayState.missed);
    expect(store.dayState(day(3), now), DayState.today);
    expect(store.dayState(day(4), now), DayState.rest); // Friday
    expect(store.dayState(day(5), now), DayState.upcoming);
    expect(store.weekProgress(now), (1, 6));
  });

  test('the longest streak survives a break', () async {
    final store = await fresh();
    await store.save(plan(), today: mon);
    Future<void> finish(int i) async {
      if (i > 0) await store.toggle(day(i), 'm33');
      await store.toggle(day(i), 'new');
    }

    for (final i in [0, 1, 2, 3, 5]) {
      await finish(i); // Mon–Thu, (Fri rest), Sat: five in a row
    }
    await finish(7); // Mon after a missed Sunday
    expect(store.longestStreak(day(7)), 5);
    expect(store.streak(day(7)), 1);
  });

  test('an evening lesson not learned moves to the next day and adds a day', () async {
    final store = await fresh();
    await store.save(plan(), today: mon);
    final base = store.finishDate(mon)!;
    expect(store.totalDays(mon), 50);

    await store.toggle(day(0), 'new'); // Mon: lesson 1 learned
    // Tue: evening skipped.
    await store.toggle(day(2), 'new'); // Wed: lesson 2 learned (again offered)
    final thu = day(3).add(const Duration(hours: 9));

    expect(store.scheduleOn(day(1), thu)!.lesson, 1);
    expect(store.scheduleOn(day(2), thu)!.lesson, 1); // moved from Tuesday
    expect(store.scheduleOn(day(2), thu)!.recite, [0]); // nothing new to recite from Tuesday
    expect(store.scheduleOn(day(3), thu)!.lesson, 2);
    expect(store.scheduleOn(day(3), thu)!.recite, [1, 0]);
    expect(store.scheduleOn(day(5), thu)!.recite, [2, 1]); // Sat: Thu, Wed (Tue gave nothing)
    expect(store.scheduleOn(day(4), thu), isNull); // Friday rest

    expect(store.skipped(thu), 1);
    expect(store.totalDays(thu), 51);
    expect(store.finishDate(thu)!.isAfter(base), isTrue);
    expect(store.dayState(day(1), thu), DayState.missed);

    // Today's own evening isn't counted as skipped until the day is over.
    expect(store.skipped(day(3).add(const Duration(hours: 23))), 1);
    expect(store.skipped(day(5)), 2); // Thursday's evening was never ticked
  });
}
