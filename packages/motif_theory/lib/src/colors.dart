import 'chord.dart';
import 'key.dart';
import 'note_name.dart';
import 'scale.dart';

/// The seven hue slots, in wheel order. Actual colour values live in the UI
/// theme; theory only decides which slot (or pair of slots) applies.
enum ColorSlot { red, orange, yellow, green, blue, purple, pink }

enum ColorScheme {
  /// Colours rotate with the mode, so relative keys share colours and the
  /// colour gaps between degrees match the interval pattern in every scale.
  diatonicCentric,

  /// Colours follow the major scale; pitches between two major-scale
  /// degrees are striped with both neighbours' colours.
  majorCentric,
}

sealed class DegreeColor {
  const DegreeColor();
}

final class SolidColor extends DegreeColor {
  const SolidColor(this.slot);
  final ColorSlot slot;

  @override
  bool operator ==(Object other) => other is SolidColor && other.slot == slot;
  @override
  int get hashCode => slot.hashCode;
  @override
  String toString() => slot.name;
}

/// A chromatic pitch drawn with stripes of two neighbouring colours.
final class StripedColor extends DegreeColor {
  const StripedColor(this.lower, this.upper);
  final ColorSlot lower;
  final ColorSlot upper;

  @override
  bool operator ==(Object other) =>
      other is StripedColor && other.lower == lower && other.upper == upper;
  @override
  int get hashCode => Object.hash(lower, upper);
  @override
  String toString() => '${lower.name}/${upper.name}';
}

ColorSlot _slot(int index) => ColorSlot.values[index % 7];

/// Colour of scale degree [degree] with chromatic [accidental] in [scale].
DegreeColor degreeColor(
  int degree,
  Scale scale, {
  int accidental = 0,
  ColorScheme scheme = ColorScheme.diatonicCentric,
}) {
  switch (scheme) {
    case ColorScheme.diatonicCentric:
      final index = degree - 1 + scale.modeRotation;
      if (accidental == 0) return SolidColor(_slot(index));
      return accidental > 0
          ? StripedColor(_slot(index), _slot(index + 1))
          : StripedColor(_slot(index - 1), _slot(index));
    case ColorScheme.majorCentric:
      final offset = (scale.intervals[degree - 1] + accidental) % 12;
      final exact = Scale.major.intervals.indexOf(offset);
      if (exact >= 0) return SolidColor(_slot(exact));
      final below = Scale.major.intervals.lastIndexWhere((i) => i < offset);
      return StripedColor(_slot(below), _slot(below + 1));
  }
}

/// Colour of a chord, taken from its root relative to the key it is in
/// (so borrowed and applied chords with a non-diatonic root are striped).
DegreeColor chordColor(
  Chord chord, {
  ColorScheme scheme = ColorScheme.diatonicCentric,
}) {
  final key = chord.key;
  final degree = chord.root.letter.stepsAbove(key.tonic.letter) + 1;
  final accidental = wrapSemitones(
    chord.root.pitchClass - key.degreePitchClass(degree),
  );
  return degreeColor(degree, key.scale, accidental: accidental, scheme: scheme);
}

/// Tonic after a *relative* scale change (pitches kept, degrees renumbered):
/// C Major → Minor gives A. Harmonic minor and Phrygian dominant move as
/// their parent modes (Aeolian, Phrygian).
NoteName relativeTonic(Key from, Scale to) {
  final ionianTonicPc =
      from.tonic.pitchClass - Scale.major.intervals[from.scale.modeRotation];
  final ionianLetter = from.tonic.letter + -from.scale.modeRotation;
  return NoteName.spell(
    ionianLetter + to.modeRotation,
    ionianTonicPc + Scale.major.intervals[to.modeRotation],
  );
}
