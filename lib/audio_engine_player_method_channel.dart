import 'package:flutter/services.dart';
import 'audio_engine_player_platform_interface.dart';

class MethodChannelAudioEnginePlayer extends AudioEnginePlayerPlatform {
  static const MethodChannel _channel = MethodChannel('audio_engine_player');
  static const EventChannel _eventChannel =
      EventChannel('audio_engine_player_events');

  Stream<Map<String, dynamic>>? _eventStream;

  @override
  Future<String?> getPlatformVersion() async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  @override
  Future<void> play(String filePath) async {
    await _channel.invokeMethod('play', {'filePath': filePath});
  }

  @override
  Future<void> seekTo(int milliseconds) async {
    await _channel.invokeMethod('seekTo', {'milliseconds': milliseconds});
  }

  @override
  Future<void> playOrPause() async {
    await _channel.invokeMethod('playOrPause');
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }

  @override
  Future<void> setPlaylist(List<String> urls, bool autoPlay) async {
    await _channel
        .invokeMethod('setPlaylist', {'urls': urls, 'autoPlay': autoPlay});
  }

  @override
  Future<void> playNext() async {
    await _channel.invokeMethod('playNext');
  }

  @override
  Future<void> playPrevious() async {
    await _channel.invokeMethod('playPrevious');
  }

  @override
  Future<void> setVolume(double volume) async {
    await _channel.invokeMethod('setVolume', {'volume': volume});
  }

  @override
  Future<void> setLoopMode(String mode) async {
    await _channel.invokeMethod('setLoopMode', {'mode': mode});
  }

  @override
  Future<void> setBandGain(int bandIndex, double gain) async {
    await _channel
        .invokeMethod('setBandGain', {'bandIndex': bandIndex, 'gain': gain});
  }

  @override
  Future<void> setReverb(int id, double wetDryMix) async {
    await _channel
        .invokeMethod('setReverb', {'id': id, 'wetDryMix': wetDryMix});
  }

  @override
  Future<void> resetAll() async {
    await _channel.invokeMethod('resetAll');
  }

  @override
  Future<void> clearCaches() async {
    await _channel.invokeMethod('clearCaches');
  }

  @override
  Stream<Map<String, dynamic>> get onEventStream {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event));
    return _eventStream!;
  }
}
