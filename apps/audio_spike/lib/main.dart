import 'dart:async';

import 'package:audio_bench/synthetic_sf2.dart';
import 'package:audio_bench/workload.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter/material.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';

/// M0 audio spike. Plays the band workload through dart_melty_soundfont and
/// mp_audio_stream, and shows the numbers we need to choose the audio stack:
/// device underruns, render load, and how a tapped note feels (latency).
void main() => runApp(const SpikeApp());

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'MotifForge audio spike',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const SpikePage(),
  );
}

class SpikePage extends StatefulWidget {
  const SpikePage({super.key});

  @override
  State<SpikePage> createState() => _SpikePageState();
}

class _SpikePageState extends State<SpikePage> {
  static const sampleRate = 48000;
  static const chunkFrames = 256;

  final _stream = getAudioStream();
  Synthesizer? _synth;
  BandWorkload? _work;
  Timer? _pump;
  final _clock = Stopwatch();

  int _lookaheadMs = 100;
  int _stress = 0;
  bool _effects = true;
  bool _band = true;

  int _framesPushed = 0;
  int _renderMicros = 0;
  int _peakChunkMicros = 0;
  int _underruns = 0;
  int _overflows = 0;
  String _status = 'Stopped';

  bool get _running => _pump != null;

  void _start() {
    final sf = ByteData.sublistView(buildSyntheticSoundFont());
    _synth = createSynth(sf, sampleRate: sampleRate, effects: _effects);
    _work = BandWorkload(
      _synth!,
      sampleRate: sampleRate,
      stressVoices: _stress,
    );
    final rc = _stream.init(
      bufferMilliSec: _lookaheadMs * 4,
      waitingBufferMilliSec: _lookaheadMs ~/ 2,
      channels: 2,
      sampleRate: sampleRate,
    );
    _stream.resume(); // web: must follow a user gesture
    _stream.resetStat();
    _framesPushed = 0;
    _renderMicros = 0;
    _peakChunkMicros = 0;
    _clock
      ..reset()
      ..start();
    _fill(); // pre-fill the look-ahead before the first timer tick
    _pump = Timer.periodic(const Duration(milliseconds: 5), (_) => _fill());
    setState(() => _status = rc == 0 ? 'Playing' : 'init failed ($rc)');
  }

  void _stop() {
    _pump?.cancel();
    _pump = null;
    _clock.stop();
    _stream.uninit();
    setState(() => _status = 'Stopped');
  }

  /// Keeps the device buffer [_lookaheadMs] ahead of the wall clock.
  void _fill() {
    final work = _work;
    if (work == null) return;
    work.stressVoices = _stress;
    final target =
        (_clock.elapsedMicroseconds * sampleRate / 1e6).round() +
        _lookaheadMs * sampleRate ~/ 1000;
    final left = Float32List(chunkFrames);
    final right = Float32List(chunkFrames);
    final interleaved = Float32List(chunkFrames * 2);
    final sw = Stopwatch();
    while (_framesPushed < target) {
      sw
        ..reset()
        ..start();
      if (_band) {
        work.render(left, right);
      } else {
        _synth!.render(left, right);
      }
      final us = sw.elapsedMicroseconds;
      _renderMicros += us;
      if (us > _peakChunkMicros) _peakChunkMicros = us;
      for (var i = 0; i < chunkFrames; i++) {
        interleaved[2 * i] = left[i];
        interleaved[2 * i + 1] = right[i];
      }
      _stream.push(interleaved);
      _framesPushed += chunkFrames;
    }
    final stat = _stream.stat();
    _underruns = stat.exhaust;
    _overflows = stat.full;
    if (mounted && _framesPushed % (chunkFrames * 40) < chunkFrames) {
      setState(() {});
    }
  }

  void _tapNote() {
    _synth?.noteOn(channel: 4, key: 84, velocity: 127);
    Future<void>.delayed(
      const Duration(milliseconds: 200),
      () => _synth?.noteOff(channel: 4, key: 84),
    );
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioSeconds = _framesPushed / sampleRate;
    final load = audioSeconds == 0
        ? 0.0
        : 100 * _renderMicros / 1e6 / audioSeconds;
    final chunkBudgetUs = chunkFrames / sampleRate * 1e6;
    return Scaffold(
      appBar: AppBar(title: const Text('Audio spike')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_status, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(
                onPressed: _running ? _stop : _start,
                child: Text(_running ? 'Stop' : 'Start'),
              ),
              OutlinedButton(
                onPressed: _running ? _tapNote : null,
                child: const Text('Tap note (latency check)'),
              ),
            ],
          ),
          SwitchListTile(
            title: const Text('Band pattern'),
            subtitle: const Text('Off = silence except tapped notes'),
            value: _band,
            onChanged: (v) => setState(() => _band = v),
          ),
          SwitchListTile(
            title: const Text('Reverb + chorus (applies on restart)'),
            value: _effects,
            onChanged: _running ? null : (v) => setState(() => _effects = v),
          ),
          ListTile(
            title: Text('Extra stress voices: $_stress'),
            subtitle: Slider(
              value: _stress.toDouble(),
              max: 64,
              divisions: 8,
              onChanged: (v) => setState(() => _stress = v.round()),
            ),
          ),
          ListTile(
            title: Text('Look-ahead: $_lookaheadMs ms (applies on restart)'),
            subtitle: Slider(
              value: _lookaheadMs.toDouble(),
              min: 20,
              max: 300,
              divisions: 14,
              onChanged: _running
                  ? null
                  : (v) => setState(() => _lookaheadMs = v.round()),
            ),
          ),
          const Divider(),
          _stat('Audio rendered', '${audioSeconds.toStringAsFixed(1)} s'),
          _stat('Average render load', '${load.toStringAsFixed(1)} %'),
          _stat(
            'Peak chunk render',
            '${(_peakChunkMicros / 1000).toStringAsFixed(2)} ms '
                '(budget ${(chunkBudgetUs / 1000).toStringAsFixed(2)} ms)',
          ),
          _stat('Device underruns (buffer ran dry)', '$_underruns'),
          _stat('Buffer-full drops', '$_overflows'),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => ListTile(
    dense: true,
    title: Text(label),
    trailing: Text(value, style: const TextStyle(fontFeatures: [])),
  );
}
