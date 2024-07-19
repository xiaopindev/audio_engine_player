import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_engine_player_platform_interface.dart';

/// An implementation of [AudioEnginePlayerPlatform] that uses method channels.
class MethodChannelAudioEnginePlayer extends AudioEnginePlayerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('audio_engine_player');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
