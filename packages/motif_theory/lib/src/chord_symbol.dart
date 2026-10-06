import 'chord.dart';
import 'note_name.dart';

const _naturalExtension = {
  ChordFunction.ninth: 14,
  ChordFunction.eleventh: 17,
  ChordFunction.thirteenth: 21,
};

const _intervalLabels = {
  1: 'b2',
  2: '2',
  5: '4',
  6: '#4',
  8: 'b6',
  9: '6',
  13: 'b9',
  14: '9',
  15: '#9',
  17: '11',
  18: '#11',
  20: 'b13',
  21: '13',
};

/// Absolute chord symbol, e.g. `Cmaj7/E`, `F#m7b5`, `G7(b9)`, `Bb6/9`.
///
/// ASCII by default; pass [unicode] for ♯/♭ glyphs.
String chordSymbol(Chord chord, {bool unicode = false}) {
  String note(NoteName n) => unicode ? n.display : n.toString();
  String acc(String s) =>
      unicode ? s.replaceAll('b', '♭').replaceAll('#', '♯') : s;

  final third = chord.thirdSemitones;
  final fifths = chord.fifthSemitones;
  final fifth = fifths.length == 1 ? fifths.single : null;
  final seventh = chord.seventhSemitones;

  // Highest unaltered extension present (needs a seventh to count).
  var ext = 7;
  if (seventh != null) {
    for (final entry in _naturalExtension.entries) {
      if (chord.tonesFor(entry.key).any((t) => t.semitones == entry.value)) {
        ext = int.parse(_intervalLabels[entry.value]!);
      }
    }
  }

  final parens = <String>[];
  var fifthHandled = false;
  String quality;
  if (third == 3 && fifth == 6) {
    fifthHandled = true;
    quality = switch (seventh) {
      null => 'dim',
      9 => 'dim7',
      10 => ext == 7 ? 'm7b5' : 'm${ext}b5',
      _ => 'dimMaj7',
    };
  } else if (third == 4 && fifth == 8) {
    fifthHandled = true;
    quality = switch (seventh) {
      null => 'aug',
      10 => 'aug$ext',
      _ => 'augMaj$ext',
    };
  } else {
    final minor = third == 3 ? 'm' : '';
    quality = switch (seventh) {
      null => minor,
      11 => '${minor == 'm' ? 'mMaj' : 'maj'}$ext',
      10 => '$minor$ext',
      _ => '$minor(bb7)',
    };
  }

  // Sus replaces the third.
  if (chord.toneFor(ChordFunction.sus2) != null) quality += 'sus2';
  if (chord.toneFor(ChordFunction.sus4) != null) quality += 'sus4';

  // Added tones: a natural 6 (and 6/9) on a chord without a seventh reads
  // as "6"; everything else is "addN".
  final add6 = chord.toneFor(ChordFunction.add6);
  final add9 = chord.toneFor(ChordFunction.add9);
  final add4 = chord.toneFor(ChordFunction.add4);
  if (seventh == null && add6?.semitones == 9) {
    quality += add9?.semitones == 14 ? '6/9' : '6';
    if (add9 != null && add9.semitones != 14) {
      quality += 'add${_intervalLabels[add9.semitones]}';
    }
  } else {
    if (add6 != null) quality += 'add${_intervalLabels[add6.semitones]}';
    if (add9 != null) quality += 'add${_intervalLabels[add9.semitones]}';
  }
  if (add4 != null) quality += 'add${_intervalLabels[add4.semitones]}';

  if (!fifthHandled) {
    for (final f in fifths) {
      if (f == 6) parens.add('b5');
      if (f == 8) parens.add('#5');
    }
  }

  // Altered extensions.
  for (final entry in _naturalExtension.entries) {
    for (final t in chord.tonesFor(entry.key)) {
      if (t.semitones != entry.value) parens.add(_intervalLabels[t.semitones]!);
    }
  }

  // Omissions. A root + perfect fifth alone is a power chord.
  final noThird =
      chord.toneFor(ChordFunction.third) == null &&
      chord.toneFor(ChordFunction.sus2) == null &&
      chord.toneFor(ChordFunction.sus4) == null;
  if (noThird &&
      chord.tones.length == 2 &&
      chord.tones.last.function == ChordFunction.fifth &&
      chord.tones.last.semitones == 7) {
    quality = '5';
  } else {
    if (noThird) parens.add('no3');
    if (fifths.isEmpty) parens.add('no5');
  }

  final buffer = StringBuffer(note(chord.root))..write(acc(quality));
  if (parens.isNotEmpty) buffer.write('(${acc(parens.join(','))})');
  if (chord.bass.name != chord.root) buffer.write('/${note(chord.bass.name)}');
  return buffer.toString();
}
