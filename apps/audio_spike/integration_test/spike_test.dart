import 'dart:async';
import 'dart:convert';

import 'package:audio_spike/spike_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

/// Headless on-device audio measurements. Plays each scenario through the
/// real audio device for [seconds], then runs the CPU benchmark, and reports
/// JSON (printed with a `SPIKE_RESULT` prefix and handed to the driver, which
/// writes build/integration_response_data.json).
///
/// Scenarios compare rendering on the UI thread with rendering in the
/// background (isolate / Web Worker), with and without a busy UI thread
/// (`jankMs` of busy-work every 400 ms), then sweep the background engine's
/// look-ahead down to find the floor.
///
/// Run on a device or emulator in profile mode (AOT, realistic speed):
///   flutter drive --profile -d DEVICE_ID \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/spike_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const seconds = int.fromEnvironment('SPIKE_SECONDS', defaultValue: 20);

  testWidgets('audio spike', (tester) async {
    const scenarios = <(SpikeSettings, int)>[
      (SpikeSettings(background: false), 0),
      (SpikeSettings(background: false), 150),
      (SpikeSettings(), 0),
      (SpikeSettings(), 150),
      (SpikeSettings(stressVoices: 64), 0),
      (SpikeSettings(lookaheadMs: 50), 0),
      (SpikeSettings(lookaheadMs: 30), 0),
      (SpikeSettings(lookaheadMs: 20), 0),
    ];
    final playback = <Map<String, Object>>[];
    final engines = <bool, AudioEngine>{};
    for (var i = 0; i < scenarios.length; i++) {
      final (s, jankMs) = scenarios[i];
      final engine = engines.putIfAbsent(
        s.background,
        () => createEngine(background: s.background),
      );
      await tester.runAsync(() async {
        mark('scenario-start', {
          'index': i,
          'mode': engine.mode,
          'jankMs': jankMs,
          ...s.toJson(),
        });
        await engine.start(s);
        // Simulated UI jank: block this (UI) thread for jankMs every 400 ms
        // (longer than the 100 ms buffer, like a slow layout or GC pause).
        final jank = jankMs == 0
            ? null
            : Timer.periodic(const Duration(milliseconds: 400), (_) {
                final sw = Stopwatch()..start();
                while (sw.elapsedMilliseconds < jankMs) {}
              });
        await Future<void>.delayed(const Duration(seconds: seconds));
        jank?.cancel();
        final stats = await engine.stop();
        mark('scenario-stop', {'index': i});
        final row = {...stats.toJson(), 'jankMs': jankMs};
        playback.add(row);
        // ignore: avoid_print
        print('SPIKE_RESULT playback ${jsonEncode(row)}');
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
    }
    for (final e in engines.values) {
      e.dispose();
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
  }, timeout: const Timeout(Duration(minutes: 15)));
}
