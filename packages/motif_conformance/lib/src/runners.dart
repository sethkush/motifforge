import 'package:motif_theory/motif_theory.dart';

import 'spec_loader.dart';

enum Outcome { pass, fail, pending }

final class CaseResult {
  const CaseResult(this.outcome, [this.message = '']);
  const CaseResult.pass() : this(Outcome.pass);
  const CaseResult.pending(String why) : this(Outcome.pending, why);

  final Outcome outcome;
  final String message;
}

typedef Runner = CaseResult Function(Map<String, Object?> c);

/// Runners by block `kind`. Kinds not listed here are reported as pending.
final Map<String, Runner> runners = {
  'chord': _chord,
  'note': _note,
  'key-spelling': _keySpelling,
  'relative-tonic': _relativeTonic,
  'color': _color,
  'octave': _octave,
};

/// Why a kind without a runner is pending.
const pendingKinds = {'edit': 'needs motif_core (editor model, M1)'};

CaseResult runCase(ConformanceBlock block, Map<String, Object?> c) {
  final runner = runners[block.kind];
  if (runner == null) {
    return CaseResult.pending(
      pendingKinds[block.kind] ?? 'no runner for kind "${block.kind}"',
    );
  }
  try {
    return runner(c);
  } on Object catch (e) {
    return CaseResult(Outcome.fail, 'error: $e');
  }
}

/// Compares only the expectations the case provides.
CaseResult _compare(Map<String, Object?> c, Map<String, Object?> actual) {
  final mismatches = <String>[];
  actual.forEach((field, value) {
    if (!c.containsKey(field)) return;
    final expected = c[field];
    final same = expected is List && value is List
        ? expected.map((e) => '$e').join(' ') == value.join(' ')
        : '$expected' == '$value';
    if (!same) mismatches.add('$field: expected "$expected", got "$value"');
  });
  return mismatches.isEmpty
      ? const CaseResult.pass()
      : CaseResult(Outcome.fail, mismatches.join('; '));
}

Key _key(Object? text) => Key.parse(text! as String);

Scale _scale(Object? text) {
  final s = '$text'.toLowerCase().replaceAll(' ', '');
  return Scale.values.firstWhere(
    (v) => v.name.toLowerCase() == s,
    orElse: () => throw FormatException('Unknown scale', '$text'),
  );
}

int _int(Object? v, [int fallback = 0]) => v == null ? fallback : v as int;

List<int> _ints(Object? v) => [
  for (final x in (v as List?) ?? const []) x as int,
];

ChordSpec _chordSpec(Map<String, Object?> s) {
  const types = {
    5: ChordType.triad,
    7: ChordType.seventh,
    9: ChordType.ninth,
    11: ChordType.eleventh,
    13: ChordType.thirteenth,
  };
  const alterations = {
    'b5': Alteration.flat5,
    '#5': Alteration.sharp5,
    'b9': Alteration.flat9,
    '#9': Alteration.sharp9,
    '#11': Alteration.sharp11,
    'b13': Alteration.flat13,
  };
  const applied = {
    'V': Applied.fiveOf,
    'IV': Applied.fourOf,
    'vii': Applied.sevenOf,
  };
  return ChordSpec(
    _int(s['degree']),
    type: types[_int(s['type'], 5)]!,
    inversion: _int(s['inversion']),
    sus: switch (s['sus']) {
      2 => Sus.sus2,
      4 => Sus.sus4,
      _ => Sus.none,
    },
    adds: {
      for (final a in _ints(s['add']))
        {4: AddTone.add4, 6: AddTone.add6, 9: AddTone.add9}[a]!,
    },
    omits: {
      for (final o in _ints(s['omit'])) {3: OmitTone.no3, 5: OmitTone.no5}[o]!,
    },
    alterations: {
      for (final a in (s['alter'] as List?) ?? const []) alterations['$a']!,
    },
    applied: applied[s['applied']] ?? Applied.none,
    borrowedFrom: s['borrow'] == null ? null : _scale(s['borrow']),
  );
}

CaseResult _chord(Map<String, Object?> c) {
  final chord = buildChord(
    _chordSpec(c['spec']! as Map<String, Object?>),
    _key(c['key']),
  );
  return _compare(c, {
    'symbol': chordSymbol(chord),
    'roman': romanNumeral(chord).toString(),
    'tones': [for (final n in chord.noteNames) '$n'],
    'bass': '${chord.bass.name}',
  });
}

CaseResult _note(Map<String, Object?> c) {
  final key = _key(c['key']);
  final note = DegreeNote(
    _int(c['degree']),
    accidental: _int(c['accidental']),
    octave: _int(c['octave']),
  );
  return _compare(c, {
    'name': '${note.name(key)}',
    'midi': note.midi(key),
    'scientific': note.scientificName(key),
  });
}

CaseResult _keySpelling(Map<String, Object?> c) => _compare(c, {
  'tonic': '${Key.fromPitchClass(_int(c['pc']), _scale(c['scale'])).tonic}',
});

CaseResult _relativeTonic(Map<String, Object?> c) => _compare(c, {
  'tonic': '${relativeTonic(_key(c['from']), _scale(c['to']))}',
});

CaseResult _color(Map<String, Object?> c) {
  final scheme = switch (c['scheme']) {
    'major' => ColorScheme.majorCentric,
    _ => ColorScheme.diatonicCentric,
  };
  final color = degreeColor(
    _int(c['degree']),
    _scale(c['scale']),
    accidental: _int(c['accidental']),
    scheme: scheme,
  );
  return _compare(c, {'color': '$color'});
}

CaseResult _octave(Map<String, Object?> c) {
  final prev = c['previous'] as Map<String, Object?>?;
  return _compare(c, {
    'octave': placeOctave(
      degree: _int(c['degree']),
      previous: prev == null
          ? null
          : DegreeNote(_int(prev['degree']), octave: _int(prev['octave'])),
      smart: (c['smart'] as bool?) ?? true,
      shift: _int(c['shift']),
    ),
  });
}
