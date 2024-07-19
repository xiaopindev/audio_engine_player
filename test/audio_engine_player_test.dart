import 'package:flutter_test/flutter_test.dart';
import 'package:audio_engine_player/audio_engine_player.dart';
import 'package:audio_engine_player/audio_engine_player_platform_interface.dart';
import 'package:audio_engine_player/audio_engine_player_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioEnginePlayerPlatform
    with MockPlatformInterfaceMixin
    implements AudioEnginePlayerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final AudioEnginePlayerPlatform initialPlatform = AudioEnginePlayerPlatform.instance;

  test('$MethodChannelAudioEnginePlayer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelAudioEnginePlayer>());
  });

  test('getPlatformVersion', () async {
    AudioEnginePlayer audioEnginePlayerPlugin = AudioEnginePlayer();
    MockAudioEnginePlayerPlatform fakePlatform = MockAudioEnginePlayerPlatform();
    AudioEnginePlayerPlatform.instance = fakePlatform;

    expect(await audioEnginePlayerPlugin.getPlatformVersion(), '42');
  });
}
