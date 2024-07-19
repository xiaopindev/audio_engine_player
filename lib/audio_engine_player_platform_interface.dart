import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'audio_engine_player_method_channel.dart';

abstract class AudioEnginePlayerPlatform extends PlatformInterface {
  /// Constructs a AudioEnginePlayerPlatform.
  AudioEnginePlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static AudioEnginePlayerPlatform _instance = MethodChannelAudioEnginePlayer();

  /// The default instance of [AudioEnginePlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelAudioEnginePlayer].
  static AudioEnginePlayerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [AudioEnginePlayerPlatform] when
  /// they register themselves.
  static set instance(AudioEnginePlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
