import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_app/data/plan.dart';
import 'package:hifz_app/data/plan_store.dart';
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
}
