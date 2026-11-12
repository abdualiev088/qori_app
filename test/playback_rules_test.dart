import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/player/playback_rules.dart';

void main() {
  group('nextAfter', () {
    int? next(int n, {bool manual = false, bool auto = false, bool loop = false, List<int> sel = const []}) =>
        nextAfter(n, manual: manual, autoNext: auto, loopSelected: loop, selected: sel);

    test('without a selection, stops unless "Then next ayah" is on', () {
      expect(next(5), isNull);
      expect(next(5, auto: true), 6);
      expect(next(52, auto: true), isNull);
    });

    test('the Next button always steps when there is no selection', () {
      expect(next(0, manual: true), 1);
      expect(next(52, manual: true), isNull);
    });

    test('with a selection, goes to the next selected ayah in order', () {
      expect(next(3, sel: [10, 2, 7]), 7);
      expect(next(1, sel: [10, 2, 7]), 2);
    });

    test('after the last selected ayah, loops only when "Loop selected" is on', () {
      expect(next(10, sel: [10, 2, 7]), isNull);
      expect(next(10, sel: [10, 2, 7], loop: true), 2);
    });
  });

  group('prevBefore', () {
    test('without a selection, steps back down to the Basmala', () {
      expect(prevBefore(1, loopSelected: false, selected: const []), 0);
      expect(prevBefore(0, loopSelected: false, selected: const []), isNull);
    });

    test('with a selection, mirrors nextAfter', () {
      expect(prevBefore(7, loopSelected: false, selected: const [10, 2, 7]), 2);
      expect(prevBefore(2, loopSelected: false, selected: const [10, 2, 7]), isNull);
      expect(prevBefore(2, loopSelected: true, selected: const [10, 2, 7]), 10);
    });
  });
}
