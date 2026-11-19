/// Which ayah plays next or previous. Ported from `nextAfter` / `prevBefore`
/// in the handoff's Player.dc.html. Ayah 0 is the Basmala.
library;

List<int> sortedQueue(Iterable<int> selected) => [...selected]..sort();

/// The ayah after [n], or null to stop. [last] is the surah's last ayah.
///
/// Without a selection, steps to the next ayah when [manual] (the Next button)
/// or [autoNext] is on. With one, goes to the next selected ayah and wraps to
/// the first only when [loopSelected] is on.
int? nextAfter(
  int n, {
  required int last,
  required bool manual,
  required bool autoNext,
  required bool loopSelected,
  required List<int> selected,
}) {
  if (selected.isEmpty) return (manual || autoNext) && n < last ? n + 1 : null;
  final q = sortedQueue(selected);
  for (final x in q) {
    if (x > n) return x;
  }
  return loopSelected ? q.first : null;
}

/// The ayah before [n], or null when there is none.
/// [first] is 0 when the surah has a Basmala row, 1 when it doesn't (1 and 9).
int? prevBefore(int n, {int first = 0, required bool loopSelected, required List<int> selected}) {
  if (selected.isEmpty) return n > first ? n - 1 : null;
  final q = sortedQueue(selected);
  for (final x in q.reversed) {
    if (x < n) return x;
  }
  return loopSelected ? q.last : null;
}
