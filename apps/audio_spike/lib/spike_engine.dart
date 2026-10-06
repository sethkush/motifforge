import 'dart:async';

import 'package:audio_bench/benchmark.dart';
import 'package:audio_bench/synthetic_sf2.dart';
import 'package:audio_bench/workload.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';
import 'package:flutter/foundation.dart';
import 'package:mp_audio_stream/mp_audio_stream.dart';

/// Settings for one playback run.
@immutable
class SpikeSettings {
  const SpikeSettings({
    this.lookaheadMs = 100,
    this.stressVoices = 0,
    this.effects = true,
    this.band = true,
  });

  final int lookaheadMs;
  final int stressVoices;
  final bool effects;
  final bool band;

  SpikeSettings copyWith({
    int? lookaheadMs,
    int? stressVoices,
    bool? effects,
    bool? band,
  }) => SpikeSettings(
    lookaheadMs: lookaheadMs ?? this.lookaheadMs,
    stressVoices: stressVoices ?? this.stressVoices,
    effects: effects ?? this.effects,
    band: band ?? this.band,
  );

  Map<String, Object> toJson() => {
    'lookaheadMs': lookaheadMs,
    'stressVoices': stressVoices,
    'effects': effects,
    'band': band,
  };
}

/// Snapshot of playback statistics.
@immutable
class SpikeStats {
  const SpikeStats({
    required this.settings,
    required this.initResult,
    required this.audioSeconds,
    required this.wallSeconds,
    required this.loadPercent,
    required this.peakChunkMs,
    required this.chunkBudgetMs,
    required this.underruns,
    required this.overflows,
  });

  final SpikeSettings settings;

  /// 0 when the audio device opened successfully.
  final int initResult;
  final double audioSeconds;
  final double wallSeconds;
  final double loadPercent;
  final double peakChunkMs;
  final double chunkBudgetMs;
  final int underruns;
  final int overflows;

  Map<String, Object> toJson() => {
    ...settings.toJson(),
    'initResult': initResult,
    'audioSeconds': double.parse(audioSeconds.toStringAsFixed(2)),
    'wallSeconds': double.parse(wallSeconds.toStringAsFixed(2)),
    'loadPercent': double.parse(loadPercent.toStringAsFixed(2)),
    'peakChunkMs': double.parse(peakChunkMs.toStringAsFixed(2)),
    'chunkBudgetMs': double.parse(chunkBudgetMs.toStringAsFixed(2)),
    'underruns': underruns,
    'overflows': overflows,
  };
}

/// Drives the synth and the audio device: keeps the device buffer
/// `lookaheadMs` ahead of the wall clock by rendering on a 5 ms timer.
class SpikeEngine {
  SpikeEngine({AudioStream? stream}) : _stream = stream ?? getAudioStream();

  static const sampleRate = 48000;
  static const chunkFrames = 256;

  final AudioStream _stream;
  Synthesizer? _synth;
  BandWorkload? _work;
  Timer? _pump;
  final _clock = Stopwatch();

  SpikeSettings settings = const SpikeSettings();
  int _initResult = -1;
  int _framesPushed = 0;
  int _renderMicros = 0;
  int _peakChunkMicros = 0;

  bool get running => _pump != null;

  /// Opens the device and starts playing. Returns the device init result
  /// (0 = success).
  int start(SpikeSettings s) {
    if (running) stop();
    settings = s;
    final sf = ByteData.sublistView(buildSyntheticSoundFont());
    _synth = createSynth(sf, sampleRate: sampleRate, effects: s.effects);
    _work = BandWorkload(
      _synth!,
      sampleRate: sampleRate,
      stressVoices: s.stressVoices,
    );
    _initResult = _stream.init(
      bufferMilliSec: s.lookaheadMs * 4,
      waitingBufferMilliSec: s.lookaheadMs ~/ 2,
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
    _fill();
    _pump = Timer.periodic(const Duration(milliseconds: 5), (_) => _fill());
    return _initResult;
  }

  void stop() {
    _pump?.cancel();
    _pump = null;
    _clock.stop();
    _stream.uninit();
  }

  /// Changes settings that apply live (stress voices, band on/off).
  void update(SpikeSettings s) {
    settings = settings.copyWith(stressVoices: s.stressVoices, band: s.band);
    _work?.stressVoices = settings.stressVoices;
  }

  void tapNote() {
    _synth?.noteOn(channel: 4, key: 84, velocity: 127);
    Future<void>.delayed(
      const Duration(milliseconds: 200),
      () => _synth?.noteOff(channel: 4, key: 84),
    );
  }

  void _fill() {
    final work = _work;
    if (work == null) return;
    final target =
        (_clock.elapsedMicroseconds * sampleRate / 1e6).round() +
        settings.lookaheadMs * sampleRate ~/ 1000;
    final left = Float32List(chunkFrames);
    final right = Float32List(chunkFrames);
    final interleaved = Float32List(chunkFrames * 2);
    final sw = Stopwatch();
    while (_framesPushed < target) {
      sw
        ..reset()
        ..start();
      if (settings.band) {
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
  }

  SpikeStats stats() {
    final stat = _stream.stat();
    final audioSeconds = _framesPushed / sampleRate;
    return SpikeStats(
      settings: settings,
      initResult: _initResult,
      audioSeconds: audioSeconds,
      wallSeconds: _clock.elapsedMicroseconds / 1e6,
      loadPercent: audioSeconds == 0
          ? 0
          : 100 * _renderMicros / 1e6 / audioSeconds,
      peakChunkMs: _peakChunkMicros / 1000,
      chunkBudgetMs: chunkFrames / sampleRate * 1000,
      underruns: stat.exhaust,
      overflows: stat.full,
    );
  }
}

/// Runs the CPU benchmark one scenario at a time, yielding between
/// scenarios so the UI stays responsive.
Stream<BenchResult> runCpuBenchmark({double seconds = 5}) async* {
  for (final effects in [true, false]) {
    for (final stress in [0, 16, 32, 64]) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      yield runBenchmark(
        seconds: seconds,
        stressLevels: [stress],
        effects: effects,
      ).single;
    }
  }
}

String platformDescription() =>
    '${kIsWeb ? 'web (${defaultTargetPlatform.name})' : defaultTargetPlatform.name}, '
    '${kReleaseMode
        ? 'release'
        : kProfileMode
        ? 'profile'
        : 'debug'} build';
