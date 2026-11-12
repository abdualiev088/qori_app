/// Which ayah plays next or previous. Ported from `nextAfter` / `prevBefore`
/// in the handoff's Player.dc.html. Ayah 0 is the Basmala.
library;

const lastAyah = 52;

List<int> sortedQueue(Iterable<int> selected) => [...selected]..sort();

/// The ayah after [n], or null to stop.
///
/// Without a selection, steps to the next ayah when [manual] (the Next button)
/// or [autoNext] is on. With one, goes to the next selected ayah and wraps to
/// the first only when [loopSelected] is on.
int? nextAfter(
  int n, {
  required bool manual,
  required bool autoNext,
  required bool loopSelected,
  required List<int> selected,
}) {
  if (selected.isEmpty) return (manual || autoNext) && n < lastAyah ? n + 1 : null;
  final q = sortedQueue(selected);
  for (final x in q) {
    if (x > n) return x;
  }
  return loopSelected ? q.first : null;
}

/// The ayah before [n], or null when there is none.
int? prevBefore(int n, {required bool loopSelected, required List<int> selected}) {
  if (selected.isEmpty) return n > 0 ? n - 1 : null;
  final q = sortedQueue(selected);
  for (final x in q.reversed) {
    if (x < n) return x;
  }
  return loopSelected ? q.last : null;
}
