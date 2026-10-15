import 'package:audio_bench/synthetic_sf2.dart';
import 'package:audio_bench/workload.dart';
import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';

import 'model.dart';

/// Pure Dart (no Flutter, no platform plugins): the synth plus the band
/// workload, rendering interleaved stereo chunks. Runs wherever the engine
/// puts it: the UI isolate, a background isolate or a Web Worker.
class RenderCore {
  RenderCore(this.settings) {
    final sf = ByteData.sublistView(buildSyntheticSoundFont());
    synth = createSynth(sf, sampleRate: sampleRate, effects: settings.effects);
    _work = BandWorkload(
      synth,
      sampleRate: sampleRate,
      stressVoices: settings.stressVoices,
    );
  }

  static const sampleRate = 48000;
  static const chunkFrames = 256;
  static const chunkBudgetMs = chunkFrames / sampleRate * 1000;

  SpikeSettings settings;
  late final Synthesizer synth;
  late final BandWorkload _work;

  final _left = Float32List(chunkFrames);
  final _right = Float32List(chunkFrames);
  final _sw = Stopwatch();

  int framesRendered = 0;
  int renderMicros = 0;
  int peakChunkMicros = 0;
  int? _tapOffFrame;

  /// Applies the settings that can change while playing.
  void update(SpikeSettings s) {
    settings = settings.copyWith(stressVoices: s.stressVoices, band: s.band);
    _work.stressVoices = settings.stressVoices;
  }

  /// A short high note, released 200 ms later (sample-accurate).
  void tapNote() {
    synth.noteOn(channel: 4, key: 84, velocity: 127);
    _tapOffFrame = framesRendered + sampleRate ~/ 5;
  }

  /// Renders the next chunk as a new interleaved stereo buffer.
  Float32List render() {
    _sw
      ..reset()
      ..start();
    if (settings.band) {
      _work.render(_left, _right);
    } else {
      synth.render(_left, _right);
    }
    final us = _sw.elapsedMicroseconds;
    renderMicros += us;
    if (us > peakChunkMicros) peakChunkMicros = us;
    final out = Float32List(chunkFrames * 2);
    for (var i = 0; i < chunkFrames; i++) {
      out[2 * i] = _left[i];
      out[2 * i + 1] = _right[i];
    }
    framesRendered += chunkFrames;
    final off = _tapOffFrame;
    if (off != null && framesRendered >= off) {
      synth.noteOff(channel: 4, key: 84);
      _tapOffFrame = null;
    }
    return out;
  }

  /// Builds a stats snapshot from device-side counters.
  SpikeStats stats({
    required String mode,
    required int initResult,
    required int playedFrames,
    required double wallSeconds,
    required int underruns,
    required int overflows,
    required double startDelayMs,
  }) {
    final rendered = framesRendered / sampleRate;
    return SpikeStats(
      settings: settings,
      mode: mode,
      initResult: initResult,
      audioSeconds: playedFrames / sampleRate,
      wallSeconds: wallSeconds,
      loadPercent: rendered == 0 ? 0 : 100 * renderMicros / 1e6 / rendered,
      peakChunkMs: peakChunkMicros / 1000,
      chunkBudgetMs: chunkBudgetMs,
      underruns: underruns,
      overflows: overflows,
      startDelayMs: startDelayMs,
    );
  }
}
