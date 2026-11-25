import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/ayah_lines.dart';
import 'package:qori_app/data/plan.dart';

Plan plan({
  ReadingOrder order = ReadingOrder.fromEnd,
  Pos start = const Pos(114, 1),
  Pos end = const Pos(78, 40),
  int lines = 5,
  int? rest,
  DateTime? startDate,
}) =>
    Plan(
      order: order,
      start: start,
      end: end,
      linesPerDay: lines,
      restWeekday: rest,
      startDate: startDate ?? DateTime(2026, 11, 23), // a Monday
    );

void main() {
  test('line data covers the Quran at about the printed mushaf length', () {
    final all = ayahLineTenths.expand((s) => s).fold(0, (a, b) => a + b);
    expect(all, closeTo(88300, 300));
    final amma = ayahLineTenths.sublist(77).expand((s) => s).fold(0, (a, b) => a + b);
    expect(amma / 10, closeTo(265, 10));
  });

  test('An-Nas → An-Naba at 5 lines a day is 50 lessons, short surahs kept whole', () {
    final l = plan().lessons;
    expect(l.length, 50);
    expect(l.take(4).map(seg), [
      'An-Nas · Al-Falaq · Al-Ikhlas',
      'Al-Masad · An-Nasr · Al-Kafirun',
      "Al-Kawthar · Al-Ma'un · Quraysh",
      'Al-Fil · Al-Humazah',
    ]);
    expect(plan(lines: 7).lessons.length, 36);
  });

  test('a long surah is split on whole ayahs', () {
    final p = plan(order: ReadingOrder.fromBeginning, start: const Pos(67, 1), end: const Pos(67, 30), lines: 7);
    expect(p.lessons.map(seg), ['Al-Mulk 1–5', 'Al-Mulk 6–11', 'Al-Mulk 12–17', 'Al-Mulk 18–22', 'Al-Mulk 23–30']);
  });

  test('a very long ayah is a lesson on its own', () {
    final p = plan(order: ReadingOrder.fromBeginning, start: const Pos(2, 281), end: const Pos(2, 283));
    expect(p.lessons.map(seg), ['Al-Baqarah 281', 'Al-Baqarah 282', 'Al-Baqarah 283']);
  });

  test('day 1 only memorizes; day 4 recites the last three lessons in the morning', () {
    final p = plan();
    final day1 = p.tasksFor(0);
    expect(day1.map((t) => t.id), ['new']);
    expect(day1.single.title, 'Memorize An-Nas · Al-Falaq · Al-Ikhlas');
    expect(day1.single.time, 'Evening');

    final day4 = p.tasksFor(3);
    expect(day4.map((t) => t.id), ['m33', 'new']);
    expect(day4.first.title, 'Recite An-Nas 1 → Quraysh 4');
    expect(day4.first.subtitle, endsWith('33× from memory · last 3 lessons'));
    expect(day4.first.time, 'Morning');
    expect(p.tasksFor(1).first.subtitle, endsWith('last 1 lesson'));
  });

  test('the rest day has no lesson, and the finish date skips it', () {
    final p = plan(rest: DateTime.friday); // starts Monday 23 Nov 2026
    expect(p.lessonIndexOn(DateTime(2026, 11, 22)), -1);
    expect(p.lessonIndexOn(DateTime(2026, 11, 23)), 0);
    expect(p.lessonIndexOn(DateTime(2026, 11, 26)), 3);
    expect(p.lessonIndexOn(DateTime(2026, 11, 27)), isNull); // Friday
    expect(p.lessonIndexOn(DateTime(2026, 11, 28)), 4);
    expect(p.finishDate(5), DateTime(2026, 11, 28));
    expect(p.finishDate(4), DateTime(2026, 11, 26));
    expect(plan().finishDate(5), DateTime(2026, 11, 27));
  });

  test('the end must come after the start in the reading order', () {
    expect(plan().valid, isTrue);
    expect(plan(end: const Pos(114, 1)).valid, isTrue);
    expect(plan(start: const Pos(78, 1), end: const Pos(114, 6)).valid, isFalse);
    expect(plan(order: ReadingOrder.fromBeginning).valid, isFalse);
    expect(plan(order: ReadingOrder.fromBeginning, start: const Pos(67, 10), end: const Pos(67, 9)).valid, isFalse);
  });

  test('labels', () {
    expect(span(const Pos(67, 1), const Pos(67, 30)), 'Al-Mulk');
    expect(span(const Pos(67, 1), const Pos(67, 12)), 'Al-Mulk 1–12');
    expect(fmtLines(1), '1 line');
    expect(fmtLines(6.2), '6 lines');
    expect(fmtLines(15), '1 page');
    expect(fmtLines(23), '1½ pages');
    expect(fmtLines(45), '3 pages');
    expect(paceWord(7), 'about half a page');
    expect(paceWord(17), 'a page and 2 lines');
    expect(paceWord(5), '5 of 15 lines on a page');
  });

  test('round-trips through JSON', () {
    final p = plan(rest: DateTime.friday, lines: 7);
    final q = Plan.fromJson(p.toJson());
    expect(q.toJson(), p.toJson());
    expect(q.lessons.length, p.lessons.length);
  });
}
