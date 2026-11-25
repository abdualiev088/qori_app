import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_app/data/surah_index.dart';
import 'package:hifz_app/data/surahs.dart';

void main() {
  test('30 juz, and every ayah of the Quran falls in exactly one', () {
    expect(juzParts, hasLength(30));
    final seen = <String>{};
    for (final parts in juzParts) {
      for (final p in parts) {
        for (var a = p.from; a <= p.to; a++) {
          expect(seen.add('${p.surah}:$a'), isTrue, reason: '${p.surah}:$a twice');
        }
      }
    }
    expect(seen.length, surahAyahCounts.fold<int>(0, (a, b) => a + b));
  });

  test('a surah that spans juz appears in each, with its ayahs', () {
    expect(juzParts[0].map((p) => (p.surah, p.from, p.to)), [(1, 1, 7), (2, 1, 141)]);
    expect(juzParts[1].single, isA<JuzPart>().having((p) => (p.from, p.to), 'ayahs', (142, 252)));
    expect(juzParts[29].first.surah, 78);
    expect(juzParts[29].last.surah, 114);
  });

  test('search is forgiving about names, and covers numbers, meanings and Arabic', () {
    expect(searchSurahs('yaseen'), [36]);
    expect(searchSurahs('kahf'), [18]);
    expect(searchSurahs('Al-Kahf'), [18]);
    expect(searchSurahs('cave'), [18]);
    expect(searchSurahs('68'), [68]);
    expect(searchSurahs('11'), containsAll([11, 110, 111, 112, 113, 114]));
    expect(searchSurahs('الكهف'), [18]);
    expect(searchSurahs('zzzz'), isEmpty);
    expect(juzOf(18), 15);
  });
}
