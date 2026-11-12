import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:qori_app/widgets/glass.dart';

void main() {
  setUp(() => HText.useGoogleFonts = false);

  Future<List<HTab>> pumpNav(WidgetTester tester) async {
    final selected = <HTab>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: LiquidGlassNav(current: HTab.home, onSelect: selected.add),
          ),
        ),
      ),
    ));
    return selected;
  }

  testWidgets('tapping a tab selects it', (tester) async {
    final selected = await pumpNav(tester);
    await tester.tap(find.text('Player'));
    expect(selected, [HTab.player]);
  });

  testWidgets('swiping from the active tab selects the tab where the finger lifts', (tester) async {
    final selected = await pumpNav(tester);
    final from = tester.getCenter(find.text('Home'));
    final to = tester.getCenter(find.text('Settings'));
    await tester.dragFrom(from, to - from);
    await tester.pumpAndSettle();
    expect(selected, [HTab.settings]);
  });

  testWidgets('holding then sliding selects the tab where the finger lifts', (tester) async {
    final selected = await pumpNav(tester);
    final gesture = await tester.startGesture(tester.getCenter(find.text('Home')));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(find.text('My Method')));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, [HTab.method]);
  });

  testWidgets('swiping back onto the active tab selects nothing', (tester) async {
    final selected = await pumpNav(tester);
    final home = tester.getCenter(find.text('Home'));
    final gesture = await tester.startGesture(home);
    await gesture.moveTo(tester.getCenter(find.text('Settings')));
    await gesture.moveTo(home);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
  });
}
