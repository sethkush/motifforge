import 'package:motif_theory/motif_theory.dart';
import 'package:test/test.dart';

/// Diatonic chords for every scale: (key, triad symbols, triad numerals,
/// seventh symbols, seventh numerals) for degrees 1–7.
const _diatonic =
    <(String, List<String>, List<String>, List<String>, List<String>)>[
      (
        'C major',
        ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
        ['I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii°'],
        ['Cmaj7', 'Dm7', 'Em7', 'Fmaj7', 'G7', 'Am7', 'Bm7b5'],
        ['I7', 'ii7', 'iii7', 'IV7', 'V7', 'vi7', 'viiø7'],
      ),
      (
        'A minor',
        ['Am', 'Bdim', 'C', 'Dm', 'Em', 'F', 'G'],
        ['i', 'ii°', 'III', 'iv', 'v', 'VI', 'VII'],
        ['Am7', 'Bm7b5', 'Cmaj7', 'Dm7', 'Em7', 'Fmaj7', 'G7'],
        ['i7', 'iiø7', 'III7', 'iv7', 'v7', 'VI7', 'VII7'],
      ),
      (
        'D dorian',
        ['Dm', 'Em', 'F', 'G', 'Am', 'Bdim', 'C'],
        ['i', 'ii', 'III', 'IV', 'v', 'vi°', 'VII'],
        ['Dm7', 'Em7', 'Fmaj7', 'G7', 'Am7', 'Bm7b5', 'Cmaj7'],
        ['i7', 'ii7', 'III7', 'IV7', 'v7', 'viø7', 'VII7'],
      ),
      (
        'E phrygian',
        ['Em', 'F', 'G', 'Am', 'Bdim', 'C', 'Dm'],
        ['i', 'II', 'III', 'iv', 'v°', 'VI', 'vii'],
        ['Em7', 'Fmaj7', 'G7', 'Am7', 'Bm7b5', 'Cmaj7', 'Dm7'],
        ['i7', 'II7', 'III7', 'iv7', 'vø7', 'VI7', 'vii7'],
      ),
      (
        'F lydian',
        ['F', 'G', 'Am', 'Bdim', 'C', 'Dm', 'Em'],
        ['I', 'II', 'iii', 'iv°', 'V', 'vi', 'vii'],
        ['Fmaj7', 'G7', 'Am7', 'Bm7b5', 'Cmaj7', 'Dm7', 'Em7'],
        ['I7', 'II7', 'iii7', 'ivø7', 'V7', 'vi7', 'vii7'],
      ),
      (
        'G mixolydian',
        ['G', 'Am', 'Bdim', 'C', 'Dm', 'Em', 'F'],
        ['I', 'ii', 'iii°', 'IV', 'v', 'vi', 'VII'],
        ['G7', 'Am7', 'Bm7b5', 'Cmaj7', 'Dm7', 'Em7', 'Fmaj7'],
        ['I7', 'ii7', 'iiiø7', 'IV7', 'v7', 'vi7', 'VII7'],
      ),
      (
        'B locrian',
        ['Bdim', 'C', 'Dm', 'Em', 'F', 'G', 'Am'],
        ['i°', 'II', 'iii', 'iv', 'V', 'VI', 'vii'],
        ['Bm7b5', 'Cmaj7', 'Dm7', 'Em7', 'Fmaj7', 'G7', 'Am7'],
        ['iø7', 'II7', 'iii7', 'iv7', 'V7', 'VI7', 'vii7'],
      ),
      (
        'A harmonic minor',
        ['Am', 'Bdim', 'Caug', 'Dm', 'E', 'F', 'G#dim'],
        ['i', 'ii°', 'III+', 'iv', 'V', 'VI', 'vii°'],
        ['AmMaj7', 'Bm7b5', 'CaugMaj7', 'Dm7', 'E7', 'Fmaj7', 'G#dim7'],
        ['i7', 'iiø7', 'III+7', 'iv7', 'V7', 'VI7', 'vii°7'],
      ),
      (
        'E phrygian dominant',
        ['E', 'F', 'G#dim', 'Am', 'Bdim', 'Caug', 'Dm'],
        ['I', 'II', 'iii°', 'iv', 'v°', 'VI+', 'vii'],
        ['E7', 'Fmaj7', 'G#dim7', 'AmMaj7', 'Bm7b5', 'CaugMaj7', 'Dm7'],
        ['I7', 'II7', 'iii°7', 'iv7', 'vø7', 'VI+7', 'vii7'],
      ),
    ];

void main() {
  for (final (keyText, triads, triadRn, sevenths, seventhRn) in _diatonic) {
    group('diatonic chords in $keyText', () {
      final key = Key.parse(keyText);
      for (var d = 1; d <= 7; d++) {
        test('degree $d', () {
          final triad = buildChord(ChordSpec(d), key);
          expect(chordSymbol(triad), triads[d - 1]);
          expect(romanNumeral(triad).toString(), triadRn[d - 1]);

          final seventh = buildChord(
            ChordSpec(d, type: ChordType.seventh),
            key,
          );
          expect(chordSymbol(seventh), sevenths[d - 1]);
          expect(romanNumeral(seventh).toString(), seventhRn[d - 1]);
        });
      }
    });
  }

  group('extensions in C major', () {
    final c = Key.parse('C major');
    final cases = <(ChordSpec, String, String)>[
      (const ChordSpec(1, type: ChordType.ninth), 'Cmaj9', 'I9'),
      (const ChordSpec(2, type: ChordType.ninth), 'Dm9', 'ii9'),
      (const ChordSpec(3, type: ChordType.ninth), 'Em7(b9)', 'iii9'),
      (const ChordSpec(5, type: ChordType.ninth), 'G9', 'V9'),
      (const ChordSpec(5, type: ChordType.eleventh), 'G11', 'V11'),
      (const ChordSpec(5, type: ChordType.thirteenth), 'G13', 'V13'),
      (const ChordSpec(4, type: ChordType.eleventh), 'Fmaj9(#11)', 'IV11'),
      (const ChordSpec(7, type: ChordType.ninth), 'Bm7b5(b9)', 'viiø9'),
      (const ChordSpec(6, type: ChordType.ninth), 'Am9', 'vi9'),
    ];
    for (final (spec, symbol, rn) in cases) {
      test('$spec', () {
        final chord = buildChord(spec, c);
        expect(chordSymbol(chord), symbol);
        expect(romanNumeral(chord).toString(), rn);
      });
    }
  });

  group('inversions and figured bass', () {
    final c = Key.parse('C major');
    final cases = <(ChordSpec, String, String)>[
      (const ChordSpec(1, inversion: 1), 'C/E', 'I6'),
      (const ChordSpec(1, inversion: 2), 'C/G', 'I64'),
      (
        const ChordSpec(5, type: ChordType.seventh, inversion: 1),
        'G7/B',
        'V65',
      ),
      (
        const ChordSpec(5, type: ChordType.seventh, inversion: 2),
        'G7/D',
        'V43',
      ),
      (
        const ChordSpec(5, type: ChordType.seventh, inversion: 3),
        'G7/F',
        'V42',
      ),
      (
        const ChordSpec(2, type: ChordType.seventh, inversion: 1),
        'Dm7/F',
        'ii65',
      ),
      (const ChordSpec(4, sus: Sus.sus4, inversion: 1), 'Fsus4/Bb', 'IV6sus4'),
    ];
    for (final (spec, symbol, rn) in cases) {
      test('$spec', () {
        final chord = buildChord(spec, c);
        expect(chordSymbol(chord), symbol);
        expect(romanNumeral(chord).toString(), rn);
      });
    }

    test('third inversion needs a seventh', () {
      expect(
        () => buildChord(const ChordSpec(1, inversion: 3), c),
        throwsArgumentError,
      );
    });
  });

  group('sus, add, omit, alterations in C major', () {
    final c = Key.parse('C major');
    final cases = <(ChordSpec, String, String)>[
      (const ChordSpec(1, sus: Sus.sus4), 'Csus4', 'Isus4'),
      (const ChordSpec(1, sus: Sus.sus2), 'Csus2', 'Isus2'),
      (const ChordSpec(2, sus: Sus.sus4), 'Dsus4', 'iisus4'),
      (
        const ChordSpec(5, type: ChordType.seventh, sus: Sus.sus4),
        'G7sus4',
        'V7sus4',
      ),
      (const ChordSpec(1, adds: {AddTone.add9}), 'Cadd9', 'Iadd9'),
      (const ChordSpec(1, adds: {AddTone.add6}), 'C6', 'Iadd6'),
      (
        const ChordSpec(1, adds: {AddTone.add6, AddTone.add9}),
        'C6/9',
        'Iadd6add9',
      ),
      (const ChordSpec(2, adds: {AddTone.add6}), 'Dm6', 'iiadd6'),
      (const ChordSpec(6, adds: {AddTone.add6}), 'Amaddb6', 'viadd6'),
      (const ChordSpec(1, adds: {AddTone.add4}), 'Cadd4', 'Iadd4'),
      (const ChordSpec(1, omits: {OmitTone.no3}), 'C5', 'Ino3'),
      (const ChordSpec(1, omits: {OmitTone.no5}), 'C(no5)', 'Ino5'),
      (
        const ChordSpec(5, type: ChordType.seventh, omits: {OmitTone.no3}),
        'G7(no3)',
        'V7no3',
      ),
      (
        const ChordSpec(
          5,
          type: ChordType.seventh,
          alterations: {Alteration.flat9},
        ),
        'G7(b9)',
        'V7(♭9)',
      ),
      (
        const ChordSpec(
          5,
          type: ChordType.ninth,
          alterations: {Alteration.sharp9},
        ),
        'G7(#9)',
        'V9(♯9)',
      ),
      (
        const ChordSpec(
          5,
          type: ChordType.seventh,
          alterations: {Alteration.sharp5},
        ),
        'Gaug7',
        'V+7(♯5)',
      ),
      (
        const ChordSpec(
          5,
          type: ChordType.seventh,
          alterations: {Alteration.flat5},
        ),
        'G7(b5)',
        'V7(♭5)',
      ),
      (
        const ChordSpec(
          1,
          type: ChordType.thirteenth,
          alterations: {Alteration.sharp11},
        ),
        'Cmaj13(#11)',
        'I13(♯11)',
      ),
      (
        const ChordSpec(
          5,
          type: ChordType.thirteenth,
          alterations: {Alteration.flat13},
        ),
        'G11(b13)',
        'V13(♭13)',
      ),
    ];
    for (final (spec, symbol, rn) in cases) {
      test('$spec', () {
        final chord = buildChord(spec, c);
        expect(chordSymbol(chord), symbol);
        expect(romanNumeral(chord).toString(), rn);
      });
    }
  });

  group('applied chords', () {
    final cases = <(String, ChordSpec, String, String)>[
      ('C major', const ChordSpec(2, applied: Applied.fiveOf), 'A', 'V/ii'),
      (
        'C major',
        const ChordSpec(2, type: ChordType.seventh, applied: Applied.fiveOf),
        'A7',
        'V7/ii',
      ),
      ('C major', const ChordSpec(5, applied: Applied.fiveOf), 'D', 'V/V'),
      (
        'C major',
        const ChordSpec(4, type: ChordType.seventh, applied: Applied.fiveOf),
        'C7',
        'V7/IV',
      ),
      ('C major', const ChordSpec(6, applied: Applied.fiveOf), 'E', 'V/vi'),
      ('C major', const ChordSpec(5, applied: Applied.fourOf), 'C', 'IV/V'),
      ('C major', const ChordSpec(2, applied: Applied.fourOf), 'G', 'IV/ii'),
      (
        'C major',
        const ChordSpec(5, applied: Applied.sevenOf),
        'F#dim',
        'vii°/V',
      ),
      (
        'C major',
        const ChordSpec(5, type: ChordType.seventh, applied: Applied.sevenOf),
        'F#dim7',
        'vii°7/V',
      ),
      (
        'C major',
        const ChordSpec(2, type: ChordType.seventh, applied: Applied.sevenOf),
        'C#dim7',
        'vii°7/ii',
      ),
      ('A minor', const ChordSpec(3, applied: Applied.fiveOf), 'G', 'V/III'),
      (
        'A minor',
        const ChordSpec(4, type: ChordType.seventh, applied: Applied.fiveOf),
        'A7',
        'V7/iv',
      ),
      (
        'A minor',
        const ChordSpec(5, type: ChordType.seventh, applied: Applied.sevenOf),
        'D#dim7',
        'vii°7/v',
      ),
      (
        'Eb major',
        const ChordSpec(2, type: ChordType.seventh, applied: Applied.fiveOf),
        'C7',
        'V7/ii',
      ),
    ];
    for (final (keyText, spec, symbol, rn) in cases) {
      test('$keyText $spec', () {
        final chord = buildChord(spec, Key.parse(keyText));
        expect(chordSymbol(chord), symbol);
        expect(romanNumeral(chord).toString(), rn);
      });
    }
  });

  group('borrowed chords in C major', () {
    final c = Key.parse('C major');
    final cases = <(ChordSpec, String, String)>[
      (const ChordSpec(6, borrowedFrom: Scale.minor), 'Ab', '♭VI'),
      (const ChordSpec(7, borrowedFrom: Scale.minor), 'Bb', '♭VII'),
      (const ChordSpec(3, borrowedFrom: Scale.minor), 'Eb', '♭III'),
      (const ChordSpec(4, borrowedFrom: Scale.minor), 'Fm', 'iv'),
      (const ChordSpec(2, borrowedFrom: Scale.minor), 'Ddim', 'ii°'),
      (const ChordSpec(5, borrowedFrom: Scale.minor), 'Gm', 'v'),
      (const ChordSpec(2, borrowedFrom: Scale.phrygian), 'Db', '♭II'),
      (const ChordSpec(4, borrowedFrom: Scale.lydian), 'F#dim', '♯iv°'),
      (
        const ChordSpec(6, type: ChordType.seventh, borrowedFrom: Scale.minor),
        'Abmaj7',
        '♭VI7',
      ),
      (
        const ChordSpec(5, applied: Applied.fiveOf, borrowedFrom: Scale.minor),
        'D',
        'V/v',
      ),
    ];
    for (final (spec, symbol, rn) in cases) {
      test('$spec', () {
        final chord = buildChord(spec, c);
        expect(chordSymbol(chord), symbol);
        final roman = romanNumeral(chord);
        expect(roman.toString(), rn);
        if (spec.applied == Applied.none) {
          expect(roman.borrowedFrom, spec.borrowedFrom);
        }
      });
    }
  });

  test('chord tones are spelled by stacked letters', () {
    final chord = buildChord(
      const ChordSpec(5, type: ChordType.seventh),
      Key.parse('F# major'),
    );
    expect(chord.noteNames.map((n) => '$n'), ['C#', 'E#', 'G#', 'B']);
    final dim = buildChord(
      const ChordSpec(7, type: ChordType.seventh),
      Key.parse('A harmonic minor'),
    );
    expect(dim.noteNames.map((n) => '$n'), ['G#', 'B', 'D', 'F']);
  });
}
