import 'package:dart_melty_soundfont/dart_melty_soundfont.dart';

/// A looping, band-like note stream resembling a default Hookpad-style
/// arrangement at [bpm] in 4/4: melody (1 note/beat), harmony (3-note chord
/// every beat), dotted bass, a drum groove with 8th-note hats, plus
/// [stressVoices] extra sustained notes re-struck every bar.
///
/// Events are applied with block accuracy ([blockSize] frames), which is
/// what the real transport will do too.
final class BandWorkload {
  BandWorkload(
    this.synth, {
    required this.sampleRate,
    this.bpm = 120,
    this.stressVoices = 0,
    this.blockSize = 64,
  }) : _left = Float32List(blockSize),
       _right = Float32List(blockSize) {
    synth.selectPreset(channel: 0, preset: 0);
  }

  final Synthesizer synth;
  final int sampleRate;
  final double bpm;
  final int blockSize;
  int stressVoices;

  final Float32List _left;
  final Float32List _right;
  int _frame = 0;
  int _nextTick = 0;

  static const ticksPerBeat = 4; // 16th-note grid
  static const _progression = [
    [60, 64, 67], // I
    [67, 71, 74], // V
    [69, 72, 76], // vi
    [65, 69, 72], // IV
  ];
  static const _melody = [72, 74, 76, 79, 77, 76, 74, 72];
  final _sounding = <(int, int)>[];

  double get _framesPerTick => sampleRate * 60 / bpm / ticksPerBeat;

  /// Total frames rendered so far.
  int get frame => _frame;

  void _off(int channel) {
    _sounding.removeWhere((n) {
      if (n.$1 != channel) return false;
      synth.noteOff(channel: n.$1, key: n.$2);
      return true;
    });
  }

  void _on(int channel, int key, [int velocity = 100]) {
    synth.noteOn(channel: channel, key: key, velocity: velocity);
    if (channel != 9) _sounding.add((channel, key));
  }

  void _tick(int tick) {
    final step = tick % ticksPerBeat;
    final beat = tick ~/ ticksPerBeat;
    final bar = beat ~/ 4;
    final chord = _progression[bar % _progression.length];

    if (step == 0) {
      _off(0);
      _on(0, _melody[beat % _melody.length]);
      _off(1);
      for (final k in chord) {
        _on(1, k, 80);
      }
      if (beat % 4 == 0 || beat % 4 == 2) {
        _off(2);
        _on(2, chord.first - 24, 110);
      }
      _on(9, beat.isEven ? 36 : 38, 120); // kick / snare
      if (beat % 4 == 0 && stressVoices > 0) {
        _off(3);
        for (var i = 0; i < stressVoices; i++) {
          _on(3, 48 + i % 36, 60);
        }
      }
    }
    if (step == 2) _on(9, 42, 70); // off-beat hat
    if (step == 0) _on(9, 42, 90);
    if (step == 3 && beat % 2 == 0) {
      _off(2);
      _on(2, chord.first - 24, 90); // dotted bass pickup
    }
  }

  /// Renders [left.length] frames (a multiple of [blockSize]).
  void render(Float32List left, Float32List right) {
    for (var offset = 0; offset < left.length; offset += blockSize) {
      while (_nextTick * _framesPerTick <= _frame) {
        _tick(_nextTick++);
      }
      synth.render(_left, _right);
      left.setRange(offset, offset + blockSize, _left);
      right.setRange(offset, offset + blockSize, _right);
      _frame += blockSize;
    }
  }
}

/// Creates a synthesizer suitable for the workload.
Synthesizer createSynth(
  ByteData soundFont, {
  int sampleRate = 48000,
  int blockSize = 64,
  int polyphony = 128,
  bool effects = true,
}) => Synthesizer.loadByteData(
  soundFont,
  SynthesizerSettings(
    sampleRate: sampleRate,
    blockSize: blockSize,
    maximumPolyphony: polyphony,
    enableReverbAndChorus: effects,
  ),
);
