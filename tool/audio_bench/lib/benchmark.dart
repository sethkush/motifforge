import 'dart:typed_data';

import 'synthetic_sf2.dart';
import 'workload.dart';

final class BenchResult {
  BenchResult(
    this.label,
    this.realTimeFactor,
    this.p99ChunkMs,
    this.chunkBudgetMs,
  );

  final String label;

  /// Seconds of audio rendered per second of CPU (higher is better; must be
  /// comfortably above 1 to play in real time).
  final double realTimeFactor;

  /// 99th-percentile time to render one output chunk.
  final double p99ChunkMs;

  /// Real-time duration of one chunk.
  final double chunkBudgetMs;

  @override
  String toString() =>
      '${label.padRight(28)} ${realTimeFactor.toStringAsFixed(1).padLeft(7)}x realtime   '
      'p99 chunk ${p99ChunkMs.toStringAsFixed(2)} ms / ${chunkBudgetMs.toStringAsFixed(2)} ms budget';
}

/// Renders [seconds] of the band workload per scenario and times it.
/// [chunkFrames] is the size of each push to the audio device.
List<BenchResult> runBenchmark({
  ByteData? soundFont,
  int sampleRate = 48000,
  double seconds = 20,
  int chunkFrames = 512,
  List<int> stressLevels = const [0, 16, 32, 64],
  bool effects = true,
  void Function(BenchResult)? onResult,
}) {
  final sf = soundFont ?? ByteData.sublistView(buildSyntheticSoundFont());
  final results = <BenchResult>[];
  for (final stress in stressLevels) {
    final synth = createSynth(sf, sampleRate: sampleRate, effects: effects);
    final work = BandWorkload(
      synth,
      sampleRate: sampleRate,
      stressVoices: stress,
    );
    final left = Float32List(chunkFrames);
    final right = Float32List(chunkFrames);

    // Warm up (JIT, caches).
    for (var i = 0; i < 50; i++) {
      work.render(left, right);
    }

    final chunks = (seconds * sampleRate / chunkFrames).ceil();
    final times = <int>[];
    final total = Stopwatch()..start();
    final sw = Stopwatch();
    for (var i = 0; i < chunks; i++) {
      sw
        ..reset()
        ..start();
      work.render(left, right);
      times.add(sw.elapsedMicroseconds);
    }
    total.stop();
    times.sort();
    final result = BenchResult(
      'band + $stress stress voices${effects ? '' : ' (no fx)'}',
      chunks * chunkFrames / sampleRate / (total.elapsedMicroseconds / 1e6),
      times[(times.length * 0.99).floor()] / 1000,
      chunkFrames / sampleRate * 1000,
    );
    results.add(result);
    onResult?.call(result);
  }
  return results;
}
