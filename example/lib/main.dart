import 'dart:async';

import 'package:audio_engine_player/audio_engine_player.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('音频控制面板'),
        ),
        body: const AudioControlPanel(),
      ),
    );
  }
}

class AudioControlPanel extends StatefulWidget {
  const AudioControlPanel({super.key});

  @override
  State<AudioControlPanel> createState() => _AudioControlPanelState();
}

class _AudioControlPanelState extends State<AudioControlPanel> {
  final AudioEnginePlayer _audioEnginePlayer = AudioEnginePlayer();
  StreamSubscription? _playbackProgressSubscription;
  final List<double> _frequencies = [
    32,
    64,
    125,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    16000
  ];

  final Map<double, double> _sliderValues = {
    32: 0.0,
    64: 0.0,
    125: 0.0,
    250: 0.0,
    500: 0.0,
    1000: 0.0,
    2000: 0.0,
    4000: 0.0,
    8000: 0.0,
    16000: 0.0,
  };

  int _reverbPreset = 0;
  double _volume = 0.0;
  int _currentPosition = 0;
  int _duration = 0;

  @override
  void initState() {
    super.initState();
    _playbackProgressSubscription =
        _audioEnginePlayer.onPlaybackProgress.listen((map) {
      _currentPosition = map["progress"];
      _duration = map["duration"];
      setState(() {});
    });
  }

  @override
  void dispose() {
    _playbackProgressSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: 500,
            child: ListView.builder(
              itemCount: _frequencies.length,
              itemBuilder: (context, index) {
                final frequency = _frequencies[index];
                return _buildSlider(index, frequency);
              },
            ),
          ),
          _buildVolumeSlider(),
          _buildProgressSlider(),
          Text('Progress: $_currentPosition/$_duration'),
          const SizedBox(height: 20),
          _buildControlButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSlider(int index, double frequency) {
    return Row(
      children: [
        Text(frequency.toString()),
        Expanded(
          child: Slider(
            value: _sliderValues[frequency]!,
            min: -12,
            max: 12,
            onChanged: (value) {
              setState(() {
                _sliderValues[frequency] = value;
              });
              print('EQ: index $index, value $value');
              _audioEnginePlayer.setBandGain(index, value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _onSetPlaylist,
              child: const Text('Fill playlist'),
            ),
            ElevatedButton(
              onPressed: _onNextReverb,
              child: const Text('Next Reverb'),
            ),
            ElevatedButton(
              onPressed: _onReset,
              child: const Text('Restore Deafult'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _onPrevious,
              child: const Text('Play Previous'),
            ),
            ElevatedButton(
              onPressed: _onPlayPause,
              child: const Text('Play/Pause'),
            ),
            ElevatedButton(
              onPressed: _onNext,
              child: const Text('Play Next'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _onSingleLoop,
              child: const Text('Single loop'),
            ),
            ElevatedButton(
              onPressed: _onLoop,
              child: const Text('Loop all'),
            ),
            ElevatedButton(
              onPressed: _onShuffle,
              child: const Text('Shuffle'),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildVolumeSlider() {
    return Row(
      children: [
        const Text('Volume'),
        Expanded(
          child: Slider(
            value: _volume,
            min: 0,
            max: 1,
            onChanged: (value) {
              setState(() {
                _volume = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSlider() {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _currentPosition.toDouble().clamp(0.0, _duration.toDouble()),
            min: 0,
            max: _duration.toDouble(),
            onChanged: (value) {
              setState(() {
                _currentPosition = value.toInt();
              });
            },
          ),
        ),
      ],
    );
  }

  void _onSetPlaylist() {
    final urls = [
      "http://localhost/musics/BEYOND%20-%20%E6%B5%B7%E9%98%94%E5%A4%A9%E7%A9%BA.mp3",
      "http://localhost/musics/%E9%99%88%E4%B9%90%E5%9F%BA%20-%20%E6%9C%88%E5%8D%8A%E5%B0%8F%E5%A4%9C%E6%9B%B2.mp3",
      "http://localhost/musics/%E5%A2%A8%E5%B0%94%E6%9C%AC%E7%9A%84%E7%A7%8B%E5%A4%A9.m4a",
      "http://localhost/musics/%E9%82%B5%E5%B8%85-%E6%9A%96%E4%B8%80%E6%9D%AF%E8%8C%B6.mp3",
      "http://localhost/musics/%E5%A5%A2%E9%A6%99%E5%A4%AB%E4%BA%BA.m4a",
    ];
    _audioEnginePlayer.setPlaylist(urls, true);
  }

  void _onNextReverb() {
    _reverbPreset = (_reverbPreset + 1) % 14;
    _audioEnginePlayer.setReverb(_reverbPreset, 50.0);
  }

  void _onReset() {
    _audioEnginePlayer.resetAll();
    _sliderValues.updateAll((key, value) => 0.0);
    setState(() {});
  }

  void _onPrevious() {
    _audioEnginePlayer.playPrevious();
  }

  void _onPlayPause() {
    _audioEnginePlayer.playOrPause();
  }

  void _onNext() {
    _audioEnginePlayer.playNext();
  }

  void _onLoop() {
    _audioEnginePlayer.setLoopMode(0);
  }

  void _onSingleLoop() {
    _audioEnginePlayer.setLoopMode(1);
  }

  void _onShuffle() {
    _audioEnginePlayer.setLoopMode(2);
  }
}
