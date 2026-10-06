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
    required this.startDelayMs,
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

  /// How long the device took to start consuming audio, estimated as wall
  /// time minus audio accepted (less the buffer, which is full at the end).
  /// Only meaningful on native (backpressure) builds.
  final double startDelayMs;

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
    'startDelayMs': startDelayMs.round(),
  };
}

/// Drives the synth and the audio device on a 5 ms timer.
///
/// Native: **backpressure**. The device ring buffer is sized to the target
/// latency (`lookaheadMs`) and each tick pushes until the device reports the
/// buffer full; a rejected chunk is kept and retried next tick. Latency is
/// therefore bounded by the buffer size, whatever the device start-up time.
///
/// Web: the plugin's push is fire-and-forget (no "full" signal), so we pace
/// by the wall clock instead and keep `lookaheadMs` of audio queued.
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
  Float32List? _pending;

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
      bufferMilliSec: kIsWeb ? s.lookaheadMs * 4 : s.lookaheadMs,
      waitingBufferMilliSec: kIsWeb ? s.lookaheadMs ~/ 2 : s.lookaheadMs ~/ 4,
      channels: 2,
      sampleRate: sampleRate,
    );
    _stream.resume(); // web: must follow a user gesture
    _stream.resetStat();
    _framesPushed = 0;
    _pending = null;
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
    if (kIsWeb) {
      final target =
          (_clock.elapsedMicroseconds * sampleRate / 1e6).round() +
          settings.lookaheadMs * sampleRate ~/ 1000;
      while (_framesPushed < target) {
        _stream.push(_render(work));
        _framesPushed += chunkFrames;
      }
      return;
    }
    // Native: push until the device buffer is full (bounded iterations so a
    // misbehaving device can't spin us forever).
    for (var i = 0; i < 64; i++) {
      final chunk = _pending ?? _render(work);
      if (_stream.push(chunk) != 0) {
        _pending = chunk; // full: retry this exact chunk next tick
        return;
      }
      _pending = null;
      _framesPushed += chunkFrames;
    }
  }

  final _left = Float32List(chunkFrames);
  final _right = Float32List(chunkFrames);

  /// Renders the next chunk as interleaved stereo.
  Float32List _render(BandWorkload work) {
    final sw = Stopwatch()..start();
    if (settings.band) {
      work.render(_left, _right);
    } else {
      _synth!.render(_left, _right);
    }
    final us = sw.elapsedMicroseconds;
    _renderMicros += us;
    if (us > _peakChunkMicros) _peakChunkMicros = us;
    final interleaved = Float32List(chunkFrames * 2);
    for (var i = 0; i < chunkFrames; i++) {
      interleaved[2 * i] = _left[i];
      interleaved[2 * i + 1] = _right[i];
    }
    return interleaved;
  }

  SpikeStats stats() {
    final stat = _stream.stat();
    final audioSeconds = _framesPushed / sampleRate;
    return SpikeStats(
      settings: settings,
      initResult: _initResult,
      audioSeconds: audioSeconds,
      wallSeconds: _clock.elapsedMicroseconds / 1e6,
      // Render time over audio accepted by the device (a rejected chunk is
      // rendered once and counted when it is accepted).
      loadPercent: audioSeconds == 0
          ? 0
          : 100 * _renderMicros / 1e6 / audioSeconds,
      peakChunkMs: _peakChunkMicros / 1000,
      chunkBudgetMs: chunkFrames / sampleRate * 1000,
      underruns: stat.exhaust,
      overflows: stat.full,
      startDelayMs: kIsWeb
          ? 0
          : (_clock.elapsedMicroseconds / 1000 -
                    (audioSeconds * 1000 - settings.lookaheadMs))
                .clamp(0, double.infinity)
                .toDouble(),
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
