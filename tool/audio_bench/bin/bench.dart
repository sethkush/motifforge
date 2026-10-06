import 'dart:io';
import 'dart:typed_data';

import 'package:audio_bench/benchmark.dart';

/// Usage: dart run audio_bench:bench [path/to/soundfont.sf2]
///
/// Without a path it uses the built-in synthetic SoundFont.
void main(List<String> args) {
  ByteData? sf;
  if (args.isNotEmpty) {
    sf = ByteData.sublistView(File(args.first).readAsBytesSync());
    stdout.writeln('SoundFont: ${args.first}');
  } else {
    stdout.writeln('SoundFont: synthetic (built in)');
  }
  stdout.writeln(
    'Platform: Dart VM ${Platform.version.split(' ').first}, '
    '${Platform.operatingSystem}, ${Platform.numberOfProcessors} cores\n',
  );
  for (final effects in [true, false]) {
    runBenchmark(soundFont: sf, effects: effects, onResult: stdout.writeln);
  }
}
