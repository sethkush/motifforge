/// The seven natural note letters.
enum Letter {
  c,
  d,
  e,
  f,
  g,
  a,
  b;

  static const _naturalPitchClasses = [0, 2, 4, 5, 7, 9, 11];

  /// Pitch class (0–11) of the natural (unaltered) letter.
  int get naturalPitchClass => _naturalPitchClasses[index];

  /// The letter [steps] letters above this one (negative steps go down).
  Letter operator +(int steps) => Letter.values[(index + steps) % 7];

  /// Number of letter steps from [other] up to this letter (0–6).
  int stepsAbove(Letter other) => (index - other.index) % 7;

  String get symbol => name.toUpperCase();
}

/// Wraps a semitone difference into the range −6…+5.
int wrapSemitones(int semitones) => (semitones + 6) % 12 - 6;

/// A spelled pitch class, e.g. C, F♯ or B♭♭. Octave-independent.
final class NoteName {
  const NoteName(this.letter, [this.accidental = 0]);

  /// Spells [pitchClass] using [letter], choosing whatever accidental is
  /// needed (e.g. letter E + pitch class 3 → E♭).
  factory NoteName.spell(Letter letter, int pitchClass) =>
      NoteName(letter, wrapSemitones(pitchClass - letter.naturalPitchClass));

  /// Parses `C`, `c#`, `Bb`, `F##`, `E♭`, `G♯`.
  factory NoteName.parse(String text) {
    final s = text.trim();
    if (s.isEmpty) throw FormatException('Empty note name');
    final letter = Letter.values.firstWhere(
      (l) => l.symbol == s[0].toUpperCase(),
      orElse: () => throw FormatException('Bad note letter', text),
    );
    var accidental = 0;
    for (final ch in s.substring(1).split('')) {
      switch (ch) {
        case '#' || '♯':
          accidental++;
        case 'b' || '♭':
          accidental--;
        default:
          throw FormatException('Bad accidental', text);
      }
    }
    return NoteName(letter, accidental);
  }

  final Letter letter;

  /// Semitones of alteration: −1 = flat, +1 = sharp, 0 = natural.
  final int accidental;

  int get pitchClass => (letter.naturalPitchClass + accidental) % 12;

  /// ASCII spelling, e.g. `F#`, `Bb`.
  @override
  String toString() =>
      letter.symbol + (accidental >= 0 ? '#' * accidental : 'b' * -accidental);

  /// Display spelling with ♯/♭ glyphs.
  String get display =>
      letter.symbol + (accidental >= 0 ? '♯' * accidental : '♭' * -accidental);

  @override
  bool operator ==(Object other) =>
      other is NoteName &&
      other.letter == letter &&
      other.accidental == accidental;

  @override
  int get hashCode => Object.hash(letter, accidental);
}

/// Accidental prefix for degree-relative labels (`♭`, `♯`, `♭♭`…), or `''`.
String accidentalPrefix(int accidental, {bool ascii = false}) {
  final sharp = ascii ? '#' : '♯';
  final flat = ascii ? 'b' : '♭';
  return accidental >= 0 ? sharp * accidental : flat * -accidental;
}
