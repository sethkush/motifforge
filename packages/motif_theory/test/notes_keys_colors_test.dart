import 'package:motif_theory/motif_theory.dart';
import 'package:test/test.dart';

void main() {
  group('NoteName', () {
    test('parse and print', () {
      for (final s in ['C', 'F#', 'Bb', 'E##', 'Dbb']) {
        expect(NoteName.parse(s).toString(), s);
      }
      expect(NoteName.parse('E♭'), NoteName.parse('Eb'));
      expect(NoteName.parse('Bb').display, 'B♭');
    });

    test('spell picks the accidental for a letter', () {
      expect(NoteName.spell(Letter.e, 3).toString(), 'Eb');
      expect(NoteName.spell(Letter.b, 0).toString(), 'B#');
      expect(NoteName.spell(Letter.c, 11).toString(), 'Cb');
    });
  });

  group('Key.fromPitchClass spelling', () {
    test('major keys use the circle-of-fifths names', () {
      expect(
        [
          for (var pc = 0; pc < 12; pc++)
            '${Key.fromPitchClass(pc, Scale.major).tonic}',
        ],
        ['C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'],
      );
    });

    test('minor keys use the spelling with fewer accidentals', () {
      expect(
        [
          for (var pc = 0; pc < 12; pc++)
            '${Key.fromPitchClass(pc, Scale.minor).tonic}',
        ],
        ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'],
      );
    });
  });

  group('degree spelling and pitch', () {
    test('accidentals keep the degree letter', () {
      final c = Key.parse('C major');
      expect(c.degreeName(2, accidental: 1).toString(), 'D#');
      expect(c.degreeName(3, accidental: -1).toString(), 'Eb');
      expect(Key.parse('F# major').degreeName(7).toString(), 'E#');
      expect(Key.parse('Db major').degreeName(4).toString(), 'Gb');
      expect(Key.parse('E major').degreeName(3).toString(), 'G#');
    });

    test('octave 0 starts at the tonic above middle C', () {
      final c = Key.parse('C major');
      expect(const DegreeNote(1).midi(c), 60);
      expect(const DegreeNote(7).midi(c), 71);
      expect(const DegreeNote(1, octave: 1).midi(c), 72);
      expect(const DegreeNote(5, octave: -1).midi(c), 55);
      expect(const DegreeNote(1).midi(Key.parse('B major')), 71);
      expect(const DegreeNote(3).scientificName(Key.parse('B major')), 'D#5');
      expect(const DegreeNote(7).scientificName(Key.parse('Db major')), 'C5');
    });

    test('fromMidi maps scale tones and chromatic tones', () {
      final c = Key.parse('C major');
      expect(DegreeNote.fromMidi(60, c), const DegreeNote(1));
      expect(DegreeNote.fromMidi(62, c), const DegreeNote(2));
      expect(DegreeNote.fromMidi(64, c), const DegreeNote(3));
      expect(DegreeNote.fromMidi(48, c), const DegreeNote(1, octave: -1));
      expect(DegreeNote.fromMidi(61, c), const DegreeNote(1, accidental: 1));
      expect(
        DegreeNote.fromMidi(61, c, preference: AccidentalPreference.flat),
        const DegreeNote(2, accidental: -1),
      );
      // B♭ in C: lowered 7, also writable as raised 6.
      expect(
        DegreeNote.fromMidi(70, c, preference: AccidentalPreference.flat),
        const DegreeNote(7, accidental: -1),
      );
      // Round trip every pitch in every scale.
      for (final scale in Scale.values) {
        final key = Key.fromPitchClass(2, scale);
        for (var p = 36; p < 96; p++) {
          expect(DegreeNote.fromMidi(p, key).midi(key), p, reason: '$key $p');
        }
      }
    });
  });

  group('placeOctave (Smart Octave)', () {
    test('first note goes in octave 0', () {
      expect(placeOctave(degree: 5), 0);
    });

    test('smart picks the closest octave', () {
      const prev = DegreeNote(1);
      expect(placeOctave(degree: 2, previous: prev), 0);
      expect(placeOctave(degree: 4, previous: prev), 0); // 3 steps up
      expect(placeOctave(degree: 5, previous: prev), -1); // 3 steps down
      expect(placeOctave(degree: 7, previous: prev), -1);
      expect(placeOctave(degree: 1, previous: const DegreeNote(7)), 1);
    });

    test('off keeps the previous octave', () {
      expect(
        placeOctave(degree: 7, previous: const DegreeNote(1), smart: false),
        0,
      );
    });

    test('held up/down shifts and clamps to five octaves', () {
      expect(
        placeOctave(degree: 2, previous: const DegreeNote(1), shift: 1),
        1,
      );
      expect(
        placeOctave(
          degree: 1,
          previous: const DegreeNote(1, octave: 2),
          shift: 1,
        ),
        2,
      );
      expect(
        placeOctave(degree: 7, previous: const DegreeNote(1, octave: -2)),
        -2,
      );
    });
  });

  group('relative scale changes', () {
    test('relative tonic', () {
      final cases = {
        ('C major', Scale.minor): 'A',
        ('A minor', Scale.major): 'C',
        ('C major', Scale.dorian): 'D',
        ('E phrygian', Scale.lydian): 'F',
        ('Eb major', Scale.minor): 'C',
        ('F# minor', Scale.major): 'A',
        ('A harmonic minor', Scale.major): 'C',
        ('C major', Scale.locrian): 'B',
      };
      cases.forEach((input, expected) {
        expect(
          relativeTonic(Key.parse(input.$1), input.$2).toString(),
          expected,
        );
      });
    });

    test('respell keeps pitch and letter', () {
      final c = Key.parse('C major');
      final a = Key.parse('A minor');
      expect(
        const DegreeNote(1).respell(c, a),
        const DegreeNote(3, octave: -1),
      );
      expect(const DegreeNote(6).respell(c, a), const DegreeNote(1));
      final cm = Key.parse('C minor');
      // E natural in C major is a raised 3 in C minor.
      expect(
        const DegreeNote(3).respell(c, cm),
        const DegreeNote(3, accidental: 1),
      );
    });
  });

  group('colours', () {
    test('diatonic-centric rotates with the mode', () {
      expect(degreeColor(1, Scale.major), const SolidColor(ColorSlot.red));
      expect(degreeColor(7, Scale.major), const SolidColor(ColorSlot.pink));
      expect(degreeColor(1, Scale.minor), const SolidColor(ColorSlot.purple));
      expect(degreeColor(3, Scale.minor), const SolidColor(ColorSlot.red));
      expect(degreeColor(1, Scale.dorian), const SolidColor(ColorSlot.orange));
      expect(
        degreeColor(1, Scale.harmonicMinor),
        const SolidColor(ColorSlot.purple),
      );
    });

    test('major-centric stripes pitches between major degrees', () {
      const scheme = ColorScheme.majorCentric;
      expect(
        degreeColor(1, Scale.minor, scheme: scheme),
        const SolidColor(ColorSlot.red),
      );
      expect(
        degreeColor(3, Scale.minor, scheme: scheme),
        const StripedColor(ColorSlot.orange, ColorSlot.yellow),
      );
      expect(
        degreeColor(4, Scale.minor, scheme: scheme),
        const SolidColor(ColorSlot.green),
      );
      expect(
        degreeColor(7, Scale.mixolydian, scheme: scheme),
        const StripedColor(ColorSlot.purple, ColorSlot.pink),
      );
    });

    test('accidentals stripe towards the neighbour', () {
      expect(
        degreeColor(4, Scale.major, accidental: 1),
        const StripedColor(ColorSlot.green, ColorSlot.blue),
      );
      expect(
        degreeColor(1, Scale.major, accidental: -1),
        const StripedColor(ColorSlot.pink, ColorSlot.red),
      );
    });

    test('chord colour comes from the root', () {
      final c = Key.parse('C major');
      expect(
        chordColor(buildChord(const ChordSpec(5), c)),
        const SolidColor(ColorSlot.blue),
      );
      expect(
        chordColor(
          buildChord(const ChordSpec(6, borrowedFrom: Scale.minor), c),
        ),
        const StripedColor(ColorSlot.blue, ColorSlot.purple),
      );
      // V/ii (A major) has a diatonic root → same colour as vi.
      expect(
        chordColor(buildChord(const ChordSpec(2, applied: Applied.fiveOf), c)),
        const SolidColor(ColorSlot.purple),
      );
    });
  });
}
