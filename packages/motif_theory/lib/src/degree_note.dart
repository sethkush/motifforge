import 'key.dart';
import 'note_name.dart';

/// Lowest and highest melody octaves (5 octaves in total).
const minOctave = -2;
const maxOctave = 2;

/// MIDI pitch of the tonic in octave 0: the tonic's pitch class in the octave
/// starting at middle C (C4 = 60), so octave 0 spans tonic…tonic+11.
int tonicMidi(Key key) => 60 + key.tonic.pitchClass;

/// How a chromatic pitch that isn't in the scale is named when converting
/// from absolute pitch (e.g. MIDI input).
enum AccidentalPreference { sharp, flat }

/// A melody note written as a scale degree, relative to the key in force.
final class DegreeNote {
  const DegreeNote(this.degree, {this.accidental = 0, this.octave = 0})
    : assert(degree >= 1 && degree <= 7);

  /// Converts an absolute MIDI [pitch] into a degree in [key]. In-scale
  /// pitches get no accidental; others are written per [preference].
  factory DegreeNote.fromMidi(
    int pitch,
    Key key, {
    AccidentalPreference preference = AccidentalPreference.sharp,
  }) {
    final offset = (pitch - tonicMidi(key)) % 12;
    var degree = key.scale.intervals.indexOf(offset) + 1;
    var accidental = 0;
    if (degree == 0) {
      accidental = preference == AccidentalPreference.sharp ? 1 : -1;
      degree = key.scale.intervals.indexOf((offset - accidental) % 12) + 1;
      if (degree == 0) {
        accidental = -accidental;
        degree = key.scale.intervals.indexOf((offset - accidental) % 12) + 1;
      }
    }
    final base = tonicMidi(key) + key.scale.intervals[degree - 1] + accidental;
    return DegreeNote(
      degree,
      accidental: accidental,
      octave: ((pitch - base) / 12).floor(),
    );
  }

  /// Scale degree 1–7.
  final int degree;

  /// Chromatic alteration in semitones (−1 = lowered, +1 = raised).
  final int accidental;

  /// Octave relative to the tonic octave (−2…+2).
  final int octave;

  /// Absolute MIDI pitch in [key].
  int midi(Key key) =>
      tonicMidi(key) +
      key.scale.intervals[degree - 1] +
      accidental +
      12 * octave;

  /// Spelled name in [key] (letter fixed by the degree).
  NoteName name(Key key) => key.degreeName(degree, accidental: accidental);

  /// Scientific pitch name, e.g. `D#4`.
  String scientificName(Key key) {
    final n = name(key);
    final naturalMidi = midi(key) - n.accidental;
    return '$n${naturalMidi ~/ 12 - 1}';
  }

  /// Diatonic step index, ignoring accidentals (7 per octave).
  int get diatonicIndex => octave * 7 + degree - 1;

  /// Re-expresses this note in [to] without changing its pitch, keeping the
  /// note's letter (used when the scale changes "relatively").
  DegreeNote respell(Key from, Key to) {
    final n = name(from);
    final pitch = midi(from);
    final newDegree = n.letter.stepsAbove(to.tonic.letter) + 1;
    final accidental = wrapSemitones(
      n.pitchClass - to.degreePitchClass(newDegree),
    );
    final base = tonicMidi(to) + to.scale.intervals[newDegree - 1] + accidental;
    return DegreeNote(
      newDegree,
      accidental: accidental,
      octave: ((pitch - base) / 12).round(),
    );
  }

  DegreeNote copyWith({int? degree, int? accidental, int? octave}) =>
      DegreeNote(
        degree ?? this.degree,
        accidental: accidental ?? this.accidental,
        octave: octave ?? this.octave,
      );

  @override
  String toString() =>
      '${accidentalPrefix(accidental, ascii: true)}$degree'
      '${octave == 0 ? '' : '@$octave'}';

  @override
  bool operator ==(Object other) =>
      other is DegreeNote &&
      other.degree == degree &&
      other.accidental == accidental &&
      other.octave == octave;

  @override
  int get hashCode => Object.hash(degree, accidental, octave);
}

/// Octave for a newly typed [degree] following [previous].
///
/// With [smart] on (the default setting) the note goes in whichever octave
/// is closest to the previous note in scale steps — with 7 steps per octave
/// there is never a tie. With [smart] off it stays in the previous note's
/// octave. [shift] (−1/+1, from holding ↓/↑ while typing) moves the result
/// an octave. The result is clamped to the 5 supported octaves.
int placeOctave({
  required int degree,
  DegreeNote? previous,
  bool smart = true,
  int shift = 0,
}) {
  var octave = 0;
  if (previous != null) {
    octave = previous.octave;
    if (smart) {
      var best = octave;
      var bestDistance = 1 << 30;
      for (final o in [octave - 1, octave, octave + 1]) {
        final distance = (o * 7 + degree - 1 - previous.diatonicIndex).abs();
        if (distance < bestDistance) {
          best = o;
          bestDistance = distance;
        }
      }
      octave = best;
    }
  }
  return (octave + shift).clamp(minOctave, maxOctave);
}
