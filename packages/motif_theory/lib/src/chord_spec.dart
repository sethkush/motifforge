import 'scale.dart';

/// How many stacked thirds the chord has.
enum ChordType {
  triad(3, '5'),
  seventh(4, '7'),
  ninth(5, '9'),
  eleventh(6, '11'),
  thirteenth(7, '13');

  const ChordType(this.toneCount, this.label);

  final int toneCount;

  /// Palette label: 5, 7, 9, 11, 13.
  final String label;

  bool get hasSeventh => this != triad;
}

enum Sus { none, sus2, sus4 }

enum AddTone {
  add4('add4'),
  add6('add6'),
  add9('add9');

  const AddTone(this.label);
  final String label;
}

enum OmitTone {
  no3('no3'),
  no5('no5');

  const OmitTone(this.label);
  final String label;
}

/// Absolute alterations, measured from the chord root.
enum Alteration {
  flat5(6, 4, '♭5', 'b5'),
  sharp5(8, 4, '♯5', '#5'),
  flat9(13, 1, '♭9', 'b9'),
  sharp9(15, 1, '♯9', '#9'),
  sharp11(18, 3, '♯11', '#11'),
  flat13(20, 5, '♭13', 'b13');

  const Alteration(this.semitones, this.letterSteps, this.label, this.ascii);

  /// Semitones above the root.
  final int semitones;

  /// Letters above the root letter (used for spelling).
  final int letterSteps;
  final String label;
  final String ascii;
}

/// Secondary (applied) chord function.
enum Applied {
  none(''),
  fiveOf('V'),
  fourOf('IV'),
  sevenOf('vii');

  const Applied(this.numeral);
  final String numeral;
}

/// A chord as the user enters it: a scale degree plus palette settings.
/// Everything is relative to the key in force, so changing key re-pitches it.
final class ChordSpec {
  const ChordSpec(
    this.degree, {
    this.type = ChordType.triad,
    this.inversion = 0,
    this.sus = Sus.none,
    this.adds = const {},
    this.omits = const {},
    this.alterations = const {},
    this.applied = Applied.none,
    this.borrowedFrom,
  }) : assert(degree >= 1 && degree <= 7),
       assert(inversion >= 0 && inversion <= 3);

  /// Scale degree 1–7. For applied chords this is the *target* degree
  /// (V/ii has degree 2).
  final int degree;
  final ChordType type;

  /// 0 = root position … 3 = third inversion (seventh chords only).
  final int inversion;
  final Sus sus;
  final Set<AddTone> adds;
  final Set<OmitTone> omits;
  final Set<Alteration> alterations;
  final Applied applied;

  /// Parallel scale the chord is borrowed from (same tonic), if any.
  final Scale? borrowedFrom;

  ChordSpec copyWith({
    int? degree,
    ChordType? type,
    int? inversion,
    Sus? sus,
    Set<AddTone>? adds,
    Set<OmitTone>? omits,
    Set<Alteration>? alterations,
    Applied? applied,
    Scale? borrowedFrom,
    bool clearBorrowed = false,
  }) => ChordSpec(
    degree ?? this.degree,
    type: type ?? this.type,
    inversion: inversion ?? this.inversion,
    sus: sus ?? this.sus,
    adds: adds ?? this.adds,
    omits: omits ?? this.omits,
    alterations: alterations ?? this.alterations,
    applied: applied ?? this.applied,
    borrowedFrom: clearBorrowed ? null : borrowedFrom ?? this.borrowedFrom,
  );

  @override
  bool operator ==(Object other) =>
      other is ChordSpec &&
      other.degree == degree &&
      other.type == type &&
      other.inversion == inversion &&
      other.sus == sus &&
      _setEquals(other.adds, adds) &&
      _setEquals(other.omits, omits) &&
      _setEquals(other.alterations, alterations) &&
      other.applied == applied &&
      other.borrowedFrom == borrowedFrom;

  @override
  int get hashCode => Object.hash(
    degree,
    type,
    inversion,
    sus,
    Object.hashAllUnordered(adds),
    Object.hashAllUnordered(omits),
    Object.hashAllUnordered(alterations),
    applied,
    borrowedFrom,
  );

  @override
  String toString() =>
      'ChordSpec($degree ${type.label} inv$inversion'
      '${sus == Sus.none ? '' : ' ${sus.name}'}'
      '${adds.isEmpty ? '' : ' ${adds.map((a) => a.label).join(' ')}'}'
      '${omits.isEmpty ? '' : ' ${omits.map((o) => o.label).join(' ')}'}'
      '${alterations.isEmpty ? '' : ' ${alterations.map((a) => a.ascii).join(' ')}'}'
      '${applied == Applied.none ? '' : ' ${applied.numeral}/'}'
      '${borrowedFrom == null ? '' : ' from ${borrowedFrom!.name}'})';
}

bool _setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.containsAll(b);
