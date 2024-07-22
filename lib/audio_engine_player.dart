import 'dart:async';
import 'audio_engine_player_platform_interface.dart';

enum PlayerEventType { playbackProgress, playingStatus }

class AudioEnginePlayer {
  Future<String?> get platformVersion async {
    return AudioEnginePlayerPlatform.instance.getPlatformVersion();
  }

  Future<int> get duration async {
    return AudioEnginePlayerPlatform.instance.duration();
  }

  Future<double> get volume async {
    return AudioEnginePlayerPlatform.instance.volume();
  }

  Future<bool> get isMute async {
    return AudioEnginePlayerPlatform.instance.isMute();
  }

  Future<int> get currentPlayIndex async {
    return AudioEnginePlayerPlatform.instance.currentPlayIndex();
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

  Future<void> pause() async {
    return AudioEnginePlayerPlatform.instance.pause();
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

  Future<void> setSpeed(double value) async {
    return AudioEnginePlayerPlatform.instance.setSpeed(value);
  }

  Future<void> setVolume(double value) async {
    return AudioEnginePlayerPlatform.instance.setVolume(value);
  }

  Future<void> setMute(bool value) async {
    return AudioEnginePlayerPlatform.instance.setMute(value);
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

  Stream<(String, Map<String, dynamic>)> get onPlayerEvents {
    return AudioEnginePlayerPlatform.instance.onEventStream
        .where((event) => event['event'] != null)
        .map((event) {
      try {
        final eventType = event['event'] as String;
        final eventData = Map<String, dynamic>.from(event)..remove('event');
        return (eventType, eventData);
      } catch (e) {
        return ('error', {'desc': e.toString()});
      }
    });
  }
}
