import 'package:audio_bench/benchmark.dart';

/// Browser entry point: prints results to the console (and the page).
void main() {
  print('Platform: web');
  for (final effects in [true, false]) {
    runBenchmark(effects: effects, seconds: 10, onResult: print);
  }
  print('DONE');
}
