import 'chord_spec.dart';
import 'key.dart';
import 'note_name.dart';
import 'scale.dart';

/// The role a tone plays in a chord.
enum ChordFunction {
  root,
  sus2,
  third,
  sus4,
  fifth,
  seventh,
  ninth,
  eleventh,
  thirteenth,
  add4,
  add6,
  add9;

  /// Root, third (or the tone replacing it), fifth and seventh: the tones
  /// an inversion can put in the bass, in that order.
  int? get inversionSlot => switch (this) {
    root => 0,
    sus2 || third || sus4 => 1,
    fifth => 2,
    seventh => 3,
    _ => null,
  };
}

final class ChordTone {
  const ChordTone(this.function, this.semitones, this.name);

  final ChordFunction function;

  /// Semitones above the chord root (0–23).
  final int semitones;
  final NoteName name;

  @override
  String toString() => '$name(${function.name})';
}

/// A fully resolved chord: spelled tones, bass, and the context needed for
/// labels.
final class Chord {
  Chord._({
    required this.spec,
    required this.key,
    required this.root,
    required this.tones,
    required this.bass,
    required this.naturalThirdIsMinor,
  });

  final ChordSpec spec;

  /// The key the chord was entered in (not the borrowed/applied local key).
  final Key key;
  final NoteName root;

  /// Tones in stacking order (ascending semitones above the root).
  final List<ChordTone> tones;
  final ChordTone bass;

  /// Whether the third the chord would have without sus/omit is minor.
  /// Decides upper/lower case for Roman numerals of sus/no3 chords.
  final bool naturalThirdIsMinor;

  ChordTone? toneFor(ChordFunction function) {
    for (final t in tones) {
      if (t.function == function) return t;
    }
    return null;
  }

  Iterable<ChordTone> tonesFor(ChordFunction function) =>
      tones.where((t) => t.function == function);

  int? get thirdSemitones => toneFor(ChordFunction.third)?.semitones;
  int? get seventhSemitones => toneFor(ChordFunction.seventh)?.semitones;

  /// Fifth(s) present: normally one, but ♭5 and ♯5 together give two.
  List<int> get fifthSemitones =>
      tonesFor(ChordFunction.fifth).map((t) => t.semitones).toList();

  List<NoteName> get noteNames => [for (final t in tones) t.name];
  Set<int> get pitchClasses => {for (final t in tones) t.name.pitchClass};

  @override
  String toString() => 'Chord(${noteNames.join(' ')} / ${bass.name})';
}

/// Builds the chord described by [spec] in [key].
///
/// 1. Borrowed chords use the borrowed scale on the same tonic.
/// 2. Applied chords locate the target degree, then build V or IV in the
///    target's major scale, or vii in its harmonic minor (so vii°7/x is fully
///    diminished).
/// 3. Thirds are stacked from that local scale up to the chord type.
/// 4. sus2/sus4 replace the third with a major 2nd / perfect 4th; add4,
///    add6 and add9 add the scale tone; omits remove; alterations set the
///    absolute interval, replacing the natural tone of the same function.
/// 5. The inversion picks the bass from root, third, fifth, seventh.
Chord buildChord(ChordSpec spec, Key key) {
  final source = Key(key.tonic, spec.borrowedFrom ?? key.scale);
  final Key local;
  final int localDegree;
  switch (spec.applied) {
    case Applied.none:
      local = source;
      localDegree = spec.degree;
    case Applied.fiveOf:
      local = Key(source.degreeName(spec.degree), Scale.major);
      localDegree = 5;
    case Applied.fourOf:
      local = Key(source.degreeName(spec.degree), Scale.major);
      localDegree = 4;
    case Applied.sevenOf:
      local = Key(source.degreeName(spec.degree), Scale.harmonicMinor);
      localDegree = 7;
  }

  final rootSemis = local.scale.semitonesOf(localDegree);
  final root = local.degreeName(localDegree);

  ChordTone stacked(ChordFunction function, int stepsAboveRoot) {
    final d = localDegree + stepsAboveRoot;
    return ChordTone(
      function,
      local.scale.semitonesOf(d) - rootSemis,
      local.degreeName(d),
    );
  }

  ChordTone absolute(ChordFunction function, int semis, int letterSteps) =>
      ChordTone(
        function,
        semis,
        NoteName.spell(root.letter + letterSteps, root.pitchClass + semis),
      );

  const stackFunctions = [
    ChordFunction.root,
    ChordFunction.third,
    ChordFunction.fifth,
    ChordFunction.seventh,
    ChordFunction.ninth,
    ChordFunction.eleventh,
    ChordFunction.thirteenth,
  ];
  final tones = <ChordTone>[
    for (var i = 0; i < spec.type.toneCount; i++)
      stacked(stackFunctions[i], 2 * i),
  ];
  final naturalThirdIsMinor = tones[1].semitones == 3;

  bool has(ChordFunction f) => tones.any((t) => t.function == f);

  // Sus replaces the third.
  if (spec.sus != Sus.none) {
    tones.removeWhere((t) => t.function == ChordFunction.third);
    tones.add(
      spec.sus == Sus.sus2
          ? absolute(ChordFunction.sus2, 2, 1)
          : absolute(ChordFunction.sus4, 5, 3),
    );
  }

  // Added scale tones (skipped if the chord already has that tone).
  for (final add in spec.adds) {
    switch (add) {
      case AddTone.add4:
        if (!has(ChordFunction.sus4) && !has(ChordFunction.eleventh)) {
          tones.add(stacked(ChordFunction.add4, 3));
        }
      case AddTone.add6:
        if (!has(ChordFunction.thirteenth)) {
          tones.add(stacked(ChordFunction.add6, 5));
        }
      case AddTone.add9:
        if (!has(ChordFunction.ninth)) {
          tones.add(stacked(ChordFunction.add9, 8));
        }
    }
  }

  for (final omit in spec.omits) {
    tones.removeWhere(
      (t) =>
          t.function ==
          (omit == OmitTone.no3 ? ChordFunction.third : ChordFunction.fifth),
    );
  }

  // Alterations replace the natural tone of the same function.
  ChordFunction alteredFunction(Alteration a) => switch (a) {
    Alteration.flat5 || Alteration.sharp5 => ChordFunction.fifth,
    Alteration.flat9 || Alteration.sharp9 => ChordFunction.ninth,
    Alteration.sharp11 => ChordFunction.eleventh,
    Alteration.flat13 => ChordFunction.thirteenth,
  };
  final alteredFunctions = spec.alterations.map(alteredFunction).toSet();
  tones.removeWhere((t) => alteredFunctions.contains(t.function));
  for (final a in spec.alterations) {
    tones.add(absolute(alteredFunction(a), a.semitones, a.letterSteps));
  }

  tones.sort((a, b) => a.semitones.compareTo(b.semitones));

  final slots = tones.where((t) => t.function.inversionSlot != null).toList()
    ..sort(
      (a, b) => a.function.inversionSlot!.compareTo(b.function.inversionSlot!),
    );
  if (spec.inversion >= slots.length) {
    throw ArgumentError.value(
      spec.inversion,
      'inversion',
      'Chord has only ${slots.length} invertible tones',
    );
  }

  return Chord._(
    spec: spec,
    key: key,
    root: root,
    tones: List.unmodifiable(tones),
    bass: slots[spec.inversion],
    naturalThirdIsMinor: naturalThirdIsMinor,
  );
}
