
import 'audio_engine_player_platform_interface.dart';

class AudioEnginePlayer {
  Future<String?> getPlatformVersion() {
    return AudioEnginePlayerPlatform.instance.getPlatformVersion();
  }
}
