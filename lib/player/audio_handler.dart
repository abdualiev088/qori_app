import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Bridges the just_audio player to the lock screen / notification.
/// Play, next and previous from the system are routed back to the app's
/// player logic through the callbacks.
class HifdthAudioHandler extends BaseAudioHandler with SeekHandler {
  HifdthAudioHandler() {
    player.playbackEventStream.listen((_) => _broadcast(), onError: (Object _, StackTrace __) {});
    player.playingStream.listen((_) => _broadcast());
  }

  final player = AudioPlayer();

  void Function()? onPlay;
  void Function()? onNext;
  void Function()? onPrevious;

  void setItem(MediaItem item) => mediaItem.add(item);

  @override
  Future<void> play() async => onPlay != null ? onPlay!() : player.play();

  @override
  Future<void> pause() => player.pause();

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<void> skipToNext() async => onNext?.call();

  @override
  Future<void> skipToPrevious() async => onPrevious?.call();

  @override
  Future<void> stop() async {
    await player.stop();
    await super.stop();
  }

  void _broadcast() {
    final playing = player.playing && player.processingState != ProcessingState.completed;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
    ));
  }
}
