import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_handler.dart';

/// The audio side of the player: one ayah file at a time, plus the lock
/// screen's media item and buttons. [PlayerController] talks only to this,
/// so tests can drive it without a real audio device.
abstract class AudioEngine {
  Stream<PlayerState> get playerStateStream;
  Stream<PlaybackEvent> get playbackEventStream;
  Stream<Duration> positionStream();

  Duration? get duration;
  Duration get position;
  ProcessingState get processingState;

  Future<void> setAsset(String path);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> stop();

  /// What the lock screen shows.
  void setItem(MediaItem? item);

  /// The lock screen's play, next and previous buttons.
  void setRemoteControls({required void Function() play, required void Function() next, required void Function() previous});
}

/// [AudioEngine] on just_audio, with audio_service for the lock screen.
class JustAudioEngine implements AudioEngine {
  JustAudioEngine(this._handler);

  final HifdthAudioHandler _handler;
  AudioPlayer get _p => _handler.player;

  @override
  Stream<PlayerState> get playerStateStream => _p.playerStateStream;
  @override
  Stream<PlaybackEvent> get playbackEventStream => _p.playbackEventStream;
  @override
  Stream<Duration> positionStream() => _p.createPositionStream(
      minPeriod: const Duration(milliseconds: 50), maxPeriod: const Duration(milliseconds: 50));

  @override
  Duration? get duration => _p.duration;
  @override
  Duration get position => _p.position;
  @override
  ProcessingState get processingState => _p.processingState;

  @override
  Future<void> setAsset(String path) => _p.setAudioSource(AudioSource.asset(path));
  @override
  Future<void> play() => _p.play();
  @override
  Future<void> pause() => _p.pause();
  @override
  Future<void> seek(Duration position) => _p.seek(position);
  @override
  Future<void> stop() => _p.stop();

  @override
  void setItem(MediaItem? item) => _handler.setItem(item);

  @override
  void setRemoteControls(
      {required void Function() play, required void Function() next, required void Function() previous}) {
    _handler
      ..onPlay = play
      ..onNext = next
      ..onPrevious = previous;
  }
}
