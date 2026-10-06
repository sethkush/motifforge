import 'chord.dart';
import 'chord_spec.dart';
import 'key.dart';
import 'note_name.dart';
import 'scale.dart';

const _numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

/// A Roman-numeral label, kept structured so the UI can typeset figured bass
/// as stacked digits.
final class RomanNumeral {
  const RomanNumeral({
    required this.accidental,
    required this.numeral,
    required this.quality,
    required this.figures,
    this.extras = const [],
    this.alterations = const [],
    this.appliedTo,
    this.borrowedFrom,
  });

  /// Chromatic offset of the root from the key's degree (♭VI → −1).
  final int accidental;

  /// `IV` or `iv` — case follows the chord's third.
  final String numeral;

  /// `''`, `°` (diminished), `ø` (half-diminished) or `+` (augmented).
  final String quality;

  /// Figured bass / type figures: `''`, `6`, `64`, `7`, `65`, `43`, `42`,
  /// `9`, `11`, `13`.
  final String figures;

  /// Suffixes such as `sus4`, `add9`, `no5`.
  final List<String> extras;

  /// Alterations such as `♭9`, shown in parentheses.
  final List<String> alterations;

  /// For applied chords, the target (V/**ii**).
  final RomanNumeral? appliedTo;

  /// Parallel scale a borrowed chord comes from (for a UI tag).
  final Scale? borrowedFrom;

  @override
  String toString() {
    final b = StringBuffer()
      ..write(accidentalPrefix(accidental))
      ..write(numeral)
      ..write(quality)
      ..write(figures)
      ..writeAll(extras);
    if (alterations.isNotEmpty) b.write('(${alterations.join(',')})');
    if (appliedTo != null) b.write('/$appliedTo');
    return b.toString();
  }
}

/// Roman numeral for [chord] relative to the key it was entered in.
///
/// Diatonic chords carry no quality marks beyond °, ø and + (a diatonic
/// seventh is just "7", as in classical analysis). Borrowed chords get an
/// accidental when their root differs from the key's degree (♭VI, ♭VII).
RomanNumeral romanNumeral(Chord chord) {
  final spec = chord.spec;
  final key = chord.key;

  final third = chord.thirdSemitones;
  final minor = third == null ? chord.naturalThirdIsMinor : third == 3;
  final fifths = chord.fifthSemitones;
  final fifth = fifths.length == 1 ? fifths.single : null;
  final seventh = chord.seventhSemitones;

  var quality = '';
  if (third == 3 && fifth == 6) {
    quality = seventh == 10 ? 'ø' : '°';
  } else if (third == 4 && fifth == 8) {
    quality = '+';
  }

  final String figures;
  if (seventh != null) {
    figures = switch (spec.inversion) {
      0 => spec.type.label,
      1 => '65',
      2 => '43',
      _ => '42',
    };
  } else {
    figures = const ['', '6', '64'][spec.inversion];
  }

  final extras = <String>[
    if (spec.sus != Sus.none) spec.sus.name,
    for (final a in AddTone.values)
      if (spec.adds.contains(a)) a.label,
    for (final o in OmitTone.values)
      if (spec.omits.contains(o)) o.label,
  ];
  final alterations = [
    for (final a in Alteration.values)
      if (spec.alterations.contains(a)) a.label,
  ];

  if (spec.applied != Applied.none) {
    final numeral = minor
        ? spec.applied.numeral.toLowerCase()
        : spec.applied.numeral.toUpperCase();
    final target = romanNumeral(
      buildChord(ChordSpec(spec.degree, borrowedFrom: spec.borrowedFrom), key),
    );
    return RomanNumeral(
      accidental: 0,
      numeral: numeral,
      quality: quality,
      figures: figures,
      extras: extras,
      alterations: alterations,
      appliedTo: target,
    );
  }

  final base = _numerals[spec.degree - 1];
  return RomanNumeral(
    accidental: wrapSemitones(
      chord.root.pitchClass - key.degreePitchClass(spec.degree),
    ),
    numeral: minor ? base.toLowerCase() : base,
    quality: quality,
    figures: figures,
    extras: extras,
    alterations: alterations,
    borrowedFrom: spec.borrowedFrom,
  );
}

/// Convenience: build and label in one step.
RomanNumeral romanNumeralOf(ChordSpec spec, Key key) =>
    romanNumeral(buildChord(spec, key));
