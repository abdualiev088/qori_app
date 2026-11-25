import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:qori_app/widgets/hifdth_card.dart';
import 'package:qori_app/widgets/hifdth_mood.dart';
import 'package:qori_app/widgets/ribbed_glass.dart';
import 'l10n_en.dart';

void main() {
  setUp(() => HText.useGoogleFonts = false);

  test('moodFor follows how many sessions are behind', () {
    expect(moodFor(sessionsBehind: 0), HifdthMood.happy);
    expect(moodFor(sessionsBehind: 1), HifdthMood.worried);
    expect(moodFor(sessionsBehind: 3), HifdthMood.sad);
  });

  test('lerp returns the end styles at 0 and 1', () {
    final a = MoodStyle.lerp(MoodStyle.happy, MoodStyle.sad, 0);
    final b = MoodStyle.lerp(MoodStyle.happy, MoodStyle.sad, 1);
    expect(a.accent, MoodStyle.happy.accent);
    expect(a.eyeScaleY, 1);
    expect(b.accent, MoodStyle.sad.accent);
    expect(b.eyeOffsetY, 14);
    expect(b.status(en), MoodStyle.sad.status(en));
  });

  Widget card(HifdthMood mood) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: HifdthCard(mood: mood))),
      );

  testWidgets('changing the mood morphs to the new status', (tester) async {
    await tester.pumpWidget(card(HifdthMood.happy));
    expect(find.text(MoodStyle.happy.status(en)), findsOneWidget);

    await tester.pumpWidget(card(HifdthMood.worried));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(MoodStyle.worried.status(en)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long-pressing Hifdth cycles the moods in debug builds', (tester) async {
    await tester.pumpWidget(card(HifdthMood.happy));
    final hifdth = find.bySemanticsLabel('Hifdth assistant');
    for (final next in [MoodStyle.worried, MoodStyle.sad, MoodStyle.happy]) {
      await tester.longPress(hifdth);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text(next.status(en)), findsOneWidget);
    }
  });

  RibbedShimmerPainter shimmer(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((p) => p.painter)
      .whereType<RibbedShimmerPainter>()
      .single;

  testWidgets('light sweeps across the ribs behind Hifdth', (tester) async {
    await tester.pumpWidget(card(HifdthMood.happy));
    final before = shimmer(tester).phase.value;
    await tester.pump(const Duration(milliseconds: 800));
    expect(shimmer(tester).phase.value, isNot(before));
  });

  testWidgets('the ribs hold still with Reduce Motion on', (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: card(HifdthMood.happy),
    ));
    final before = shimmer(tester).phase.value;
    await tester.pump(const Duration(seconds: 2));
    expect(shimmer(tester).phase.value, before);
  });
}
