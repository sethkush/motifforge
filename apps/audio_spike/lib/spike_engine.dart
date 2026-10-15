import 'dart:async';

import 'package:audio_bench/benchmark.dart';
import 'package:flutter/foundation.dart';

export 'engine/engine.dart';

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
