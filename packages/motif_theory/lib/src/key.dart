import 'note_name.dart';
import 'scale.dart';

/// A tonic plus a scale, e.g. E♭ Minor.
final class Key {
  const Key(this.tonic, this.scale);

  /// Picks the conventional spelling for a tonic pitch class: the spelling
  /// whose scale needs the fewest accidentals; ties go to the names used on
  /// the circle of fifths (C G D A E B F♯ D♭ A♭ E♭ B♭ F).
  factory Key.fromPitchClass(int pitchClass, Scale scale) {
    final pc = pitchClass % 12;
    final candidates = <NoteName>[
      for (final letter in Letter.values)
        if (wrapSemitones(pc - letter.naturalPitchClass).abs() <= 1)
          NoteName.spell(letter, pc),
    ];
    int cost(NoteName tonic) {
      final key = Key(tonic, scale);
      var total = 0;
      for (var d = 1; d <= 7; d++) {
        total += key.degreeName(d).accidental.abs();
      }
      return total;
    }

    candidates.sort((a, b) {
      final byCost = cost(a).compareTo(cost(b));
      if (byCost != 0) return byCost;
      final aDefault = _circleNames[pc] == a ? 0 : 1;
      final bDefault = _circleNames[pc] == b ? 0 : 1;
      return aDefault.compareTo(bDefault);
    });
    return Key(candidates.first, scale);
  }

  /// Parses `C major`, `F# minor`, `Bb dorian`, `A harmonic minor`.
  factory Key.parse(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    final tonic = NoteName.parse(parts.first);
    final scaleText = parts.skip(1).join(' ').toLowerCase();
    final scale = Scale.values.firstWhere(
      (s) => s.displayName.toLowerCase() == scaleText,
      orElse: () => throw FormatException('Unknown scale', text),
    );
    return Key(tonic, scale);
  }

  static final _circleNames = [
    'C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B', //
  ].map(NoteName.parse).toList();

  final NoteName tonic;
  final Scale scale;

  /// Pitch class of scale degree [degree] (1-based, may exceed 7) with an
  /// optional chromatic [accidental].
  int degreePitchClass(int degree, {int accidental = 0}) =>
      (tonic.pitchClass + scale.semitonesOf(degree) + accidental) % 12;

  /// Spelling of scale degree [degree]: the letter is always the tonic's
  /// letter plus (degree − 1), so ♯2 in C is D♯, never E♭.
  NoteName degreeName(int degree, {int accidental = 0}) => NoteName.spell(
    tonic.letter + (degree - 1),
    degreePitchClass(degree, accidental: accidental),
  );

  @override
  String toString() => '$tonic ${scale.displayName}';

  @override
  bool operator ==(Object other) =>
      other is Key && other.tonic == tonic && other.scale == scale;

  @override
  int get hashCode => Object.hash(tonic, scale);
}
