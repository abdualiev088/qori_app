import 'app_localizations.dart';

/// Plan numbers and dates in the app's language. The English versions in
/// `data/plan.dart` stay for the tests and the data layer; screens use these.

/// "1 line", "6 lines"; from 15 lines, pages to the nearest half: "1 page", "1½ pages".
String linesText(AppLocalizations l, double n) {
  final r = n.round() < 1 ? 1 : n.round();
  if (r < 15) return l.linesCount(r);
  final p = (r / 7.5).round() / 2;
  final w = p.floor();
  return p % 1 != 0 ? l.pagesHalf('$w½') : l.pagesCount(w);
}

/// What a daily line count means on the page.
String paceText(AppLocalizations l, int n) => switch (n) {
      15 => l.paceOnePage,
      30 => l.paceTwoPages,
      7 || 8 => l.paceHalfPage,
      > 15 => l.pacePagePlus(n - 15),
      _ => l.paceOfPage(n),
    };

List<String> _split(String s) => s.split(',').map((e) => e.trim()).toList();

/// Monday = index 0.
String weekdayLong(AppLocalizations l, int weekday) => _split(l.weekdaysLong)[weekday - 1];
/// The full name with a capital first letter, for labels: "Friday", "Пятница", "Juma".
String weekdayTitle(AppLocalizations l, int weekday) {
  final w = weekdayLong(l, weekday);
  return w.isEmpty ? w : w[0].toUpperCase() + w.substring(1);
}

String weekdayShort(AppLocalizations l, int weekday) => _split(l.weekdaysShort)[weekday - 1];
String weekdayLetter(AppLocalizations l, int weekday) => _split(l.weekdayLetters)[weekday - 1];

/// "Wed, 20 Jan", with the year when it isn't [now]'s.
String dateShort(AppLocalizations l, DateTime d, {DateTime? now}) {
  final base = l.dateShort(weekdayShort(l, d.weekday), d.day, _split(l.monthsShort)[d.month - 1]);
  return d.year == (now ?? DateTime.now()).year ? base : l.withYear(base, d.year);
}

/// "Wednesday, 25 November" (Home's header).
String dateLong(AppLocalizations l, DateTime d) =>
    l.dateLong(weekdayLong(l, d.weekday), d.day, _split(l.monthsLong)[d.month - 1]);
