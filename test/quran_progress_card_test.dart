import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/surahs.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:qori_app/widgets/quran_progress_card.dart';

void main() {
  setUp(() => HText.useGoogleFonts = false);

  test('surah data has 114 names, 114 counts and 6236 ayahs', () {
    expect(surahNames, hasLength(114));
    expect(surahAyahCounts, hasLength(114));
    expect(surahAyahCounts.fold<int>(0, (a, b) => a + b), 6236);
  });

  Future<void> pumpCard(WidgetTester tester, {required double width, int start = 67}) async {
    tester.view.physicalSize = Size(width, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final surahs = sampleSurahProgress();
    var selected = start;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: StatefulBuilder(
            builder: (context, setState) => QuranProgressCard(
              surahs: surahs,
              selected: selected,
              onSelect: (i) => setState(() => selected = i),
            ),
          ),
        ),
      ),
    ));
  }

  Finder tile(int number) => find.bySemanticsLabel(RegExp('^Surah $number, '));

  testWidgets('shows the header, 114 tiles and the selected surah', (tester) async {
    await pumpCard(tester, width: 402);
    expect(find.text('QURAN PROGRESS'), findsOneWidget);
    expect(find.text('39/114', findRichText: true), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Surah \d+, ')), findsNWidgets(114 + 1)); // tiles + detail row
    expect(find.text('Al-Qalam'), findsOneWidget);
    expect(find.text('58%'), findsOneWidget);
  });

  testWidgets('tapping a tile selects it', (tester) async {
    await pumpCard(tester, width: 402);
    await tester.tap(tile(98).first);
    await tester.pumpAndSettle();
    expect(find.text('Al-Bayyinah'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('holding then sliding browses with a loupe', (tester) async {
    await pumpCard(tester, width: 402);
    final gesture = await tester.startGesture(tester.getCenter(tile(61).first));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Al-Saff'), findsNothing);
    expect(find.text('As-Saff'), findsNWidgets(2)); // detail row and loupe
    await gesture.moveTo(tester.getCenter(tile(64).first));
    await tester.pump();
    expect(find.text('At-Taghabun'), findsNWidgets(2));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('At-Taghabun'), findsOneWidget); // loupe gone, selection kept
  });

  testWidgets('fits at 320 px wide', (tester) async {
    await pumpCard(tester, width: 320);
    expect(tester.takeException(), isNull);
  });
}
