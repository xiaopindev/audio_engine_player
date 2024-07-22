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
  Future<int> duration() async {
    final int duration = await _channel.invokeMethod('duration') ?? 0;
    return duration;
  }

  @override
  Future<double> volume() async {
    final double volume = await _channel.invokeMethod('isMute') ?? 1;
    return volume;
  }

  @override
  Future<bool> isMute() async {
    final bool isMute = await _channel.invokeMethod('isMute') ?? false;
    return isMute;
  }

  @override
  Future<int> currentPlayIndex() async {
    final int currentPlayIndex =
        await _channel.invokeMethod('currentPlayIndex') ?? 0;
    return currentPlayIndex;
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
  Future<void> pause() async {
    await _channel.invokeMethod('pause');
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
  Future<void> appendToPlaylist(String url, bool autoPlay) async {
    await _channel
        .invokeMethod('appendToPlaylist', {'url': url, 'autoPlay': autoPlay});
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
  Future<void> setSpeed(double value) async {
    await _channel.invokeMethod('setSpeed', {'speed': value});
  }

  @override
  Future<void> setVolume(double value) async {
    await _channel.invokeMethod('setVolume', {'volume': value});
  }

  @override
  Future<void> setMute(bool value) async {
    await _channel.invokeMethod('setMute', {'isMute': value});
  }

  @override
  Future<void> setLoopMode(int mode) async {
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
