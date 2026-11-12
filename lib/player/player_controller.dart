import 'dart:async';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/al_qalam.dart';
import 'audio_handler.dart';
import 'playback_rules.dart';

/// Repeat choices; 0 means forever.
const repeatOptions = [1, 3, 5, 7, 10, 0];

/// Player state and behavior, ported from the script in the handoff's Player.dc.html.
class PlayerController extends ChangeNotifier {
  PlayerController(this._audio, this._prefs) {
    current = (_prefs.getInt('$_k.current') ?? 1).clamp(0, lastAyah);
    repeat = _prefs.getInt('$_k.repeat') ?? 3;
    autoNext = _prefs.getBool('$_k.autoNext') ?? false;
    loopSelected = _prefs.getBool('$_k.loopSel') ?? false;
    selected = (_prefs.getStringList('$_k.selected') ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .where((n) => n >= 1 && n <= lastAyah)
        .toList();
  }

  static const _k = 'hifdth.qalam';

  final HifdthAudioHandler _audio;
  final SharedPreferences _prefs;
  AudioPlayer get _p => _audio.player;

  late int current;
  late int repeat;
  late bool autoNext;
  late bool loopSelected;
  late List<int> selected;
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

  Future<void> init() async {
    _subs
      ..add(_p.playerStateStream.listen(_onState))
      ..add(_p.playbackEventStream.listen((_) {}, onError: (Object e, StackTrace _) {
        // e.g. the output fails mid-track: stop showing "playing" so Play works again.
        debugPrint('Playback error on ayah $current: $e');
        _p.pause();
        playing = false;
        loading = false;
        notifyListeners();
      }))
      ..add(_p
          .createPositionStream(minPeriod: const Duration(milliseconds: 50), maxPeriod: const Duration(milliseconds: 50))
          .listen((pos) {
        if (!finished) progress.value = math.min(1, pos.inMilliseconds / 1000 / _length);
      }));
    _audio
      ..onPlay = toggle
      ..onNext = goNext
      ..onPrevious = goPrevious;
    await load(current, play: false, scroll: false);
  }

  // ---------- derived state ----------

  bool get hasQueue => selected.isNotEmpty;
  List<int> get queue => sortedQueue(selected);

  int? _next(int n, {required bool manual}) =>
      nextAfter(n, manual: manual, autoNext: autoNext, loopSelected: loopSelected, selected: selected);
  int? _prev(int n) => prevBefore(n, loopSelected: loopSelected, selected: selected);

  bool get canGoPrevious => _prev(current) != null;
  bool get canGoNext => _next(current, manual: true) != null;

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
    if (finished) return (hasQueue ? 'Finished · ${selected.length} ayat' : 'Finished', '', '');
    if (repeat == 1) return (playing ? 'Playing once' : 'Plays once', '', '');
    if (repeat == 0) return ('Repeating ', '${plays + 1}', ' · ∞');
    return ('Repeat ', '${math.min(plays + 1, repeat)}', ' of $repeat');
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

  double get _length {
    final d = _p.duration;
    return d != null && d > Duration.zero ? d.inMilliseconds / 1000 : ayahDurations[current];
  }

  // ---------- playback ----------

  void _onState(PlayerState st) {
    final completed = st.processingState == ProcessingState.completed;
    final nowPlaying = st.playing && !completed;
    final nowLoading = nowPlaying &&
        (st.processingState == ProcessingState.loading || st.processingState == ProcessingState.buffering);
    if (nowPlaying != playing || nowLoading != loading) {
      playing = nowPlaying;
      loading = nowLoading;
      notifyListeners();
    }
    if (completed && !_endHandled) {
      _endHandled = true;
      _onEnded();
    } else if (!completed) {
      _endHandled = false;
    }
  }

  Future<void> load(int n, {bool play = true, bool scroll = true}) async {
    current = n;
    plays = 0;
    finished = false;
    progress.value = 0;
    _prefs.setInt('$_k.current', n);
    notifyListeners();
    if (scroll) onScrollRequest?.call(n);
    _audio.setItem(MediaItem(
      id: '068_$n',
      title: n == 0 ? 'Basmala' : 'Ayah $n',
      artist: 'Alijon Qori',
      album: 'Surah Al-Qalam',
      duration: Duration(milliseconds: (ayahDurations[n] * 1000).round()),
    ));
    final token = ++_loadToken;
    try {
      await _p.setAudioSource(AudioSource.asset('assets/audio/068_${n.toString().padLeft(3, '0')}.mp3'));
    } on PlayerInterruptedException {
      return;
    } catch (e) {
      debugPrint('Could not load ayah $n: $e');
      return;
    }
    if (token != _loadToken) return;
    if (play) _p.play();
  }

  void toggle() {
    if (playing) {
      _p.pause();
      return;
    }
    final ended = _p.processingState == ProcessingState.completed;
    final fresh = ended || _p.position == Duration.zero || finished;
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
      _p.seek(Duration.zero);
    }
    _p.play();
  }

  void _onEnded() {
    final p = plays + 1;
    if (repeat == 0 || p < repeat) {
      plays = p;
      progress.value = 0;
      notifyListeners();
      _p.seek(Duration.zero);
      _p.play();
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
    _p.pause();
    notifyListeners();
  }

  void goNext() {
    final n = _next(current, manual: true);
    if (n != null) load(n);
  }

  void goPrevious() {
    final n = _prev(current);
    if (n != null) load(n);
  }

  /// Seeks within the current repetition; [fraction] is 0–1.
  void seekTo(double fraction) {
    if (finished) return;
    final f = fraction.clamp(0.0, 1.0);
    _p.seek(Duration(milliseconds: (f * _length * 1000).round()));
    progress.value = f;
  }

  void seekBy(Duration delta) {
    final len = Duration(milliseconds: (_length * 1000).round());
    final t = _p.position + delta;
    _p.seek(t < Duration.zero ? Duration.zero : (t > len ? len : t));
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
      load(n, scroll: false);
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
    if (q.isNotEmpty && q.join(',') != _selBefore) load(q.first);
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
    _prefs.setStringList('$_k.selected', [for (final n in sortedQueue(list)) '$n']);
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
