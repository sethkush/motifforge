import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Builds a tiny, licence-free SoundFont 2 file in memory: a looped
/// harmonic tone (bank 0, program 0) and a noise-burst kit (bank 128,
/// program 0). Voice cost in a SoundFont synth hardly depends on the sample
/// content, so this is a fair stand-in for benchmarking.
Uint8List buildSyntheticSoundFont() {
  const rate = 44100;
  const period = 100; // 441 Hz, ~A4 + 4 cents
  const toneLength = period * 200;
  const noiseLength = 4410;
  const pad = 46; // zero samples required after each sample

  final samples = Int16List(toneLength + pad + noiseLength + pad);
  for (var i = 0; i < toneLength; i++) {
    final phase = 2 * math.pi * (i % period) / period;
    final v =
        0.6 * math.sin(phase) +
        0.25 * math.sin(2 * phase) +
        0.1 * math.sin(3 * phase) +
        0.05 * math.sin(5 * phase);
    samples[i] = (v * 20000).round();
  }
  final rng = math.Random(1);
  const noiseStart = toneLength + pad;
  for (var i = 0; i < noiseLength; i++) {
    final env = math.exp(-i / 600);
    samples[noiseStart + i] = ((rng.nextDouble() * 2 - 1) * env * 20000)
        .round();
  }

  int timecents(double seconds) =>
      (1200 * math.log(seconds) / math.ln2).round();

  // Generator operators (SoundFont 2.04 §8.1.2).
  const instrumentGen = 41;
  const attackVolEnv = 34;
  const decayVolEnv = 36;
  const sustainVolEnv = 37;
  const releaseVolEnv = 38;
  const sampleId = 53;
  const sampleModes = 54;
  const overridingRootKey = 58;

  final toneGens = [
    (attackVolEnv, timecents(0.002)),
    (decayVolEnv, timecents(1.5)),
    (sustainVolEnv, 200), // centibels of attenuation
    (releaseVolEnv, timecents(0.3)),
    (sampleModes, 1), // loop
    (sampleId, 0),
  ];
  final kitGens = [
    (releaseVolEnv, timecents(0.1)),
    (sampleModes, 0),
    (overridingRootKey, 60),
    (sampleId, 1),
  ];

  final info = _list('INFO', [
    _chunk('ifil', _u16s([2, 1])),
    _chunk('isng', _zstr('EMU8000')),
    _chunk('INAM', _zstr('MotifForge synthetic bench')),
  ]);
  final sdta = _list('sdta', [_chunk('smpl', samples.buffer.asUint8List())]);

  final pdta = _list('pdta', [
    _chunk(
      'phdr',
      _concat([
        _phdr('Bench Keys', 0, 0, 0),
        _phdr('Bench Kit', 0, 128, 1),
        _phdr('EOP', 0, 0, 2),
      ]),
    ),
    _chunk('pbag', _u16s([0, 0, 1, 0, 2, 0])),
    _chunk('pmod', Uint8List(10)),
    _chunk('pgen', _u16s([instrumentGen, 0, instrumentGen, 1, 0, 0])),
    _chunk(
      'inst',
      _concat([
        _inst('Bench Tone', 0),
        _inst('Bench Noise', 1),
        _inst('EOI', 2),
      ]),
    ),
    _chunk(
      'ibag',
      _u16s([0, 0, toneGens.length, 0, toneGens.length + kitGens.length, 0]),
    ),
    _chunk('imod', Uint8List(10)),
    _chunk(
      'igen',
      _u16s([
        for (final (op, amount) in [...toneGens, ...kitGens, (0, 0)]) ...[
          op,
          amount & 0xffff,
        ],
      ]),
    ),
    _chunk(
      'shdr',
      _concat([
        _shdr('Tone', 0, toneLength, period, toneLength - period, rate, 69, -4),
        _shdr(
          'Noise',
          noiseStart,
          noiseStart + noiseLength,
          noiseStart,
          noiseStart + noiseLength - 1,
          rate,
          60,
          0,
        ),
        _shdr('EOS', 0, 0, 0, 0, 0, 0, 0, type: 0),
      ]),
    ),
  ]);

  final body = _concat([ascii.encode('sfbk'), info, sdta, pdta]);
  return _concat([ascii.encode('RIFF'), _u32(body.length), body]);
}

Uint8List _concat(List<List<int>> parts) {
  final b = BytesBuilder(copy: false);
  for (final p in parts) {
    b.add(p);
  }
  return b.toBytes();
}

Uint8List _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

Uint8List _u16s(List<int> values) {
  final d = ByteData(values.length * 2);
  for (var i = 0; i < values.length; i++) {
    d.setUint16(i * 2, values[i] & 0xffff, Endian.little);
  }
  return d.buffer.asUint8List();
}

Uint8List _zstr(String s) {
  final bytes = [...ascii.encode(s), 0];
  if (bytes.length.isOdd) bytes.add(0);
  return Uint8List.fromList(bytes);
}

Uint8List _name20(String s) {
  final out = Uint8List(20);
  out.setRange(0, s.length, ascii.encode(s));
  return out;
}

Uint8List _chunk(String id, Uint8List data) => _concat([
  ascii.encode(id),
  _u32(data.length),
  data,
  if (data.length.isOdd) [0],
]);

Uint8List _list(String type, List<Uint8List> chunks) {
  final body = _concat([ascii.encode(type), ...chunks]);
  return _concat([ascii.encode('LIST'), _u32(body.length), body]);
}

Uint8List _phdr(String name, int preset, int bank, int bag) {
  final d = ByteData(38 - 20);
  d.setUint16(0, preset, Endian.little);
  d.setUint16(2, bank, Endian.little);
  d.setUint16(4, bag, Endian.little);
  return _concat([_name20(name), d.buffer.asUint8List()]);
}

Uint8List _inst(String name, int bag) => _concat([
  _name20(name),
  _u16s([bag]),
]);

Uint8List _shdr(
  String name,
  int start,
  int end,
  int loopStart,
  int loopEnd,
  int rate,
  int pitch,
  int correction, {
  int type = 1,
}) {
  final d = ByteData(26);
  d.setUint32(0, start, Endian.little);
  d.setUint32(4, end, Endian.little);
  d.setUint32(8, loopStart, Endian.little);
  d.setUint32(12, loopEnd, Endian.little);
  d.setUint32(16, rate, Endian.little);
  d.setUint8(20, pitch);
  d.setInt8(21, correction);
  d.setUint16(22, 0, Endian.little);
  d.setUint16(24, type, Endian.little);
  return _concat([_name20(name), d.buffer.asUint8List()]);
}
