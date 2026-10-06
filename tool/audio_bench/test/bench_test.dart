import 'dart:typed_data';

import 'package:audio_bench/synthetic_sf2.dart';
import 'package:audio_bench/workload.dart';
import 'package:test/test.dart';

void main() {
  test('synthetic SoundFont loads and the workload makes sound', () {
    final synth = createSynth(ByteData.sublistView(buildSyntheticSoundFont()));
    expect(synth.soundFont.presets, hasLength(2));
    final work = BandWorkload(synth, sampleRate: 48000);
    final left = Float32List(4800);
    final right = Float32List(4800);
    work.render(left, right);
    final peak = left.fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m);
    expect(peak, greaterThan(0.01));
    expect(work.frame, 4800);
  });
}
