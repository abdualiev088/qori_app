import 'surah_meta.dart';
import 'surahs.dart';

/// One surah's share of a juz: ayahs [from]–[to] of [surah].
class JuzPart {
  const JuzPart(this.surah, this.from, this.to);

  final int surah;
  final int from;
  final int to;

  int get ayahCount => surahAyahCounts[surah - 1];

  /// The whole surah sits in this juz.
  bool get whole => from == 1 && to == ayahCount;
}

/// The surahs of each juz, 1–30. A surah that spans juz appears in each one,
/// with the ayahs that fall in it (ported from the prototype's `juzParts()`).
final List<List<JuzPart>> juzParts = [
  for (var j = 0; j < juzStarts.length; j++) _partsOf(j),
];

List<JuzPart> _partsOf(int j) {
  final (startSurah, startAyah) = juzStarts[j];
  final next = j + 1 < juzStarts.length ? juzStarts[j + 1] : null;
  final endSurah = next == null ? 114 : (next.$2 == 1 ? next.$1 - 1 : next.$1);
  return [
    for (var s = startSurah; s <= endSurah; s++)
      JuzPart(
        s,
        s == startSurah ? startAyah : 1,
        next != null && s == next.$1 && next.$2 > 1 ? next.$2 - 1 : surahAyahCounts[s - 1],
      ),
  ];
}

/// The juz a surah starts in, 1–30.
int juzOf(int surah) {
  for (var j = juzStarts.length - 1; j >= 0; j--) {
    final (startSurah, startAyah) = juzStarts[j];
    if (startSurah < surah || (startSurah == surah && startAyah == 1)) return j + 1;
  }
  return 1;
}

/// Whether every surah touched by juz [j] (1–30) is fully memorized.
bool juzMemorized(int j, bool Function(int surah) isSurahLearned) =>
    juzParts[j - 1].every((p) => isSurahLearned(p.surah));

// ---------------------------------------------------------------- search

/// Arabic without diacritics, alef forms folded, so "الكهف" finds "الكَهۡفِ".
String foldArabic(String s) => s
    .replaceAll(RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]'), '')
    .replaceAll(RegExp('[ٱأإآ]'), 'ا')
    .replaceAll('ة', 'ه')
    .replaceAll('ى', 'ي')
    .replaceFirst(RegExp('^ال'), '');

/// A forgiving Latin key: "Ya-Sin" and "yaseen" both become "yasin".
String _fold(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r"['‘’`ʿʾ\-\s.]"), '')
    .replaceAll('ee', 'i')
    .replaceAll(RegExp('oo|ou'), 'u')
    .replaceAll('aa', 'a')
    .replaceAllMapped(RegExp(r'(.)\1'), (m) => m[1]!)
    .replaceFirst(RegExp(r'h$'), '');

/// "Al-Kahf" → "kahf", so typing without the article still matches.
String _dropArticle(String s) => s.toLowerCase().replaceFirst(RegExp(r'^(a[lnrstdz]h?|adh)-'), '');

final _latin = [for (final n in surahNames) _fold(n)];
final _latinNoArticle = [for (final n in surahNames) _fold(_dropArticle(n))];
final _arabic = [for (final n in surahArabicNames) foldArabic(n)];

/// Whether surah [n] (1–114) matches the search [query]: by number (prefix),
/// English name (forgiving: "yaseen", "kahf"), meaning ("cave") or Arabic name.
bool surahMatches(int n, String query) {
  final q = query.trim();
  if (q.isEmpty) return true;
  if (RegExp(r'^\d+$').hasMatch(q)) return '$n'.startsWith(q);
  if (RegExp('[؀-ۿ]').hasMatch(q)) return _arabic[n - 1].contains(foldArabic(q));
  final f = _fold(q);
  final fa = _fold(_dropArticle(q));
  return _latin[n - 1].contains(f) ||
      _latinNoArticle[n - 1].contains(fa) ||
      surahMeanings[n - 1].toLowerCase().contains(q.toLowerCase());
}

/// The surahs matching [query], in Mushaf order.
List<int> searchSurahs(String query) => [
      for (var n = 1; n <= 114; n++)
        if (surahMatches(n, query)) n,
    ];
