import 'dart:convert';

import 'package:audio_spike/spike_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Headless on-device audio check. Plays each scenario through the real
/// audio device for [seconds], then runs the CPU benchmark, and reports
/// everything as JSON (printed with a `SPIKE_RESULT` prefix and handed to
/// the driver, which writes build/integration_response_data.json).
///
/// Run on a device or emulator in profile mode (AOT, realistic speed):
///   flutter drive --profile -d DEVICE_ID \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/spike_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const seconds = int.fromEnvironment('SPIKE_SECONDS', defaultValue: 20);

  testWidgets('audio spike', (tester) async {
    final scenarios = [
      const SpikeSettings(),
      const SpikeSettings(stressVoices: 64),
      const SpikeSettings(lookaheadMs: 50),
      const SpikeSettings(lookaheadMs: 30),
      const SpikeSettings(lookaheadMs: 20),
    ];
    final playback = <Map<String, Object>>[];
    final engine = SpikeEngine();
    for (final s in scenarios) {
      await tester.runAsync(() async {
        engine.start(s);
        await Future<void>.delayed(const Duration(seconds: seconds));
        final stats = engine.stats();
        engine.stop();
        playback.add(stats.toJson());
        // ignore: avoid_print
        print('SPIKE_RESULT playback ${jsonEncode(stats.toJson())}');
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
    }

    final bench = <Map<String, Object>>[];
    await tester.runAsync(() async {
      await for (final r in runCpuBenchmark()) {
        final row = {
          'scenario': r.label,
          'realTimeFactor': double.parse(r.realTimeFactor.toStringAsFixed(1)),
          'p99ChunkMs': double.parse(r.p99ChunkMs.toStringAsFixed(2)),
        };
        bench.add(row);
        // ignore: avoid_print
        print('SPIKE_RESULT bench ${jsonEncode(row)}');
      }
    });

    final report = {
      'platform': platformDescription(),
      'secondsPerScenario': seconds,
      'playback': playback,
      'benchmark': bench,
    };
    binding.reportData = report;
    // ignore: avoid_print
    print('SPIKE_RESULT report ${jsonEncode(report)}');
    for (final p in playback) {
      expect(p['initResult'], 0, reason: 'audio device failed to open: $p');
    }
  }, timeout: const Timeout(Duration(minutes: 10)));
}
