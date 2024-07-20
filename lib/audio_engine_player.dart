import 'dart:async';
import 'audio_engine_player_platform_interface.dart';

class AudioEnginePlayer {
  Future<String?> get platformVersion async {
    return AudioEnginePlayerPlatform.instance.getPlatformVersion();
  }

  Future<int> get duration async {
    return AudioEnginePlayerPlatform.instance.getTotalDuration();
  }

  Future<double> get volume async {
    return AudioEnginePlayerPlatform.instance.getVolume();
  }

  Future<void> play(String filePath) async {
    return AudioEnginePlayerPlatform.instance.play(filePath);
  }

  Future<void> seekTo(int milliseconds) async {
    return AudioEnginePlayerPlatform.instance.seekTo(milliseconds);
  }

  Future<void> playOrPause() async {
    return AudioEnginePlayerPlatform.instance.playOrPause();
  }

  Future<void> stop() async {
    return AudioEnginePlayerPlatform.instance.stop();
  }

  Future<void> setPlaylist(List<String> urls, bool autoPlay) async {
    return AudioEnginePlayerPlatform.instance.setPlaylist(urls, autoPlay);
  }

  Future<void> appendToPlaylist(String url, bool autoPlay) async {
    return AudioEnginePlayerPlatform.instance.appendToPlaylist(url, autoPlay);
  }

  Future<void> playNext() async {
    return AudioEnginePlayerPlatform.instance.playNext();
  }

  Future<void> playPrevious() async {
    return AudioEnginePlayerPlatform.instance.playPrevious();
  }

  Future<void> setVolume(double volume) async {
    return AudioEnginePlayerPlatform.instance.setVolume(volume);
  }

  Future<void> setLoopMode(int mode) async {
    return AudioEnginePlayerPlatform.instance.setLoopMode(mode);
  }

  Future<void> setBandGain(int bandIndex, double gain) async {
    return AudioEnginePlayerPlatform.instance.setBandGain(bandIndex, gain);
  }

  Future<void> setReverb(int id, double wetDryMix) async {
    return AudioEnginePlayerPlatform.instance.setReverb(id, wetDryMix);
  }

  Future<void> resetAll() async {
    return AudioEnginePlayerPlatform.instance.resetAll();
  }

  Future<void> clearCaches() async {
    return AudioEnginePlayerPlatform.instance.clearCaches();
  }

  Stream<Map<String, dynamic>> get onPlaybackProgress {
    return AudioEnginePlayerPlatform.instance.onEventStream
        .where((event) => event['event'] == 'playbackProgress')
        .map(
          (event) => {
            'progress': event['progress'] as int? ?? 0,
            'duration': event['duration'] as int? ?? 0,
          },
        );
  }
}
