import 'ayah_lines.dart';
import 'surahs.dart';

/// The one memorization method: "33 repetitions". Learn the new portion in the
/// evening, then recite it 33 times from memory on each of the next three mornings.

/// Al-Fatihah first, or An-Nas first (Juz ʿAmma, surahs backwards, ayahs forwards).
enum ReadingOrder { fromBeginning, fromEnd }

/// An ayah: surah 1–114, ayah 1–n.
class Pos {
  const Pos(this.s, this.a);

  final int s, a;

  @override
  bool operator ==(Object other) => other is Pos && other.s == s && other.a == a;

  @override
  int get hashCode => Object.hash(s, a);

  @override
  String toString() => '$s:$a';

  Map<String, int> toJson() => {'s': s, 'a': a};
  factory Pos.fromJson(Map<String, dynamic> j) => Pos(j['s'] as int, j['a'] as int);
}

/// Mushaf lines (15-line Madani) for one ayah, estimated from its letters.
double linesOf(int s, int a) => ayahLineTenths[s - 1][a - 1] / 10;

double sumLines(Iterable<Pos> list) => list.fold(0, (n, p) => n + linesOf(p.s, p.a));

int ayahsIn(int s) => surahAyahCounts[s - 1];

String nameOf(int s) => surahNames[s - 1];

/// Dates are kept as midnight local time.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _fromKey(String k) {
  final [y, m, d] = k.split('-').map(int.parse).toList();
  return DateTime(y, m, d);
}

class Plan {
  Plan({
    required this.order,
    required this.start,
    required this.end,
    required this.linesPerDay,
    required this.restWeekday,
    required DateTime startDate,
  }) : startDate = dateOnly(startDate);

  final ReadingOrder order;
  final Pos start, end;

  /// New mushaf lines a day, 1–30.
  final int linesPerDay;

  /// [DateTime.friday] and so on, or null for no rest day.
  final int? restWeekday;
  final DateTime startDate;

  static const maxLines = 30;

  Plan copyWith({DateTime? startDate}) => Plan(
        order: order,
        start: start,
        end: end,
        linesPerDay: linesPerDay,
        restWeekday: restWeekday,
        startDate: startDate ?? this.startDate,
      );

  Map<String, dynamic> toJson() => {
        'order': order.name,
        'start': start.toJson(),
        'end': end.toJson(),
        'linesPerDay': linesPerDay,
        'restWeekday': restWeekday,
        'startDate': dateKey(startDate),
      };

  factory Plan.fromJson(Map<String, dynamic> j) => Plan(
        order: ReadingOrder.values.byName(j['order'] as String),
        start: Pos.fromJson((j['start'] as Map).cast()),
        end: Pos.fromJson((j['end'] as Map).cast()),
        linesPerDay: j['linesPerDay'] as int,
        restWeekday: j['restWeekday'] as int?,
        startDate: _fromKey(j['startDate'] as String),
      );

  /// The end comes after the start in this reading order.
  bool get valid {
    if (start.s == end.s) return end.a >= start.a;
    return order == ReadingOrder.fromBeginning ? end.s > start.s : end.s < start.s;
  }

  /// Every ayah from start to end: surahs in reading order, ayahs ascending inside each.
  List<Pos> get positions {
    final out = <Pos>[];
    final step = order == ReadingOrder.fromBeginning ? 1 : -1;
    for (var s = start.s;; s += step) {
      final a1 = s == start.s ? start.a : 1;
      final a2 = s == end.s ? end.a : ayahsIn(s);
      for (var a = a1; a <= a2; a++) {
        out.add(Pos(s, a));
      }
      if (s == end.s) break;
    }
    return out;
  }

  List<List<Pos>>? _lessons;

  /// One lesson per study day, about [linesPerDay] lines of whole ayahs. Short
  /// surahs are kept whole (up to 1.5× the pace), a lesson ends at a surah
  /// boundary once it's half full, and only long surahs are split. A single
  /// very long ayah (Al-Baqarah 282) is a lesson on its own.
  List<List<Pos>> get lessons => _lessons ??= _split();

  List<List<Pos>> _split() {
    final pace = linesPerDay.toDouble();
    final max = pace * 1.5, half = pace / 2;
    final bySurah = <List<Pos>>[];
    for (final p in positions) {
      if (bySurah.isNotEmpty && bySurah.last.first.s == p.s) {
        bySurah.last.add(p);
      } else {
        bySurah.add([p]);
      }
    }
    final out = <List<Pos>>[];
    var cur = <Pos>[];
    var w = 0.0;
    void close() {
      if (cur.isNotEmpty) out.add(cur);
      cur = [];
      w = 0;
    }

    for (final group in bySurah) {
      final rest = [...group];
      var rw = sumLines(rest);
      while (rest.isNotEmpty) {
        if (w + rw <= max) {
          cur.addAll(rest);
          rest.clear();
          w += rw;
          rw = 0;
          if (w >= pace * 0.9) close();
        } else if (w >= half) {
          close();
        } else {
          // Take ayahs while most of the next one still fits; always at least one.
          do {
            final p = rest.removeAt(0);
            final l = linesOf(p.s, p.a);
            cur.add(p);
            w += l;
            rw -= l;
          } while (rest.isNotEmpty && w + linesOf(rest.first.s, rest.first.a) / 2 <= pace);
          close();
        }
      }
    }
    close();
    return out;
  }

  /// Which lesson falls on [date]: -1 before the start, null on the rest day,
  /// otherwise the number of study days since the start (≥ lessons.length once finished).
  int? lessonIndexOn(DateTime date) {
    final day = dateOnly(date);
    if (day.isBefore(startDate)) return -1;
    if (restWeekday != null && day.weekday == restWeekday) return null;
    var k = 0;
    for (var d = startDate; d.isBefore(day); d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.weekday != restWeekday) k++;
    }
    return k;
  }

  /// The date of the [n]-th study day (1-based).
  DateTime finishDate([int? n]) {
    final target = n ?? lessons.length;
    var k = 0;
    for (var d = startDate;; d = DateTime(d.year, d.month, d.day + 1)) {
      if (d.weekday != restWeekday && ++k >= target) return d;
    }
  }

  /// Today's tasks for lesson [k]: the morning recitation of the last three
  /// lessons (from day 2), then the evening's new lesson.
  List<PlanTask> tasksFor(int k) {
    final l = lessons;
    if (k < 0 || k >= l.length) return const [];
    final back = [for (final i in [k - 1, k - 2, k - 3]) if (i >= 0) i];
    return [
      if (back.isNotEmpty)
        PlanTask(
          id: 'm33',
          title: 'Recite ${span(l[back.last].first, l[back.first].last)}',
          subtitle: '${fmtLines(sumLines([for (final i in back.reversed) ...l[i]]))} · 33× from memory · '
              'last ${back.length} ${back.length == 1 ? 'lesson' : 'lessons'}',
          time: 'Morning',
          dueHour: 12,
          range: span(l[back.last].first, l[back.first].last),
          amount: fmtLines(sumLines([for (final i in back.reversed) ...l[i]])),
        ),
      PlanTask(
        id: 'new',
        title: 'Memorize ${seg(l[k])}',
        subtitle: '${fmtLines(sumLines(l[k]))} · about one hour, before 22:00',
        time: 'Evening',
        dueHour: 22,
        range: seg(l[k]),
        amount: fmtLines(sumLines(l[k])),
      ),
    ];
  }
}

/// One thing to do on a study day, ticked by [id].
class PlanTask {
  const PlanTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.dueHour,
    required this.range,
    required this.amount,
  });

  /// Morning recitation ("m33") or the evening's new lesson ("new").
  bool get morning => id == 'm33';

  /// Just the ayahs, without the verb: "An-Nas · Al-Falaq", "An-Nas 1 → Quraysh 4".
  final String range;

  /// How much, from [fmtLines]: "5 lines", "1½ pages".
  final String amount;

  final String id;
  final String title;
  final String subtitle;

  /// "Morning" or "Evening".
  final String time;

  /// After this hour the task counts as behind if it isn't ticked.
  final int dueHour;
}

/// Whole surahs by name, partial ones with their ayahs: "An-Nas · Al-Falaq",
/// "Al-Mulk 1–5", "Al-Baqarah 282".
String seg(List<Pos> lesson) {
  final groups = <(int, int, int)>[];
  for (final p in lesson) {
    if (groups.isNotEmpty && groups.last.$1 == p.s) {
      groups.last = (p.s, groups.last.$2, p.a);
    } else {
      groups.add((p.s, p.a, p.a));
    }
  }
  return groups.map((g) {
    final (s, a, b) = g;
    if (a == 1 && b == ayahsIn(s)) return nameOf(s);
    return a == b ? '${nameOf(s)} $a' : '${nameOf(s)} $a–$b';
  }).join(' · ');
}

/// A span across lessons: "Al-Mulk 1–30", "Al-Mulk", or "An-Nas 1 → Quraysh 4".
String span(Pos first, Pos last) {
  if (first.s == last.s) {
    if (first.a == 1 && last.a == ayahsIn(first.s)) return nameOf(first.s);
    return first.a == last.a ? '${nameOf(first.s)} ${first.a}' : '${nameOf(first.s)} ${first.a}–${last.a}';
  }
  return '${nameOf(first.s)} ${first.a} → ${nameOf(last.s)} ${last.a}';
}

/// "1 line", "6 lines"; from 15 lines, pages to the nearest half: "1 page", "1½ pages".
String fmtLines(double n) {
  final r = n.round() < 1 ? 1 : n.round();
  if (r < 15) return '$r ${r == 1 ? 'line' : 'lines'}';
  final p = (r / 7.5).round() / 2;
  final w = p.floor();
  return '$w${p % 1 != 0 ? '½' : ''} ${p > 1 ? 'pages' : 'page'}';
}

/// What a daily line count means on the page.
String paceWord(int n) => switch (n) {
      15 => 'one full page',
      30 => 'two full pages',
      7 || 8 => 'about half a page',
      > 15 => 'a page and ${n - 15} ${n - 15 == 1 ? 'line' : 'lines'}',
      _ => '$n of 15 lines on a page',
    };

const _shortWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _shortMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// "Wed, 20 Jan", with the year when it isn't [now]'s.
String fmtDate(DateTime d, {DateTime? now}) {
  final base = '${_shortWeekdays[d.weekday - 1]}, ${d.day} ${_shortMonths[d.month - 1]}';
  return d.year == (now ?? DateTime.now()).year ? base : '$base ${d.year}';
}
