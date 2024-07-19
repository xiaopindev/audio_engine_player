import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'audio_engine_player_method_channel.dart';

abstract class AudioEnginePlayerPlatform extends PlatformInterface {
  AudioEnginePlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioEnginePlayerPlatform _instance = MethodChannelAudioEnginePlayer();

  static AudioEnginePlayerPlatform get instance => _instance;

  static set instance(AudioEnginePlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion();

  Future<int> getTotalDuration();

  Future<double> getVolume();

  Future<void> play(String filePath);

  Future<void> seekTo(int milliseconds);

  Future<void> playOrPause();

  Future<void> stop();

  Future<void> setPlaylist(List<String> urls, bool autoPlay);

  Future<void> playNext();

  Future<void> playPrevious();

  Future<void> setVolume(double volume);

  Future<void> setLoopMode(int mode);

  Future<void> setBandGain(int bandIndex, double gain);

  Future<void> setReverb(int id, double wetDryMix);

  Future<void> resetAll();

  Future<void> clearCaches();

  Stream<Map<String, dynamic>> get onEventStream;
}
