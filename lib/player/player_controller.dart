import 'dart:async';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/surah_meta.dart';
import '../data/surah_source.dart';
import '../data/surahs.dart';
import 'audio_engine.dart';
import 'playback_rules.dart';

/// Repeat choices; 0 means forever.
const repeatOptions = [1, 3, 5, 7, 10, 0];

/// The reciter of the bundled audio.
const reciterName = 'Alijon Qori';

/// Player state and behavior, ported from the script in the handoff's Player.dc.html,
/// for any surah. One surah is active at a time ([surah]); it stays active,
/// playing or paused, after the player screen closes, until [close].
class PlayerController extends ChangeNotifier {
  PlayerController(this._audio, this._prefs, {SurahSource? source}) : source = source ?? BundledSurahSource() {
    repeat = _prefs.getInt('$_k.repeat') ?? _prefs.getInt('$_old.repeat') ?? 3;
    autoNext = _prefs.getBool('$_k.autoNext') ?? _prefs.getBool('$_old.autoNext') ?? false;
    loopSelected = _prefs.getBool('$_k.loopSel') ?? _prefs.getBool('$_old.loopSel') ?? false;
  }

  /// Settings shared by all surahs, then per surah: `$_k.<surah>.current` and `.selected`.
  static const _k = 'hifdth.player';

  /// Where the Al-Qalam-only player kept its settings; read once, as a fallback.
  static const _old = 'hifdth.qalam';

  final AudioEngine _audio;
  final SharedPreferences _prefs;
  final SurahSource source;

  /// The active surah, or null when nothing is open or playing.
  int? surah;

  /// The active surah's ayahs; empty while they load.
  List<Ayah> ayat = const [];
  bool textLoading = false;
  Object? textError;

  int current = 1;
  late int repeat;
  late bool autoNext;
  late bool loopSelected;
  List<int> selected = [];
  bool selecting = false;
  int plays = 0;
  bool finished = false;
  bool playing = false;
  bool loading = false;

  /// Progress through the current repetition, 0–1. Separate so only the bar repaints.
  final progress = ValueNotifier<double>(0);

  /// Set by the player screen to keep the current ayah in view.
  void Function(int n, {bool center})? onScrollRequest;

  final _subs = <StreamSubscription<Object?>>[];
  String _selBefore = '';
  bool _endHandled = false;
  int _loadToken = 0;
  int _openToken = 0;

  Future<void> init() async {
    _subs
      ..add(_audio.playerStateStream.listen(_onState))
      ..add(_audio.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace _) {
        // e.g. the output fails mid-track: stop showing "playing" so Play works again.
        debugPrint('Playback error on ayah $current: $e');
        _audio.pause();
        playing = false;
        loading = false;
        notifyListeners();
      }))
      ..add(_audio.positionStream().listen((pos) {
        if (!finished && surah != null) progress.value = math.min(1, pos.inMilliseconds / 1000 / _length);
      }));
    _audio.setRemoteControls(play: toggle, next: goNext, previous: goPrevious);
  }

  // ---------- the active surah ----------

  String get name => surah == null ? '' : surahNames[surah! - 1];
  String get arabicName => surah == null ? '' : surahArabicNames[surah! - 1];
  int get ayahCount => surah == null ? 0 : surahAyahCounts[surah! - 1];

  /// Surahs 1 and 9 have no Basmala row.
  bool get hasBasmala => surah != 1 && surah != 9;
  int get _first => hasBasmala ? 0 : 1;

  bool get hasAudio => surah != null && source.hasAudio(surah!);

  /// Opens [s] at [ayah] (or where it was left). The same surah keeps playing;
  /// a different one stops the current audio first.
  Future<void> openSurah(int s, {int? ayah}) async {
    if (s == surah) {
      if (ayah != null && ayah != current && ayat.isNotEmpty) await load(ayah, play: playing);
      return;
    }
    final token = ++_openToken;
    ++_loadToken;
    await _audio.stop();
    surah = s;
    selected = [
      for (final n in (_prefs.getStringList('$_k.$s.selected') ?? (s == 68 ? _prefs.getStringList('$_old.selected') : null) ?? const []))
        if (int.tryParse(n) case final v? when v >= 1 && v <= surahAyahCounts[s - 1]) v,
    ];
    selecting = false;
    playing = false;
    loading = false;
    plays = 0;
    finished = false;
    progress.value = 0;
    ayat = const [];
    textError = null;
    textLoading = true;
    current = (ayah ?? _prefs.getInt('$_k.$s.current') ?? (s == 68 ? _prefs.getInt('$_old.current') : null) ?? 1)
        .clamp(_first, surahAyahCounts[s - 1]);
    notifyListeners();
    await _loadText(token, start: current);
  }

  /// Tries the text again after it failed to load.
  Future<void> retryText() async {
    if (surah == null) return;
    textError = null;
    textLoading = true;
    notifyListeners();
    await _loadText(++_openToken, start: current);
  }

  Future<void> _loadText(int token, {required int start}) async {
    try {
      final loaded = await source.ayat(surah!);
      if (token != _openToken) return;
      ayat = loaded;
      textLoading = false;
      notifyListeners();
      await load(start, play: false, scroll: false);
      onScrollRequest?.call(current, center: true);
    } catch (e) {
      if (token != _openToken) return;
      debugPrint('Could not load surah $surah: $e');
      textLoading = false;
      textError = e;
      notifyListeners();
    }
  }

  /// Stops playback and clears the active surah.
  Future<void> close() async {
    ++_openToken;
    ++_loadToken;
    surah = null;
    ayat = const [];
    playing = false;
    loading = false;
    selecting = false;
    progress.value = 0;
    notifyListeners();
    await _audio.stop();
    _audio.setItem(null);
  }

  // ---------- derived state ----------

  bool get hasQueue => selected.isNotEmpty;
  List<int> get queue => sortedQueue(selected);

  int? _next(int n, {required bool manual}) => nextAfter(n,
      last: ayahCount, manual: manual, autoNext: autoNext, loopSelected: loopSelected, selected: selected);
  int? _prev(int n) => prevBefore(n, first: _first, loopSelected: loopSelected, selected: selected);

  bool get canGoPrevious => hasAudio && _prev(current) != null;
  bool get canGoNext => hasAudio && _next(current, manual: true) != null;

  /// "Then next ayah" without a selection, "Loop selected" with one.
  bool get autoOn => hasQueue ? loopSelected : autoNext;
  String get autoLabel => hasQueue ? 'Loop selected' : 'Then next ayah';

  /// Position of the current ayah in the selection, e.g. "2 of 5".
  String get queuePosition {
    final i = queue.indexOf(current);
    return i >= 0 ? '${i + 1} of ${queue.length}' : '';
  }

  /// Repeat counter as (before, bold, after).
  (String, String, String) get counter {
    if (!hasAudio) return ('', '', '');
    if (finished) return (hasQueue ? 'Finished · ${selected.length} ayat' : 'Finished', '', '');
    if (repeat == 1) return (playing ? 'Playing once' : 'Plays once', '', '');
    if (repeat == 0) return ('Repeating ', '${plays + 1}', ' · ∞');
    return ('Repeat ', '${math.min(plays + 1, repeat)}', ' of $repeat');
  }

  /// "Ayah 30 of 52 · repeat 2 of 3", for the mini-player.
  String get summary {
    final where = current == 0 ? 'Basmala' : 'Ayah $current of $ayahCount';
    if (!hasAudio) return where;
    final (pre, strong, post) = counter;
    return '$where · ${'$pre$strong$post'.toLowerCase()}';
  }

  String get selectionHint => selected.isNotEmpty
      ? '${selected.length} selected · each plays ${repeat == 0 ? 'on repeat' : '$repeat×'}, then the next selected one'
      : 'Tap the ayat you want to repeat';

  /// One fill value (0–1) per repetition segment.
  List<double> segmentFills(double p) {
    final n = repeat == 0 ? 1 : repeat;
    final cur = repeat == 0 ? 0 : math.min(plays, n - 1);
    return [for (var k = 0; k < n; k++) finished || k < cur ? 1 : (k == cur ? p : 0)];
  }

  /// Progress through all of the current ayah's repeats, 0–1 (the mini-player's line).
  double overallProgress(double p) {
    if (finished) return 1;
    final n = repeat == 0 ? 1 : repeat;
    final cur = repeat == 0 ? 0 : math.min(plays, n - 1);
    return ((cur + p) / n).clamp(0.0, 1.0);
  }

  double get _length {
    final d = _audio.duration;
    return d != null && d > Duration.zero ? d.inMilliseconds / 1000 : source.ayahSeconds(surah ?? 0, current);
  }

  // ---------- playback ----------

  void _onState(PlayerState st) {
    final completed = st.processingState == ProcessingState.completed;
    final nowPlaying = st.playing && !completed && surah != null;
    final nowLoading = nowPlaying &&
        (st.processingState == ProcessingState.loading || st.processingState == ProcessingState.buffering);
    if (nowPlaying != playing || nowLoading != loading) {
      playing = nowPlaying;
      loading = nowLoading;
      notifyListeners();
    }
    if (completed && !_endHandled) {
      _endHandled = true;
      if (surah != null) _onEnded();
    } else if (!completed) {
      _endHandled = false;
    }
  }

  Future<void> load(int n, {bool play = true, bool scroll = true}) async {
    final s = surah;
    if (s == null) return;
    current = n;
    plays = 0;
    finished = false;
    progress.value = 0;
    _prefs.setInt('$_k.$s.current', n);
    notifyListeners();
    if (scroll) onScrollRequest?.call(n);
    final path = source.audioAsset(s, n);
    if (path == null) return; // no audio for this surah yet
    _audio.setItem(MediaItem(
      id: '${s}_$n',
      title: n == 0 ? 'Basmala' : 'Ayah $n',
      artist: reciterName,
      album: 'Surah ${surahNames[s - 1]}',
      duration: Duration(milliseconds: (source.ayahSeconds(s, n) * 1000).round()),
    ));
    final token = ++_loadToken;
    try {
      await _audio.setAsset(path);
    } on PlayerInterruptedException {
      return;
    } catch (e) {
      debugPrint('Could not load ayah $n: $e');
      return;
    }
    if (token != _loadToken) return;
    if (play) _audio.play();
  }

  void toggle() {
    if (!hasAudio) return;
    if (playing) {
      _audio.pause();
      return;
    }
    final ended = _audio.processingState == ProcessingState.completed;
    final fresh = ended || _audio.position == Duration.zero || finished;
    if (fresh && hasQueue) {
      final q = queue;
      if (finished) {
        load(q.first);
        return;
      }
      if (!selected.contains(current)) {
        load(q.firstWhere((x) => x > current, orElse: () => q.first));
        return;
      }
    }
    if (finished || ended) {
      plays = 0;
      finished = false;
      progress.value = 0;
      notifyListeners();
      _audio.seek(Duration.zero);
    }
    _audio.play();
  }

  void _onEnded() {
    final p = plays + 1;
    if (repeat == 0 || p < repeat) {
      plays = p;
      progress.value = 0;
      notifyListeners();
      _audio.seek(Duration.zero);
      _audio.play();
      return;
    }
    final n = _next(current, manual: false);
    if (n != null) {
      load(n);
      return;
    }
    finished = true;
    plays = math.max(0, repeat - 1);
    progress.value = 1;
    _audio.pause();
    notifyListeners();
  }

  void goNext() {
    final n = _next(current, manual: true);
    if (n != null && hasAudio) load(n);
  }

  void goPrevious() {
    final n = _prev(current);
    if (n != null && hasAudio) load(n);
  }

  /// Seeks within the current repetition; [fraction] is 0–1.
  void seekTo(double fraction) {
    if (finished || !hasAudio) return;
    final f = fraction.clamp(0.0, 1.0);
    _audio.seek(Duration(milliseconds: (f * _length * 1000).round()));
    progress.value = f;
  }

  void seekBy(Duration delta) {
    if (!hasAudio) return;
    final len = Duration(milliseconds: (_length * 1000).round());
    final t = _audio.position + delta;
    _audio.seek(t < Duration.zero ? Duration.zero : (t > len ? len : t));
  }

  // ---------- list & selection ----------

  void tapAyah(int n) {
    if (selecting && n != 0) {
      _setSelected(selected.contains(n) ? (selected.where((x) => x != n).toList()) : [...selected, n]);
      return;
    }
    if (n == current && !finished) {
      toggle();
    } else {
      load(n, play: hasAudio, scroll: false);
    }
  }

  void setSelecting(bool on) {
    if (on) {
      _selBefore = queue.join(',');
      selecting = true;
      notifyListeners();
      return;
    }
    selecting = false;
    notifyListeners();
    final q = queue;
    if (q.isNotEmpty && q.join(',') != _selBefore) load(q.first, play: hasAudio);
  }

  void selectAll() => _setSelected([for (final a in ayat) a.n]);
  void clearSelection() => _setSelected([]);

  /// "Cancel" outside select mode drops the selection.
  void cancelSelection() {
    finished = false;
    _setSelected([]);
  }

  void _setSelected(List<int> list) {
    selected = list;
    if (surah != null) _prefs.setStringList('$_k.$surah.selected', [for (final n in sortedQueue(list)) '$n']);
    notifyListeners();
  }

  void setRepeat(int r) {
    _prefs.setInt('$_k.repeat', r);
    plays = r != 0 && plays >= r ? r - 1 : plays;
    repeat = r;
    notifyListeners();
  }

  void toggleAuto() {
    if (hasQueue) {
      loopSelected = !loopSelected;
      _prefs.setBool('$_k.loopSel', loopSelected);
    } else {
      autoNext = !autoNext;
      _prefs.setBool('$_k.autoNext', autoNext);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    progress.dispose();
    super.dispose();
  }
}
