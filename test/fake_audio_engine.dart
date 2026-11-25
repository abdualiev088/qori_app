import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hifz_app/player/audio_engine.dart';

/// Stands in for just_audio in widget tests: plays instantly, never ends on its own.
class FakeAudioEngine implements AudioEngine {
  final _states = StreamController<PlayerState>.broadcast();
  final _events = StreamController<PlaybackEvent>.broadcast();
  final _positions = StreamController<Duration>.broadcast();

  bool playing = false;
  String? asset;
  MediaItem? item;
  ProcessingState _state = ProcessingState.idle;

  void _emit() => _states.add(PlayerState(playing, _state));

  @override
  Stream<PlayerState> get playerStateStream => _states.stream;
  @override
  Stream<PlaybackEvent> get playbackEventStream => _events.stream;
  @override
  Stream<Duration> positionStream() => _positions.stream;

  @override
  Duration? get duration => const Duration(seconds: 5);
  @override
  Duration position = Duration.zero;
  @override
  ProcessingState get processingState => _state;

  @override
  Future<void> setAsset(String path) async {
    asset = path;
    _state = ProcessingState.ready;
    _emit();
  }

  /// The last downloaded file set, if any.
  String? file;

  @override
  Future<void> setFile(String path) async {
    file = path;
    _state = ProcessingState.ready;
    _emit();
  }

  @override
  Future<void> play() async {
    playing = true;
    position = const Duration(milliseconds: 1);
    _emit();
  }

  @override
  Future<void> pause() async {
    playing = false;
    _emit();
  }

  @override
  Future<void> seek(Duration position) async => this.position = position;

  @override
  Future<void> stop() async {
    playing = false;
    _state = ProcessingState.idle;
    _emit();
  }

  @override
  void setItem(MediaItem? item) => this.item = item;

  @override
  void setRemoteControls(
      {required void Function() play, required void Function() next, required void Function() previous}) {}
}
